import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:melody/core/logging/app_logger.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/share/mp3_clip.dart';
import 'package:melody/domain/stats/listening_stats.dart';
import 'package:melody/domain/stats/play_event.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/settings/legal_screen.dart';
import 'package:melody/features/share/audio_clip.dart';
import 'package:melody/features/share/picture_share.dart';
import 'package:melody/features/stats/stats_providers.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/history_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const _log = AppLogger('film');

/// Length of the film of the year.
const yearFilmLength = Duration(seconds: 45);

/// Size of the film's pictures (9:16).
const yearFilmSize = Size(1080, 1920);

/// One picture of the film.
typedef FilmFrame = ({String big, String small, Uint8List? photo});

/// When each of [count] frames starts in a film of [length]: a short
/// title, the months sharing the middle, a longer last one.
List<Duration> filmTimes(int count, Duration length) {
  if (count <= 1) return const [Duration.zero];
  const intro = Duration(seconds: 3);
  const outro = Duration(seconds: 4);
  final months = count - 2;
  final middle = length - intro - outro;
  return [
    Duration.zero,
    for (var i = 0; i < months; i++) intro + middle * (i / months),
    length - outro,
  ];
}

/// The most played song of each month of [events], by month (1–12).
Map<int, Track> topSongByMonth(List<PlayEvent> events) {
  final counts = <int, Map<String, int>>{};
  final tracks = <String, Track>{};
  for (final e in events) {
    if (e.skipped) continue;
    final month = counts.putIfAbsent(e.startedAt.month, () => {});
    month[e.track.id] = (month[e.track.id] ?? 0) + 1;
    tracks[e.track.id] = e.track;
  }
  return {
    for (final MapEntry(key: month, value: songs) in counts.entries)
      month:
          tracks[(songs.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key]!,
  };
}

/// Draws one picture of the film as a PNG file.
Future<File> renderFilmFrame(
  FilmFrame frame,
  Directory dir,
  int index, {
  Color color = const Color(0xFF5B7FE8),
}) async {
  final w = yearFilmSize.width;
  final h = yearFilmSize.height;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Offset.zero & yearFilmSize;
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.linear(Offset.zero, Offset(w, h), [
        color,
        Color.lerp(color, Colors.black, 0.7)!,
      ]),
  );
  final photo = frame.photo;
  if (photo != null) {
    try {
      final codec = await ui.instantiateImageCodec(photo);
      final image = (await codec.getNextFrame()).image;
      codec.dispose();
      // Cover the picture, cut to 9:16.
      final iw = image.width.toDouble();
      final ih = image.height.toDouble();
      final scale = (w / iw) > (h / ih) ? w / iw : h / ih;
      final sw = w / scale;
      final sh = h / scale;
      canvas.drawImageRect(
        image,
        Rect.fromLTWH((iw - sw) / 2, (ih - sh) / 2, sw, sh),
        rect,
        Paint()..filterQuality = FilterQuality.medium,
      );
      image.dispose();
    } on Object {
      // Not a picture: the colour stays.
    }
  }
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.linear(Offset(0, h * 0.45), Offset(0, h), [
        const Color(0x00000000),
        const Color(0xD0000000),
      ]),
  );
  void text(String value, double size, double bottom, {bool bold = false}) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: bold ? Colors.white : Colors.white70,
          fontSize: size,
          fontWeight: bold ? FontWeight.w900 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: w - 160);
    painter.paint(canvas, Offset(80, h - bottom - painter.height));
  }

  text(frame.big, 120, 260, bold: true);
  text(frame.small, 48, 180);
  text('Melody', 34, 90);
  final image = await recorder.endRecording().toImage(w.toInt(), h.toInt());
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final file = File('${dir.path}/frame$index.png');
  await file.writeAsBytes(png!.buffer.asUint8List(), flush: true);
  return file;
}

/// Makes the film of [year]: one picture per month (a photo of it and its
/// song) over the loudest 45 seconds of the year's top song.
Future<File> makeYearFilm(
  WidgetRef ref, {
  required int year,
  required ListeningStats stats,
  required AppLocalizations l10n,
  required String locale,
}) async {
  final top = stats.topTracks.first.item;
  final source = ref.read(activeSourceProvider);
  final accountId = ref.read(sessionControllerProvider).activeId;
  if (source == null || accountId == null) throw StateError('signed out');

  // The music.
  final bytes = await ref.read(songAudioLoaderProvider).load(source, top);
  final song = Mp3Song.parse(bytes);
  final length = song.duration < yearFilmLength
      ? song.duration
      : yearFilmLength;
  final start = song.loudestPart(length);
  final clip = await writeClipFile(
    top,
    song.cut(start, length, fadeIn: clipFadeIn, fadeOut: clipFadeOut),
  );

  // The pictures.
  final events = await ref
      .read(historyStoreProvider)
      .events(accountId, from: DateTime(year), to: DateTime(year + 1));
  final songs = topSongByMonth(events);
  final bridge = ref.read(placesBridgeProvider);
  final photosAllowed = bridge.supported && await bridge.hasPhotos();
  final frames = <FilmFrame>[
    (big: '$year', small: '♪ ${top.title} · ${top.artistLine}', photo: null),
  ];
  for (var month = 1; month <= 12; month++) {
    final monthSong = songs[month];
    if (monthSong == null) continue;
    Uint8List? photo;
    if (photosAllowed) {
      try {
        final found = await bridge.photos(
          DateTime(year, month),
          DateTime(year, month + 1),
          limit: 1,
        );
        if (found.isNotEmpty) {
          photo = await bridge.thumbnail(found.first.id, size: 1080);
        }
      } on Object {
        // Without a photo then.
      }
    }
    frames.add((
      big: DateFormat.MMMM(locale).format(DateTime(year, month)),
      small: '♪ ${monthSong.title}',
      photo: photo,
    ));
  }
  frames.add((
    big: formatListened(l10n, stats.listened),
    small: l10n.wrapTitle(year),
    photo: null,
  ));
  final dir = Directory('${(await getTemporaryDirectory()).path}/film');
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);
  final files = [
    for (final (i, f) in frames.indexed) await renderFilmFrame(f, dir, i),
  ];
  final times = filmTimes(files.length, length);
  return await ref
      .read(storyVideoMakerProvider)
      .make(
        pictures: [for (final (i, f) in files.indexed) (f, times[i])],
        audio: clip,
        name: 'melody-$year',
      );
}

/// "Film of the year" button on the year in review (Android).
class YearFilmButton extends ConsumerStatefulWidget {
  /// Creates the button.
  const YearFilmButton({required this.year, required this.stats, super.key});

  /// The year.
  final int year;

  /// Its statistics.
  final ListeningStats stats;

  @override
  ConsumerState<YearFilmButton> createState() => _YearFilmButtonState();
}

class _YearFilmButtonState extends ConsumerState<YearFilmButton> {
  var _busy = false;

  Future<bool> _confirmRights() => confirmShareTerms(context, ref);

  Future<void> _make(BuildContext button) async {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final messenger = ScaffoldMessenger.of(context);
    final origin = shareOrigin(button);
    if (!await _confirmRights() || !mounted) return;
    setState(() => _busy = true);
    messenger.showSnackBar(SnackBar(content: Text(l10n.filmMaking)));
    try {
      final film = await makeYearFilm(
        ref,
        year: widget.year,
        stats: widget.stats,
        l10n: l10n,
        locale: locale,
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(film.path, mimeType: 'video/mp4')],
          sharePositionOrigin: origin,
        ),
      );
    } on Object catch (e) {
      _log.error('Year film failed', e);
      messenger.showSnackBar(SnackBar(content: Text(l10n.clipVideoFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(storyVideoMakerProvider).supported ||
        widget.stats.topTracks.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    return Builder(
      builder: (button) => IconButton(
        color: Colors.white,
        tooltip: l10n.filmTitle,
        icon: _busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.movie_creation_outlined),
        onPressed: _busy ? null : () => unawaited(_make(button)),
      ),
    );
  }
}
