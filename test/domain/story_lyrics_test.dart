import 'package:flutter_test/flutter_test.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/share/story_lyrics.dart';

void main() {
  const lyrics = Lyrics(
    synced: true,
    lines: [
      LyricLine(text: 'Bir', start: Duration(seconds: 10)),
      LyricLine(text: 'İki', start: Duration(seconds: 20)),
      LyricLine(text: '', start: Duration(seconds: 30)),
      LyricLine(text: 'Üç', start: Duration(seconds: 40)),
    ],
  );

  test('lines sung in the piece, from its start', () {
    expect(
      storyLyricFrames(
        lyrics,
        start: const Duration(seconds: 15),
        end: const Duration(seconds: 45),
      ),
      const [
        LyricFrame(at: Duration.zero, line: 'Bir', next: 'İki'),
        LyricFrame(at: Duration(seconds: 5), line: 'İki'),
        LyricFrame(at: Duration(seconds: 15), next: 'Üç'),
        LyricFrame(at: Duration(seconds: 25), line: 'Üç'),
      ],
    );
  });

  test('the offset moves the lines later', () {
    final frames = storyLyricFrames(
      lyrics,
      start: const Duration(seconds: 15),
      end: const Duration(seconds: 25),
      offset: const Duration(seconds: 2),
    );
    expect(frames.map((f) => f.at), const [
      Duration.zero,
      Duration(seconds: 7),
    ]);
  });

  test('before the first line and with plain lyrics', () {
    expect(
      storyLyricFrames(
        lyrics,
        start: Duration.zero,
        end: const Duration(seconds: 5),
      ).single,
      // Nothing sung yet: the first line waits, dimmed.
      const LyricFrame(at: Duration.zero, next: 'Bir'),
    );
    expect(
      storyLyricFrames(
        const Lyrics(lines: [LyricLine(text: 'x')]),
        start: Duration.zero,
        end: const Duration(seconds: 5),
      ),
      isEmpty,
    );
  });
}
