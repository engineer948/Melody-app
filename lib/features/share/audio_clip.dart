import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/logging/app_logger.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/core/utils/formatters.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/domain/share/mp3_clip.dart';
import 'package:melody/domain/share/story_lyrics.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/lyrics/lyrics_providers.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/player_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'audio_clip.g.dart';

const _log = AppLogger('clip');

/// Downloads a whole song as MP3; replaced by a fake in tests.
abstract interface class SongAudioLoader {
  /// The MP3 of [track]. Throws [UnsupportedFailure] when [source] cannot
  /// provide MP3.
  Future<Uint8List> load(MusicSource source, Track track);

  /// The first [maxBytes] of the MP3 of [track] (its first half minute or
  /// so), for finding where the music starts.
  Future<Uint8List> loadStart(MusicSource source, Track track, {int maxBytes});
}

/// [SongAudioLoader] over HTTP.
class HttpSongAudioLoader implements SongAudioLoader {
  /// Creates the loader.
  HttpSongAudioLoader([Dio? dio])
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 60),
            ),
          );

  final Dio _dio;

  @override
  Future<Uint8List> load(MusicSource source, Track track) async {
    // From the start: the waveform and the loudest part need the whole
    // song, and every piece is then cut on the phone without waiting.
    final request = source.clipRequest(track, Duration.zero);
    if (request == null) throw const UnsupportedFailure();
    final response = await _dio.getUri<List<int>>(
      request.uri,
      options: Options(
        responseType: ResponseType.bytes,
        headers: source.requestHeaders,
      ),
    );
    final data = response.data;
    if (data == null || data.isEmpty) throw const ParsingFailure();
    return data is Uint8List ? data : Uint8List.fromList(data);
  }

  @override
  Future<Uint8List> loadStart(
    MusicSource source,
    Track track, {
    int maxBytes = 800000,
  }) async {
    final request = source.clipRequest(track, Duration.zero);
    if (request == null) throw const UnsupportedFailure();
    final cancel = CancelToken();
    final response = await _dio.getUri<ResponseBody>(
      request.uri,
      cancelToken: cancel,
      options: Options(
        responseType: ResponseType.stream,
        headers: source.requestHeaders,
      ),
    );
    final body = response.data;
    if (body == null) throw const ParsingFailure();
    final bytes = BytesBuilder(copy: false);
    try {
      await for (final chunk in body.stream) {
        bytes.add(chunk);
        if (bytes.length >= maxBytes) break;
      }
    } finally {
      // Stop the download: the rest of the song is not needed.
      cancel.cancel();
    }
    if (bytes.isEmpty) throw const ParsingFailure();
    return bytes.takeBytes();
  }
}

/// Preference set once the user accepted that sharing music is their own
/// responsibility.
const clipRightsKey = 'share.clipRightsAccepted';

/// The song loader in use.
@Riverpod(keepAlive: true)
SongAudioLoader songAudioLoader(Ref ref) => HttpSongAudioLoader();

/// File name of a shared clip: "Artist - Title.mp3".
String clipFileName(Track track) {
  final name = [
    if (track.artistLine.isNotEmpty) track.artistLine,
    track.title,
  ].join(' - ');
  final safe = name
      .replaceAll(RegExp(r'[\\/:*?"<>|\r\n]'), '_')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final short = safe.length > 80 ? safe.substring(0, 80).trim() : safe;
  return '${short.isEmpty ? 'clip' : short}.mp3';
}

/// Saves [mp3] with an ID3 title and artist as the shared clip file; only
/// the latest clip is kept.
Future<File> writeClipFile(Track track, Uint8List mp3) async {
  final dir = Directory('${(await getTemporaryDirectory()).path}/clip');
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);
  final file = File('${dir.path}/${clipFileName(track)}');
  final sink = file.openWrite()
    ..add(id3Tag(title: track.title, artist: track.artistLine))
    ..add(mp3);
  await sink.close();
  return file;
}

/// Pictures of a story video: the card for each lyrics state and, for a
/// turning record, the record alone and where it sits (0–1 of the card).
typedef StoryPictures = ({
  List<(File, Duration)> pictures,
  File? disc,
  Rect? discRect,
});

/// Frames per second of story videos; [storyPulse] gives one value each.
const storyFps = 24;

/// How much the record swells with the music, per video frame (0–1): the
/// loudness of [song] between [start] and [end], smoothed.
List<double> storyPulse(Mp3Song song, Duration start, Duration end) {
  final frames = song.frames;
  if (frames.isEmpty || end <= start) return const [];
  final count = ((end - start).inMicroseconds * storyFps / 1000000).ceil();
  final raw = <double>[];
  var f = 0;
  for (var i = 0; i < count; i++) {
    final t = start.inMicroseconds + i * 1000000 ~/ storyFps;
    while (f + 1 < frames.length && frames[f + 1].startUs <= t) {
      f++;
    }
    raw.add(frames[f].loudness);
  }
  final low = raw.reduce(min);
  final high = raw.reduce(max);
  final range = max(1, high - low);
  var level = 0.0;
  return [for (final v in raw) level += ((v - low) / range - level) * 0.35];
}

/// Turns story pictures and a clip into an MP4; replaced in tests.
abstract interface class StoryVideoMaker {
  /// Whether this device can make videos.
  bool get supported;

  /// Writes a video named after [name]: each picture is shown from its
  /// time on (the first at 0), with [audio] under it. With [disc], that
  /// picture turns like a record at [discRect], growing a little with
  /// [pulse] (one value per frame at [storyFps]).
  Future<File> make({
    required List<(File, Duration)> pictures,
    required File audio,
    required String name,
    File? disc,
    Rect? discRect,
    List<double> pulse = const [],
  });
}

/// [StoryVideoMaker] using the platform codecs (Android only for now).
class ChannelStoryVideoMaker implements StoryVideoMaker {
  static const _channel = MethodChannel('melody/story_video');

  @override
  bool get supported => !kIsWeb && Platform.isAndroid;

  @override
  Future<File> make({
    required List<(File, Duration)> pictures,
    required File audio,
    required String name,
    File? disc,
    Rect? discRect,
    List<double> pulse = const [],
  }) async {
    final dir = Directory('${(await getTemporaryDirectory()).path}/video');
    // Only the latest video is kept.
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final out = '${dir.path}/$name.mp4';
    await _channel.invokeMethod<String>('make', {
      'images': [for (final (file, _) in pictures) file.path],
      'times': [for (final (_, at) in pictures) at.inMicroseconds],
      'audio': audio.path,
      'out': out,
      if (disc != null && discRect != null) ...{
        'disc': disc.path,
        'discRect': [
          discRect.left,
          discRect.top,
          discRect.width,
          discRect.height,
        ],
        'pulse': pulse,
      },
    });
    return File(out);
  }
}

/// The story video maker in use.
@Riverpod(keepAlive: true)
StoryVideoMaker storyVideoMaker(Ref ref) => ChannelStoryVideoMaker();

/// Plays a made clip to check it before sharing; replaced in tests.
abstract interface class ClipPreview {
  /// Plays [file] once; completes when playback has started.
  Future<void> play(File file);

  /// Stops playback.
  Future<void> stop();

  /// Whether a clip is playing.
  ValueListenable<bool> get playing;

  /// Frees the player.
  Future<void> dispose();
}

/// [ClipPreview] with its own player, separate from the music player.
class JustAudioClipPreview implements ClipPreview {
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _sub;
  final ValueNotifier<bool> _playing = ValueNotifier(false);

  @override
  ValueListenable<bool> get playing => _playing;

  @override
  Future<void> play(File file) async {
    final player = _player ??= AudioPlayer(handleAudioSessionActivation: false);
    _sub ??= player.playerStateStream.listen((s) {
      _playing.value =
          s.playing && s.processingState != ProcessingState.completed;
    });
    await player.setFilePath(file.path);
    unawaited(player.play());
  }

  @override
  Future<void> stop() async {
    await _player?.stop();
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    await _player?.dispose();
    _playing.dispose();
  }
}

/// A new preview player for one share screen.
@riverpod
ClipPreview clipPreview(Ref ref) {
  final preview = JustAudioClipPreview();
  ref.onDispose(() => unawaited(preview.dispose()));
  return preview;
}

/// Shortest and longest clip.
const minClip = Duration(seconds: 5);

/// See [minClip].
const maxClip = Duration(seconds: 60);

/// Length chosen at first.
const defaultClip = Duration(seconds: 30);

/// Fade lengths when "smooth start and end" is on.
const clipFadeIn = Duration(seconds: 1);

/// See [clipFadeIn].
const clipFadeOut = Duration(milliseconds: 1500);

/// Picks a piece of [track], plays it and shares it as an MP3 file or, with
/// [renderPictures], as a story video.
class AudioClipPanel extends ConsumerStatefulWidget {
  /// Creates the panel.
  const AudioClipPanel({
    required this.track,
    this.renderPictures,
    this.onCardLyrics,
    this.onSpin,
    super.key,
  });

  /// Tells the story card whether the cover turns like a record.
  final ValueChanged<bool>? onSpin;

  /// Song to cut.
  final Track track;

  /// Renders the story picture once for each lyrics state; `null` while
  /// the picture is loading.
  final Future<StoryPictures> Function(
    List<LyricFrame> frames, {
    required bool spin,
  })?
  renderPictures;

  /// Tells the story card which lyrics to show (`null`: none).
  final ValueChanged<LyricFrame?>? onCardLyrics;

  @override
  ConsumerState<AudioClipPanel> createState() => _AudioClipPanelState();
}

class _AudioClipPanelState extends ConsumerState<AudioClipPanel> {
  Mp3Song? _song;
  List<double> _wave = const [];
  Object? _loadError;
  Duration _start = Duration.zero;
  Duration _end = defaultClip;
  bool _fade = true;
  bool _lyrics = false;
  bool _spin = false;
  ({Duration start, Duration end, bool fade, File file})? _made;
  bool _busy = false;
  bool _makingVideo = false;
  LyricFrame? _sentLyrics;

  Duration get _duration => _song?.duration ?? Duration.zero;
  Duration get _length => _end - _start;

  /// Where the song is now, when it is the one playing.
  Duration? get _playingAt {
    final current = ref.read(playerControllerProvider).current;
    if (current?.id != widget.track.id) return null;
    return ref.read(playerPositionProvider).value;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final source = ref.read(activeSourceProvider);
    setState(() => _loadError = null);
    try {
      if (source == null) throw const UnauthorizedFailure();
      final bytes = await ref
          .read(songAudioLoaderProvider)
          .load(source, widget.track);
      final song = Mp3Song.parse(bytes);
      if (song.frames.isEmpty) throw const ParsingFailure();
      if (!mounted) return;
      setState(() {
        _song = song;
        _wave = song.waveform(96);
        final at = _playingAt;
        _place(at ?? song.loudestPart(defaultClip), defaultClip);
      });
    } on Object catch (e) {
      _log.error('Song could not be loaded', e);
      if (mounted) setState(() => _loadError = e);
    }
  }

  /// Puts a piece of [length] at [start], kept inside the song.
  void _place(Duration start, Duration length) {
    final total = _duration;
    final len = length > total ? total : length;
    var from = start;
    if (from + len > total) from = total - len;
    if (from.isNegative) from = Duration.zero;
    _start = Duration(milliseconds: (from.inMilliseconds / 100).round() * 100);
    _end = _start + len;
    if (_end > total) _end = total;
  }

  void _changed() {
    unawaited(ref.read(clipPreviewProvider).stop());
  }

  void _move(Duration start) {
    setState(() => _place(start, _length));
    _changed();
  }

  void _setRange(RangeValues v) {
    var start = Duration(milliseconds: (v.start * 1000).round());
    var end = Duration(milliseconds: (v.end * 1000).round());
    // Keep the length between the limits, moving the handle that moved.
    final movedStart = start != _start;
    if (end - start < minClip) {
      if (movedStart) {
        start = end - minClip;
      } else {
        end = start + minClip;
      }
    }
    if (end - start > maxClip) {
      if (movedStart) {
        end = start + maxClip;
      } else {
        start = end - maxClip;
      }
    }
    setState(() {
      _start = start.isNegative ? Duration.zero : start;
      _end = end > _duration ? _duration : end;
    });
    _changed();
  }

  Future<File?> _file() async {
    final made = _made;
    if (made != null &&
        made.start == _start &&
        made.end == _end &&
        made.fade == _fade &&
        made.file.existsSync()) {
      return made.file;
    }
    final song = _song;
    if (song == null) return null;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = song.cut(
        _start,
        _length,
        fadeIn: _fade ? clipFadeIn : Duration.zero,
        fadeOut: _fade ? clipFadeOut : Duration.zero,
      );
      if (bytes.isEmpty) throw const ParsingFailure();
      final file = await writeClipFile(widget.track, bytes);
      _made = (start: _start, end: _end, fade: _fade, file: file);
      return file;
    } on Object catch (e) {
      _log.error('Clip failed', e);
      messenger.showSnackBar(SnackBar(content: Text(l10n.clipFailed)));
      return null;
    }
  }

  Future<void> _togglePreview() async {
    final preview = ref.read(clipPreviewProvider);
    if (preview.playing.value) {
      await preview.stop();
      return;
    }
    final file = await _file();
    if (file == null || !mounted) return;
    if (ref.read(playerControllerProvider).playing) {
      await ref.read(playerControllerProvider.notifier).pause();
    }
    await preview.play(file);
  }

  Rect? _origin(BuildContext button) {
    final box = button.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _share(BuildContext button) async {
    final origin = _origin(button);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (!await _confirmRights()) return;
    final file = await _file();
    if (file == null) return;
    await ref.read(clipPreviewProvider).stop();
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'audio/mpeg')],
          subject: widget.track.title,
          sharePositionOrigin: origin,
        ),
      );
    } on Object catch (e) {
      _log.error('Share failed', e);
      messenger.showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
    }
  }

  /// Lyrics states over the chosen piece, or one plain picture.
  List<LyricFrame> _lyricFrames() {
    final lyrics = _syncedLyrics;
    if (!_lyrics || lyrics == null) {
      return const [LyricFrame(at: Duration.zero)];
    }
    final frames = storyLyricFrames(
      lyrics,
      start: _start,
      end: _end,
      offset: _lyricsOffset,
    );
    return frames.isEmpty ? const [LyricFrame(at: Duration.zero)] : frames;
  }

  Future<void> _shareVideo(BuildContext button) async {
    final render = widget.renderPictures;
    if (render == null) return;
    final origin = _origin(button);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (!await _confirmRights()) return;
    final clip = await _file();
    if (clip == null || !mounted) return;
    await ref.read(clipPreviewProvider).stop();
    setState(() => _busy = _makingVideo = true);
    try {
      final story = await render(_lyricFrames(), spin: _spin);
      final song = _song!;
      final video = await ref
          .read(storyVideoMakerProvider)
          .make(
            pictures: story.pictures,
            disc: story.disc,
            discRect: story.discRect,
            pulse: story.disc == null
                ? const []
                : storyPulse(song, _start, _end),
            audio: clip,
            name: clipFileName(widget.track)
                .replaceFirst(RegExp(r'\.mp3$'), ''),
          );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(video.path, mimeType: 'video/mp4')],
          subject: widget.track.title,
          sharePositionOrigin: origin,
        ),
      );
    } on Object catch (e) {
      _log.error('Story video failed', e);
      messenger.showSnackBar(SnackBar(content: Text(l10n.clipVideoFailed)));
    } finally {
      if (mounted) setState(() => _busy = _makingVideo = false);
    }
  }

  /// Preference set once the user accepted that sharing is their own
  /// responsibility.
  static const String rightsKey = clipRightsKey;

  /// Asks once whether the user takes responsibility for what they share.
  Future<bool> _confirmRights() async {
    final prefs = ref.read(preferencesProvider);
    if (prefs.getBool(rightsKey) ?? false) return true;
    final l10n = context.l10n;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.copyright_rounded),
        title: Text(l10n.clipRightsTitle),
        content: Text(l10n.clipRightsBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.clipRightsAccept),
          ),
        ],
      ),
    );
    if (accepted != true) return false;
    await prefs.setBool(rightsKey, true);
    return true;
  }

  Lyrics? get _syncedLyrics {
    final lyrics = ref.read(trackLyricsProvider(widget.track)).value;
    return lyrics != null && lyrics.synced && !lyrics.isEmpty ? lyrics : null;
  }

  Duration get _lyricsOffset =>
      ref.read(lyricsSettingsControllerProvider).offsetOf(widget.track.id);

  /// Shows the lyrics at the start of the piece on the story card.
  void _sendCardLyrics() {
    final callback = widget.onCardLyrics;
    if (callback == null) return;
    final first = _lyrics && _syncedLyrics != null
        ? _lyricFrames().first
        : null;
    if (first == _sentLyrics) return;
    _sentLyrics = first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) callback(first);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (ref
            .watch(activeSourceProvider)
            ?.clipRequest(widget.track, Duration.zero) ==
        null) {
      return _Message(text: l10n.clipUnsupported);
    }
    if (_loadError != null) {
      return _Message(
        text: l10n.clipFailed,
        action: TextButton(onPressed: _load, child: Text(l10n.retry)),
      );
    }
    final song = _song;
    if (song == null) {
      return _Message(text: l10n.clipLoading, busy: true);
    }
    final lyrics = ref.watch(trackLyricsProvider(widget.track)).value;
    final synced = lyrics != null && lyrics.synced && !lyrics.isEmpty;
    final offset = ref.watch(
      lyricsSettingsControllerProvider.select(
        (s) => s.offsetOf(widget.track.id),
      ),
    );
    _sendCardLyrics();
    final preview = ref.watch(clipPreviewProvider);
    final playingAt = _playingAt;
    final totalSeconds = max(1, _duration.inMilliseconds) / 1000;
    final canVideo =
        widget.renderPictures != null &&
        ref.watch(storyVideoMakerProvider).supported;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        _Waveform(
          wave: _wave,
          duration: _duration,
          start: _start,
          end: _end,
          onMove: _move,
        ),
        RangeSlider(
          values: RangeValues(
            _start.inMilliseconds / 1000,
            _end.inMilliseconds / 1000,
          ),
          max: totalSeconds,
          onChanged: _setRange,
        ),
        Row(
          children: [
            IconButton(
              tooltip: l10n.clipEarlier,
              icon: const Icon(Icons.replay_5_rounded),
              onPressed: () => _move(_start - const Duration(seconds: 5)),
            ),
            Expanded(
              child: Text(
                '${formatDuration(_start)} – ${formatDuration(_end)}'
                ' · ${l10n.clipSeconds(_length.inSeconds)}',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.clipLater,
              icon: const Icon(Icons.forward_5_rounded),
              onPressed: () => _move(_start + const Duration(seconds: 5)),
            ),
          ],
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(l10n.clipBestPart),
              onPressed: () => _move(song.loudestPart(_length)),
            ),
            if (playingAt != null)
              ActionChip(
                avatar: const Icon(Icons.my_location_rounded, size: 18),
                label: Text(l10n.clipFromNow),
                onPressed: () => _move(playingAt),
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.clipFade),
          value: _fade,
          onChanged: (v) {
            setState(() => _fade = v);
            _changed();
          },
        ),
        if (widget.renderPictures != null) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.clipSpin),
            subtitle: Text(l10n.clipSpinBody),
            value: _spin,
            onChanged: (v) {
              setState(() => _spin = v);
              widget.onSpin?.call(v);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.clipLyrics),
            subtitle: synced ? null : Text(l10n.clipLyricsNone),
            value: _lyrics && synced,
            onChanged: synced ? (v) => setState(() => _lyrics = v) : null,
          ),
          if (_lyrics && synced)
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.clipLyricsTiming,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.lyricsEarlier,
                  icon: const Icon(Icons.remove_rounded),
                  onPressed: () => ref
                      .read(lyricsSettingsControllerProvider.notifier)
                      .shift(
                        widget.track.id,
                        const Duration(milliseconds: -250),
                      ),
                ),
                Text(
                  l10n.lyricsOffset(
                    '${offset.isNegative || offset == Duration.zero ? '' : '+'}'
                    '${(offset.inMilliseconds / 1000).toStringAsFixed(2)}',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                IconButton(
                  tooltip: l10n.lyricsLater,
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => ref
                      .read(lyricsSettingsControllerProvider.notifier)
                      .shift(
                        widget.track.id,
                        const Duration(milliseconds: 250),
                      ),
                ),
              ],
            ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: preview.playing,
                builder: (context, playing, _) => OutlinedButton.icon(
                  onPressed: _busy ? null : () => unawaited(_togglePreview()),
                  icon: Icon(
                    playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  ),
                  label: Text(playing ? l10n.clipStop : l10n.clipListen),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Builder(
                builder: (button) => FilledButton.icon(
                  onPressed: _busy ? null : () => unawaited(_share(button)),
                  icon: const Icon(Icons.send_rounded),
                  label: Text(l10n.clipShare),
                ),
              ),
            ),
          ],
        ),
        if (canVideo) ...[
          const SizedBox(height: 12),
          Builder(
            builder: (button) => FilledButton.tonalIcon(
              onPressed: _busy ? null : () => unawaited(_shareVideo(button)),
              icon: _makingVideo
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.movie_creation_outlined),
              label: Text(_makingVideo ? l10n.clipVideoMaking : l10n.clipVideo),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          l10n.clipHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.clipRightsNote,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action, this.busy = false});

  final String text;
  final Widget? action;
  final bool busy;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
          ],
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          ?action,
        ],
      ),
    ),
  );
}

/// The song's loudness with the chosen piece highlighted; dragging or
/// tapping moves the piece.
class _Waveform extends StatelessWidget {
  const _Waveform({
    required this.wave,
    required this.duration,
    required this.start,
    required this.end,
    required this.onMove,
  });

  final List<double> wave;
  final Duration duration;
  final Duration start;
  final Duration end;
  final ValueChanged<Duration> onMove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = max(1, duration.inMilliseconds).toDouble();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final piece = (end - start).inMilliseconds;
        // The finger holds the middle of the piece.
        void move(double dx) => onMove(
          Duration(milliseconds: (dx / width * total - piece / 2).round()),
        );
        final left = start.inMilliseconds / total * width;
        final right = end.inMilliseconds / total * width;
        return Semantics(
          slider: true,
          value: formatDuration(start),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => move(d.localPosition.dx),
            onHorizontalDragUpdate: (d) => move(d.localPosition.dx),
            child: SizedBox(
              height: 72,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Row(
                      children: [
                        for (var i = 0; i < wave.length; i++)
                          Expanded(
                            child: Center(
                              child: Container(
                                width: 2.5,
                                height: 6 + 54 * wave[i],
                                decoration: BoxDecoration(
                                  color: _inside(i)
                                      ? scheme.primary
                                      : scheme.onSurfaceVariant.withValues(
                                          alpha: 0.35,
                                        ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: left,
                    width: (right - left).clamp(4, width),
                    top: 2,
                    bottom: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        border: Border.all(color: scheme.primary, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _inside(int bar) {
    if (wave.isEmpty) return false;
    final at = duration * ((bar + 0.5) / wave.length);
    return at >= start && at <= end;
  }
}
