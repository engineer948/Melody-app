import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:melody/domain/share/mp3_clip.dart';

/// MPEG-1 Layer III, 128 kbps, 44.1 kHz: 417 bytes and ~26.1 ms a frame.
const frameBytes = 417;
const int frameUs = 1152 * 1000000 ~/ 44100;

Uint8List frame(int marker, {bool info = false}) {
  final f = Uint8List(frameBytes)
    ..[0] = 0xFF
    ..[1] = 0xFB
    ..[2] = 0x90
    ..[3] = 0x00
    ..[4] = marker;
  if (info) f.setAll(36, 'Info'.codeUnits);
  return f;
}

Uint8List song(int frames) {
  final b = BytesBuilder()
    ..add(id3Tag(title: 'Firuze', artist: 'Sezen Aksu'))
    ..add(frame(255, info: true));
  for (var i = 0; i < frames; i++) {
    b.add(frame(i % 200));
    // Some junk between frames must be skipped.
    if (i == 5) b.add([0x00, 0xFF, 0x12]);
  }
  return b.takeBytes();
}

void feed(Mp3Clipper clipper, Uint8List bytes, Random random) {
  var p = 0;
  while (p < bytes.length && !clipper.isDone) {
    final n = min(1 + random.nextInt(3000), bytes.length - p);
    clipper.add(Uint8List.sublistView(bytes, p, p + n));
    p += n;
  }
}

void main() {
  test('keeps whole frames from the skip point for the wanted length', () {
    for (final seed in [1, 2, 3]) {
      final clipper = Mp3Clipper(
        skip: const Duration(seconds: 1),
        length: const Duration(seconds: 2),
      );
      feed(clipper, song(400), Random(seed));
      expect(clipper.isDone, isTrue);
      final out = clipper.takeBytes();
      // First kept frame starts at or after 1 s; enough frames for 2 s.
      final first = (1000000 / frameUs).ceil();
      final count = (2000000 / frameUs).ceil();
      expect(out.length, count * frameBytes);
      expect(out[4], first % 200);
      for (var i = 0; i < count; i++) {
        expect(out[i * frameBytes], 0xFF);
        expect(out[i * frameBytes + 4], (first + i) % 200);
      }
    }
  });

  test('drops the ID3 tag and the Info frame of the original file', () {
    final clipper = Mp3Clipper(length: const Duration(milliseconds: 100))
      ..add(song(10));
    final out = clipper.takeBytes();
    expect(out[0], 0xFF);
    expect(out[4], 0); // Frame 0, not the Info frame (marker 255).
  });

  test('a song shorter than the clip gives what there is', () {
    final clipper = Mp3Clipper(length: const Duration(seconds: 30))
      ..add(song(20));
    expect(clipper.isDone, isFalse);
    expect(clipper.kept, const Duration(microseconds: 20 * frameUs));
  });

  test('id3Tag holds title and artist in UTF-16 with a syncsafe size', () {
    final tag = id3Tag(title: 'Gülümse', artist: 'Sezen');
    expect(String.fromCharCodes(tag.sublist(0, 3)), 'ID3');
    final size = (tag[6] << 21) | (tag[7] << 14) | (tag[8] << 7) | tag[9];
    expect(size, tag.length - 10);
    expect(String.fromCharCodes(tag.sublist(10, 14)), 'TIT2');
    // Encoding byte 1, BOM, then "G" in UTF-16LE.
    expect(tag.sublist(20, 25), [1, 0xFF, 0xFE, 0x47, 0x00]);
  });
}
