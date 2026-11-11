import 'package:flutter_test/flutter_test.dart';
import 'package:melody/domain/lyrics/lrc_parser.dart';
import 'package:melody/domain/models/media.dart';

void main() {
  test('parses timed lines, repeated stamps and fractions', () {
    final lyrics = parseLrc('''
[ar:Sezen Aksu]
[ti:Firuze]
[00:12.5]Firuze
[00:20.25][01:05.00]Gözlerin
[00:30:750]Üçüncü
''');
    expect(lyrics.synced, isTrue);
    expect(lyrics.lines.map((l) => l.text), [
      'Firuze',
      'Gözlerin',
      'Üçüncü',
      'Gözlerin',
    ]);
    expect(lyrics.lines.map((l) => l.start?.inMilliseconds), [
      12500,
      20250,
      30750,
      65000,
    ]);
  });

  test('applies the offset tag and drops word timestamps', () {
    final lyrics = parseLrc(
      '[offset:+500]\n[00:01.00]<00:01.00>Bir <00:01.50>iki',
    );
    expect(lyrics.lines.single.text, 'Bir iki');
    expect(lyrics.lines.single.start, const Duration(milliseconds: 500));
  });

  test('text without timestamps is unsynchronised', () {
    final lyrics = parseLrc('\n\nBirinci satır\n\nİkinci satır\n\n');
    expect(lyrics.synced, isFalse);
    expect(lyrics.lines.map((l) => l.text), [
      'Birinci satır',
      '',
      'İkinci satır',
    ]);
    expect(lyrics.lineAt(const Duration(seconds: 10)), -1);
  });

  test('finds the line for a position', () {
    final lyrics = parseLrc('[00:01.00]a\n[00:05.00]b\n[00:09.00]c');
    expect(lyrics.lineAt(Duration.zero), -1);
    expect(lyrics.lineAt(const Duration(seconds: 1)), 0);
    expect(lyrics.lineAt(const Duration(seconds: 6)), 1);
    expect(lyrics.lineAt(const Duration(minutes: 5)), 2);
  });

  test('lyrics survive a JSON round trip', () {
    final lyrics = parseLrc('[00:01.00]a', origin: LyricsOrigin.lrclib);
    expect(Lyrics.fromJson(lyrics.toJson()), lyrics);
    expect(const Lyrics().isEmpty, isTrue);
  });
}
