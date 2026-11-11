import 'package:melody/domain/models/media.dart';

final _timestamp = RegExp(r'\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]');
final _offsetTag = RegExp(r'^\[offset:\s*([+-]?\d+)\]', caseSensitive: false);
final _metaTag = RegExp(r'^\[[a-zA-Z#]+:.*\]\s*$');
final _wordTimestamp = RegExp(r'<\d{1,3}:\d{1,2}(?:[.:]\d{1,3})?>');

/// Parses LRC text (also "enhanced" LRC with word timestamps, which are
/// dropped) into [Lyrics].
///
/// Text without any timestamp becomes unsynchronised lyrics.
Lyrics parseLrc(String text, {LyricsOrigin origin = LyricsOrigin.server}) {
  var offset = Duration.zero;
  final timed = <LyricLine>[];
  final plain = <LyricLine>[];
  for (final raw in text.split(RegExp(r'\r?\n'))) {
    final line = raw.trim();
    final offsetMatch = _offsetTag.firstMatch(line);
    if (offsetMatch != null) {
      // Positive offsets make lyrics appear sooner.
      offset = Duration(milliseconds: -int.parse(offsetMatch[1]!));
      continue;
    }
    final stamps = _timestamp.allMatches(line).toList();
    if (stamps.isEmpty) {
      if (_metaTag.hasMatch(line)) continue;
      plain.add(LyricLine(text: line));
      continue;
    }
    final content = line
        .substring(stamps.last.end)
        .replaceAll(_wordTimestamp, '')
        .trim();
    for (final stamp in stamps) {
      final fraction = stamp[3] ?? '0';
      final millis = int.parse(fraction.padRight(3, '0').substring(0, 3));
      final start =
          Duration(
            minutes: int.parse(stamp[1]!),
            seconds: int.parse(stamp[2]!),
            milliseconds: millis,
          ) +
          offset;
      timed.add(
        LyricLine(
          text: content,
          start: start.isNegative ? Duration.zero : start,
        ),
      );
    }
  }
  if (timed.isEmpty) {
    while (plain.isNotEmpty && plain.first.text.isEmpty) {
      plain.removeAt(0);
    }
    while (plain.isNotEmpty && plain.last.text.isEmpty) {
      plain.removeLast();
    }
    return Lyrics(lines: plain, origin: origin);
  }
  timed.sort((a, b) => a.start!.compareTo(b.start!));
  return Lyrics(lines: timed, synced: true, origin: origin);
}
