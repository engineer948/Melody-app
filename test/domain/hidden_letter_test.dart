import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:melody/domain/share/hidden_letter.dart';
import 'package:melody/domain/share/mixtape.dart';

void main() {
  test('a letter hidden in pixels comes back; the picture barely changes', () {
    final random = Random(1);
    final rgba = Uint8List.fromList(
      List.generate(64 * 64 * 4, (_) => random.nextInt(256)),
    );
    final before = Uint8List.fromList(rgba);
    const code = 'MELODY-MIX1:abc_DEF-123 ünicode ♪';
    expect(HiddenLetter.hide(rgba, code), isTrue);
    expect(HiddenLetter.reveal(rgba), code);
    for (var i = 0; i < rgba.length; i++) {
      if (i % 4 == 3) {
        expect(rgba[i], 255, reason: 'opaque');
      } else {
        expect((rgba[i] - before[i]).abs(), lessThanOrEqualTo(1));
      }
    }
  });

  test('too small pictures and plain pictures are refused', () {
    expect(HiddenLetter.hide(Uint8List(4 * 10), 'too long a text'), isFalse);
    expect(HiddenLetter.reveal(Uint8List(4 * 1000)), isNull);
    expect(HiddenLetter.capacity(1000), 367);
  });

  test('time capsules and relay letters keep their day and chain', () {
    final letter = Mixtape(
      title: 'Gələcək',
      from: 'Leyla',
      songs: const [MixtapeSong(id: 't1', title: 'Firuze')],
      openOn: DateTime(2027, 3, 21),
      hops: const ['Ali'],
    );
    final back = Mixtape.decode(letter.encode());
    expect(back.openOn, DateTime(2027, 3, 21));
    expect(back.hops, ['Ali']);
    expect(back.sealedAt(DateTime(2027, 3, 20, 23)), isTrue);
    expect(back.sealedAt(DateTime(2027, 3, 21, 0, 1)), isFalse);
    expect(
      const Mixtape(title: 'x', songs: []).sealedAt(DateTime(2000)),
      isFalse,
    );

    final passed = back.passOn(
      const MixtapeSong(id: 't2', title: 'Hadi'),
      by: 'Murad',
    );
    expect(passed.from, 'Murad');
    expect(passed.hops, ['Ali', 'Leyla']);
    expect(passed.songs.map((s) => s.title), ['Firuze', 'Hadi']);
  });
}
