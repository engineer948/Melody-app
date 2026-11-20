import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/logging/app_logger.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/core/utils/formatters.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/domain/share/mp3_clip.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/player_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'audio_clip.g.dart';

const _log = AppLogger('clip');

/// Makes MP3 files of a piece of a song; replaced by a fake in tests.
abstract interface class ClipMaker {
  /// Cuts [length] of [track] from [start] and saves it as an MP3 file.
  ///
  /// Throws [UnsupportedFailure] when [source] cannot provide MP3.
  Future<File> make(
    MusicSource source,
    Track track,
    Duration start,
    Duration length,
  );
}

/// [ClipMaker] that streams the MP3 from the server and stops downloading
/// as soon as the piece is complete.
class HttpClipMaker implements ClipMaker {
  /// Creates the maker.
  HttpClipMaker([Dio? dio])
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
            ),
          );

  final Dio _dio;

  @override
  Future<File> make(
    MusicSource source,
    Track track,
    Duration start,
    Duration length,
  ) async {
    final request = source.clipRequest(track, start);
    if (request == null) throw const UnsupportedFailure();
    final clipper = Mp3Clipper(length: length, skip: request.skip);
    final cancel = CancelToken();
    try {
      final response = await _dio.getUri<ResponseBody>(
        request.uri,
        cancelToken: cancel,
        options: Options(
          responseType: ResponseType.stream,
          headers: source.requestHeaders,
        ),
      );
      await for (final chunk in response.data!.stream) {
        if (clipper.add(chunk)) break;
      }
    } on DioException catch (e) {
      if (!CancelToken.isCancel(e)) rethrow;
    } finally {
      if (!cancel.isCancelled) cancel.cancel();
    }
    // A song that ends early still makes a (shorter) clip.
    if (clipper.kept < const Duration(seconds: 1)) {
      throw const ParsingFailure();
    }
    final dir = Directory('${(await getTemporaryDirectory()).path}/share');
    await dir.create(recursive: true);
    // Only the latest clip is kept.
    for (final old in dir.listSync().whereType<File>()) {
      if (old.path.endsWith('.mp3')) old.deleteSync();
    }
    final file = File('${dir.path}/${clipFileName(track)}');
    final sink = file.openWrite()
      ..add(id3Tag(title: track.title, artist: track.artistLine))
      ..add(clipper.takeBytes());
    await sink.close();
    return file;
  }
}

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

/// The clip maker in use.
@Riverpod(keepAlive: true)
ClipMaker clipMaker(Ref ref) => HttpClipMaker();

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

/// Lengths a clip can have.
const clipLengths = [
  Duration(seconds: 15),
  Duration(seconds: 30),
  Duration(seconds: 60),
];

/// Picks a piece of [track], plays it and shares it as an MP3 file.
class AudioClipPanel extends ConsumerStatefulWidget {
  /// Creates the panel.
  const AudioClipPanel({required this.track, super.key});

  /// Song to cut.
  final Track track;

  @override
  ConsumerState<AudioClipPanel> createState() => _AudioClipPanelState();
}

class _AudioClipPanelState extends ConsumerState<AudioClipPanel> {
  late Duration _length;
  late Duration _start;
  ({Duration start, Duration length, File file})? _made;
  bool _busy = false;

  Duration get _duration => widget.track.duration ?? Duration.zero;

  Duration get _maxStart {
    final max = _duration - _length;
    return max.isNegative ? Duration.zero : max;
  }

  /// Where the song is now, when it is the one playing.
  Duration? get _playingAt {
    final current = ref.read(playerControllerProvider).current;
    if (current?.id != widget.track.id) return null;
    return ref.read(playerPositionProvider).value;
  }

  @override
  void initState() {
    super.initState();
    _length = clipLengths[1];
    if (_duration < _length) _length = _duration;
    // From where it is playing, or about a third in (often the chorus).
    _start = _clamp(_playingAt ?? _duration * 0.3);
  }

  Duration _clamp(Duration d) =>
      Duration(seconds: d.inSeconds.clamp(0, _maxStart.inSeconds));

  Future<File?> _file() async {
    final made = _made;
    if (made != null && made.start == _start && made.length == _length) {
      return made.file;
    }
    final source = ref.read(activeSourceProvider);
    if (source == null) return null;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final file = await ref
          .read(clipMakerProvider)
          .make(source, widget.track, _start, _length);
      _made = (start: _start, length: _length, file: file);
      return file;
    } on Object catch (e) {
      _log.error('Clip failed', e);
      messenger.showSnackBar(SnackBar(content: Text(l10n.clipFailed)));
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
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
    final player = ref.read(playerControllerProvider);
    if (player.playing) {
      await ref.read(playerControllerProvider.notifier).pause();
    }
    await preview.play(file);
  }

  Future<void> _share(BuildContext button) async {
    final box = button.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
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

  /// Preference set once the user accepted that sharing is their own
  /// responsibility.
  static const rightsKey = 'share.clipRightsAccepted';

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

  void _setStart(Duration start) {
    setState(() => _start = _clamp(start));
    unawaited(ref.read(clipPreviewProvider).stop());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final supported =
        _duration > Duration.zero &&
        ref.watch(activeSourceProvider)?.clipRequest(widget.track, _start) !=
            null;
    if (!supported) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.clipUnsupported,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }
    final preview = ref.watch(clipPreviewProvider);
    final end = _start + _length > _duration ? _duration : _start + _length;
    final playingAt = _playingAt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.graphic_eq_rounded),
          title: Text(
            widget.track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            widget.track.artistLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.clipLength, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<Duration>(
          segments: [
            for (final d in clipLengths)
              ButtonSegment(
                value: d,
                enabled: d <= _duration,
                label: Text(l10n.clipSeconds(d.inSeconds)),
              ),
          ],
          selected: {_length},
          showSelectedIcon: false,
          onSelectionChanged: (s) {
            _length = s.first;
            _setStart(_start);
          },
        ),
        const SizedBox(height: 24),
        Text(l10n.clipPart, style: theme.textTheme.titleSmall),
        _ClipBar(
          duration: _duration,
          start: _start,
          end: end,
          onChanged: _setStart,
        ),
        Row(
          children: [
            IconButton(
              tooltip: l10n.clipEarlier,
              icon: const Icon(Icons.replay_5_rounded),
              onPressed: () => _setStart(_start - const Duration(seconds: 5)),
            ),
            Expanded(
              child: Text(
                '${formatDuration(_start)} – ${formatDuration(end)}',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.clipLater,
              icon: const Icon(Icons.forward_5_rounded),
              onPressed: () => _setStart(_start + const Duration(seconds: 5)),
            ),
          ],
        ),
        if (playingAt != null)
          Center(
            child: TextButton.icon(
              onPressed: () => _setStart(playingAt),
              icon: const Icon(Icons.my_location_rounded),
              label: Text(l10n.clipFromNow),
            ),
          ),
        const SizedBox(height: 16),
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
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(l10n.clipShare),
                ),
              ),
            ),
          ],
        ),
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

/// The whole song as a bar with the chosen piece highlighted; dragging or
/// tapping moves the piece.
class _ClipBar extends StatelessWidget {
  const _ClipBar({
    required this.duration,
    required this.start,
    required this.end,
    required this.onChanged,
  });

  final Duration duration;
  final Duration start;
  final Duration end;
  final ValueChanged<Duration> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = duration.inMilliseconds.toDouble();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final piece = (end - start).inMilliseconds;
        // The finger holds the middle of the piece.
        void move(double dx) => onChanged(
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
              height: 56,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // A fake waveform, so it reads as "sound".
                  Row(
                    children: [
                      for (var i = 0; i < 48; i++)
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 3,
                              height: 10 + 26 * ((i * 37 % 11) / 10),
                              decoration: BoxDecoration(
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.35,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Positioned(
                    left: left,
                    width: (right - left).clamp(4, width),
                    top: 4,
                    bottom: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.25),
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
}
