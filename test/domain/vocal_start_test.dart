import 'package:flutter_test/flutter_test.dart';
import 'package:melody/domain/lyrics/vocal_start.dart';

/// 20 ms levels: [silence] s of nothing, instruments (as loud in the
/// middle as at the sides) until [voice] s, then a singer in the middle.
({List<double> mid, List<double> side}) _song({
  double silence = 1,
  double voice = 8,
  double length = 20,
  double instruments = 0.05,
}) {
  final mid = <double>[];
  final side = <double>[];
  for (var t = 0.0; t < length; t += 0.02) {
    if (t < silence) {
      mid.add(0.0001);
      side.add(0.0001);
    } else if (t < voice) {
      // A little beat so it is not perfectly flat.
      final beat = (t * 2).floor().isEven ? 1.0 : 0.8;
      mid.add(instruments * beat);
      side.add(instruments * beat);
    } else {
      mid.add(0.3);
      side.add(instruments);
    }
  }
  return (mid: mid, side: side);
}

void main() {
  test('the singing is found after an instrumental intro', () {
    final song = _song();
    final start = vocalStart(song.mid, song.side)!;
    expect(start.inMilliseconds, closeTo(8000, 300));
  });

  test('a quiet intro and a short silence still count as music', () {
    final song = _song(silence: 0.5, length: 18);
    final start = vocalStart(song.mid, song.side)!;
    expect(start.inMilliseconds, closeTo(8000, 300));
  });

  test('louder instruments alone are not singing', () {
    final mid = <double>[];
    final side = <double>[];
    for (var t = 0.0; t < 20; t += 0.02) {
      final v = t < 1 ? 0.0001 : (t < 6 ? 0.05 : 0.12);
      mid.add(v);
      side.add(v);
    }
    expect(vocalStart(mid, side), isNull);
  });

  test('too little audio or none at all gives nothing', () {
    expect(vocalStart(const [0.1, 0.1], const [0.1, 0.1]), isNull);
    expect(
      vocalStart(List.filled(500, 0.0001), List.filled(500, 0.0001)),
      isNull,
    );
  });

  test('the correction moves the first line to the singing', () {
    const s = Duration(seconds: 8);
    expect(
      vocalLyricsOffset(s, const Duration(seconds: 6)),
      s - const Duration(seconds: 6),
    );
    expect(
      vocalLyricsOffset(s, const Duration(milliseconds: 7900)),
      Duration.zero,
      reason: 'close enough',
    );
    expect(
      vocalLyricsOffset(s, const Duration(seconds: 30)),
      isNull,
      reason: 'too far: the detection is probably wrong',
    );
    expect(vocalLyricsOffset(null, s), isNull);
    expect(vocalLyricsOffset(s, null), isNull);
  });
}
