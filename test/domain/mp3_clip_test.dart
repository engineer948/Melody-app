import 'package:flutter_test/flutter_test.dart';
import 'package:melody/domain/share/mp3_clip.dart';

import '../helpers/fake_mp3.dart';

void main() {
  test('frames are found past the tag, the Info frame and junk', () {
    final song = Mp3Song.parse(fakeSong(List.filled(100, 160)));
    expect(song.frames, hasLength(100));
    expect(song.frames.first.loudness, 160);
    expect(song.bytes[song.frames.first.offset + 200], 0, reason: 'frame 0');
    expect(song.duration, const Duration(microseconds: 100 * fakeFrameUs));
  });

  test('the waveform follows the loudness', () {
    final song = Mp3Song.parse(fakeSongWithChorus());
    final wave = song.waveform(37); // 5 s per bar
    expect(wave[0], lessThan(0.1));
    expect(wave[22], greaterThan(0.9)); // 110 s
    expect(wave[30], lessThan(0.1)); // 150 s
  });

  test('the best part is the loud one, away from the edges', () {
    final song = Mp3Song.parse(fakeSongWithChorus());
    final start = song.loudestPart(const Duration(seconds: 20));
    expect(start.inSeconds, inInclusiveRange(99, 110));

    // Loudest at the very start: the first 8 seconds are avoided.
    final intro = Mp3Song.parse(fakeSongWithChorus(loudFrom: 0, loudFor: 20));
    expect(
      intro.loudestPart(const Duration(seconds: 10)).inMilliseconds,
      greaterThanOrEqualTo(8000),
    );

    // A piece longer than the song starts at 0.
    final short = Mp3Song.parse(fakeSong(List.filled(50, 160)));
    expect(short.loudestPart(const Duration(seconds: 30)), Duration.zero);
  });

  test('a cut keeps whole frames and fades in and out', () {
    final gains = [for (var i = 0; i < 400; i++) 180];
    final song = Mp3Song.parse(fakeSong(gains));
    final out = song.cut(
      const Duration(seconds: 2),
      const Duration(seconds: 5),
      fadeIn: const Duration(seconds: 1),
      fadeOut: const Duration(seconds: 1),
    );
    final first = (2000000 / fakeFrameUs).ceil();
    final count = ((7000000 - 1) ~/ fakeFrameUs) - first + 1;
    expect(out.length, count * fakeFrameBytes);
    int gain(int frame) =>
        readBits(out, frame * fakeFrameBytes * 8 + fakeGainBit(0), 8);
    expect(out[200], first % 250, reason: 'starts at 2 s');
    expect(gain(0), 180 - 40, reason: 'silent at the start');
    expect(gain(count ~/ 2), 180, reason: 'full volume in the middle');
    expect(gain(count - 1), lessThan(180 - 35), reason: 'silent at the end');
    // Every block of a frame is faded, the original is untouched.
    expect(readBits(out, fakeGainBit(3), 8), 180 - 40);
    expect(song.frames[first].loudness, 180);
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
