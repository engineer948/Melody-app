import 'package:melody/domain/models/media.dart';
import 'package:meta/meta.dart';

/// What the story card shows from one moment of a clip on.
@immutable
class LyricFrame {
  /// Creates a frame.
  const LyricFrame({required this.at, this.line, this.next});

  /// Time from the start of the clip.
  final Duration at;

  /// Line being sung; `null` between lines.
  final String? line;

  /// The line after it, shown dimmer.
  final String? next;

  @override
  bool operator ==(Object other) =>
      other is LyricFrame &&
      other.at == at &&
      other.line == line &&
      other.next == next;

  @override
  int get hashCode => Object.hash(at, line, next);

  @override
  String toString() => 'LyricFrame($at, $line / $next)';
}

/// The lines of synced [lyrics] sung between [start] and [end] of the song,
/// as card states from the start of the clip. [offset] shifts the lyrics
/// (positive shows them later), as in the player.
List<LyricFrame> storyLyricFrames(
  Lyrics lyrics, {
  required Duration start,
  required Duration end,
  Duration offset = Duration.zero,
}) {
  if (!lyrics.synced) return const [];
  final lines = lyrics.lines;
  String? text(int i) {
    if (i < 0 || i >= lines.length) return null;
    final t = lines[i].text.trim();
    return t.isEmpty ? null : t;
  }

  LyricFrame frame(Duration at, int i) =>
      LyricFrame(at: at, line: text(i), next: text(i + 1));

  final frames = [frame(Duration.zero, lyrics.lineAt(start - offset))];
  for (var i = 0; i < lines.length; i++) {
    final at = lines[i].start;
    if (at == null) continue;
    final shown = at + offset;
    if (shown <= start || shown >= end) continue;
    final next = frame(shown - start, i);
    // Skip changes that look the same (e.g. two empty lines).
    final last = frames.last;
    if (last.line == next.line && last.next == next.next) continue;
    frames.add(next);
  }
  return frames;
}
