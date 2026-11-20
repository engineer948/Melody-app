import 'dart:typed_data';

import 'package:melody/domain/share/mp3_clip.dart';

/// MPEG-1 Layer III, 128 kbps, 44.1 kHz stereo: 417 bytes, ~26.1 ms.
const fakeFrameBytes = 417;

/// Length of one fake frame in microseconds.
const int fakeFrameUs = 1152 * 1000000 ~/ 44100;

/// Bit offset of the global gain of granule/channel block [block].
int fakeGainBit(int block) => 32 + 20 + block * 59 + 21;

/// Reads [count] bits at [bit].
int readBits(Uint8List b, int bit, int count) {
  var v = 0;
  for (var i = 0; i < count; i++) {
    final at = bit + i;
    v = (v << 1) | ((b[at >> 3] >> (7 - (at & 7))) & 1);
  }
  return v;
}

void _writeBits(Uint8List b, int bit, int count, int value) {
  for (var i = 0; i < count; i++) {
    final at = bit + i;
    final mask = 1 << (7 - (at & 7));
    if ((value >> (count - 1 - i)) & 1 == 1) {
      b[at >> 3] |= mask;
    } else {
      b[at >> 3] &= ~mask & 0xFF;
    }
  }
}

/// One frame with global gain [gain] in all four blocks; byte 200 holds
/// [marker] to recognise it.
Uint8List fakeFrame(int gain, {int marker = 0, bool info = false}) {
  final f = Uint8List(fakeFrameBytes)
    ..[0] = 0xFF
    ..[1] = 0xFB
    ..[2] = 0x90
    ..[3] = 0x00
    ..[200] = marker;
  for (var block = 0; block < 4; block++) {
    final start = 32 + 20 + block * 59;
    _writeBits(f, start, 12, 500); // part2_3_length: not silent
    _writeBits(f, start + 21, 8, gain);
  }
  if (info) f.setAll(36, 'Info'.codeUnits);
  return f;
}

/// A fake song: an ID3 tag, an Info frame, then one frame per entry of
/// [gains] (marker = index % 250), with some junk after frame 5.
Uint8List fakeSong(List<int> gains) {
  final b = BytesBuilder()
    ..add(id3Tag(title: 'Firuze', artist: 'Sezen Aksu'))
    ..add(fakeFrame(0, marker: 255, info: true));
  for (var i = 0; i < gains.length; i++) {
    b.add(fakeFrame(gains[i], marker: i % 250));
    if (i == 5) b.add([0x00, 0xFF, 0x12]);
  }
  return b.takeBytes();
}

/// [seconds] long, quiet (gain 140) except loud (gain 200) from
/// [loudFrom] for [loudFor] seconds.
Uint8List fakeSongWithChorus({
  int seconds = 185,
  int loudFrom = 100,
  int loudFor = 30,
}) {
  final frames = seconds * 1000000 ~/ fakeFrameUs;
  return fakeSong([
    for (var i = 0; i < frames; i++)
      if (i * fakeFrameUs >= loudFrom * 1000000 &&
          i * fakeFrameUs < (loudFrom + loudFor) * 1000000)
        200
      else
        140,
  ]);
}
