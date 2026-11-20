import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// One MPEG Layer III frame of an MP3 file.
class Mp3Frame {
  const Mp3Frame._({
    required this.offset,
    required this.length,
    required this.startUs,
    required this.durationUs,
    required this.loudness,
    required this.sideInfoBit,
    required this.blocks,
  });

  /// Byte position in the file.
  final int offset;

  /// Size in bytes.
  final int length;

  /// Time at which the frame starts.
  final int startUs;

  /// Length of the frame.
  final int durationUs;

  /// Rough loudness: the average "global gain" of its granules, 0 for
  /// silence (global gain steps are 1.5 dB).
  final double loudness;

  /// Bit position of the side information from the start of the file,
  /// or -1 when it cannot be changed (frames protected by a CRC).
  final int sideInfoBit;

  /// Bit offsets of the granule/channel blocks inside the side information.
  final List<int> blocks;

  /// Time at which the frame ends.
  int get endUs => startUs + durationUs;
}

/// A whole MP3 file, read without decoding: frames, a waveform, the loudest
/// part, and pieces cut at frame boundaries (with fades).
class Mp3Song {
  Mp3Song._(this.bytes, this.frames);

  /// Finds the frames of [bytes]; ID3 tags, the Xing / Info frame and junk
  /// between frames are skipped.
  factory Mp3Song.parse(Uint8List bytes) {
    final frames = <Mp3Frame>[];
    var p = _id3Size(bytes);
    var time = 0;
    var first = true;
    while (p + 4 <= bytes.length) {
      final h = _header(bytes, p);
      if (h == null) {
        p++;
        continue;
      }
      if (p + h.bytes > bytes.length) break;
      final isTag = first && _isInfoFrame(bytes, p, h.bytes);
      first = false;
      if (!isTag) {
        final sideInfo = (p + 4 + (h.crc ? 2 : 0)) * 8;
        final blocks = <int>[
          for (var g = 0; g < h.granules; g++)
            for (var c = 0; c < h.channels; c++)
              h.firstBlock + (g * h.channels + c) * h.blockBits,
        ];
        var sum = 0;
        for (final b in blocks) {
          final bits = _read(bytes, sideInfo + b, 12); // part2_3_length
          if (bits > 0) sum += _read(bytes, sideInfo + b + 21, 8);
        }
        frames.add(
          Mp3Frame._(
            offset: p,
            length: h.bytes,
            startUs: time,
            durationUs: h.us,
            loudness: sum / blocks.length,
            sideInfoBit: h.crc ? -1 : sideInfo,
            blocks: blocks,
          ),
        );
        time += h.us;
      }
      p += h.bytes;
    }
    return Mp3Song._(bytes, frames);
  }

  /// The file.
  final Uint8List bytes;

  /// Its audio frames in order.
  final List<Mp3Frame> frames;

  /// Length of the song.
  Duration get duration =>
      Duration(microseconds: frames.isEmpty ? 0 : frames.last.endUs);

  /// Loudness in [count] equal parts of the song, from 0 (quiet) to 1.
  List<double> waveform(int count) {
    if (frames.isEmpty || count <= 0) return List.filled(max(count, 0), 0);
    final total = frames.last.endUs;
    final sums = List<double>.filled(count, 0);
    final counts = List<int>.filled(count, 0);
    for (final f in frames) {
      final i = min(count - 1, f.startUs * count ~/ total);
      sums[i] += f.loudness;
      counts[i]++;
    }
    final values = [
      for (var i = 0; i < count; i++)
        if (counts[i] == 0) 0.0 else sums[i] / counts[i],
    ];
    // Quiet parts sit around the 5th percentile, loud ones at the top.
    final sorted = [...values.where((v) => v > 0)]..sort();
    if (sorted.isEmpty) return values;
    final low = sorted[(sorted.length * 0.05).floor()];
    final high = sorted.last;
    final range = max(1, high - low);
    return [for (final v in values) ((v - low) / range).clamp(0.0, 1.0)];
  }

  /// Start of the loudest [length] of the song (usually the chorus); the
  /// first and last 8 seconds are not chosen when the song is long enough.
  Duration loudestPart(Duration length) {
    final total = frames.isEmpty ? 0 : frames.last.endUs;
    final window = length.inMicroseconds;
    if (frames.isEmpty || window >= total) return Duration.zero;
    const edge = 8000000;
    final earliest = total - window > 2 * edge ? edge : 0;
    final latest = total - window - earliest;
    // Sliding window over the frames, both ends moving forward.
    var best = -1.0;
    var bestStart = 0;
    var sum = 0.0;
    var end = 0;
    for (var i = 0; i < frames.length; i++) {
      final start = frames[i].startUs;
      if (start > latest) break;
      while (end < frames.length && frames[end].startUs < start + window) {
        sum += frames[end].loudness;
        end++;
      }
      if (start >= earliest && sum > best) {
        best = sum;
        bestStart = start;
      }
      sum -= frames[i].loudness;
    }
    return Duration(microseconds: bestStart);
  }

  /// The frames from [start] for [length] as a playable MP3, fading in and
  /// out over [fadeIn] and [fadeOut] (by lowering each frame's global gain,
  /// so nothing is decoded).
  Uint8List cut(
    Duration start,
    Duration length, {
    Duration fadeIn = Duration.zero,
    Duration fadeOut = Duration.zero,
  }) {
    final from = start.inMicroseconds;
    final to = from + length.inMicroseconds;
    final out = BytesBuilder();
    for (final f in frames) {
      if (f.startUs < from || f.startUs >= to) continue;
      final frame = Uint8List.fromList(
        Uint8List.sublistView(bytes, f.offset, f.offset + f.length),
      );
      final t = f.startUs - from;
      final left = to - f.endUs;
      var level = 1.0;
      if (fadeIn > Duration.zero) {
        level = min(level, t / fadeIn.inMicroseconds);
      }
      if (fadeOut > Duration.zero) {
        level = min(level, left / fadeOut.inMicroseconds);
      }
      if (level < 1 && f.sideInfoBit >= 0) {
        // 40 steps of 1.5 dB: from silent (-60 dB) to full volume.
        final steps = ((1 - level.clamp(0.0, 1.0)) * 40).round();
        final base = f.sideInfoBit - f.offset * 8;
        for (final b in f.blocks) {
          final at = base + b + 21;
          _write(frame, at, 8, max(0, _read(frame, at, 8) - steps));
        }
      }
      out.add(frame);
    }
    return out.takeBytes();
  }

  static int _id3Size(Uint8List b) {
    if (b.length < 10 || b[0] != 0x49 || b[1] != 0x44 || b[2] != 0x33) {
      return 0; // No "ID3".
    }
    final size = (b[6] << 21) | (b[7] << 14) | (b[8] << 7) | b[9];
    final footer = (b[5] & 0x10) != 0 ? 10 : 0;
    return 10 + size + footer;
  }

  static const _rates1 = [
    0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, //
  ];
  static const _rates2 = [
    0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, //
  ];

  static ({
    int bytes,
    int us,
    bool crc,
    int channels,
    int granules,
    int firstBlock,
    int blockBits,
  })?
  _header(Uint8List b, int p) {
    if (b[p] != 0xFF || (b[p + 1] & 0xE0) != 0xE0) return null;
    final version = (b[p + 1] >> 3) & 3; // 3: MPEG-1, 2: MPEG-2, 0: 2.5
    final layer = (b[p + 1] >> 1) & 3; // 1: Layer III
    final rateIndex = (b[p + 2] >> 4) & 0xF;
    final srIndex = (b[p + 2] >> 2) & 3;
    if (version == 1 || layer != 1) return null;
    if (rateIndex == 0 || rateIndex == 15 || srIndex == 3) return null;
    final mpeg1 = version == 3;
    final kbps = (mpeg1 ? _rates1 : _rates2)[rateIndex];
    final shift = mpeg1 ? 0 : (version == 2 ? 1 : 2);
    final sampleRate = [44100, 48000, 32000][srIndex] >> shift;
    final samples = mpeg1 ? 1152 : 576;
    final padding = (b[p + 2] >> 1) & 1;
    final mono = (b[p + 3] >> 6) == 3;
    final channels = mono ? 1 : 2;
    return (
      bytes: samples ~/ 8 * kbps * 1000 ~/ sampleRate + padding,
      us: samples * 1000000 ~/ sampleRate,
      crc: (b[p + 1] & 1) == 0,
      channels: channels,
      granules: mpeg1 ? 2 : 1,
      // main_data_begin, private bits (and scfsi for MPEG-1).
      firstBlock: mpeg1 ? (mono ? 18 : 20) : (mono ? 9 : 10),
      blockBits: mpeg1 ? 59 : 63,
    );
  }

  /// Whether the frame holds a Xing / Info header (length of the whole
  /// original file, which would be wrong for a piece).
  static bool _isInfoFrame(Uint8List b, int p, int length) {
    final end = min(p + length, p + 64);
    for (var i = p + 4; i + 4 <= end; i++) {
      final tag = String.fromCharCodes(b, i, i + 4);
      if (tag == 'Xing' || tag == 'Info') return true;
    }
    return false;
  }

  static int _read(Uint8List b, int bit, int count) {
    var v = 0;
    for (var i = 0; i < count; i++) {
      final at = bit + i;
      v = (v << 1) | ((b[at >> 3] >> (7 - (at & 7))) & 1);
    }
    return v;
  }

  static void _write(Uint8List b, int bit, int count, int value) {
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
}

/// An ID3v2.3 tag with [title] and [artist], so chat apps show the song.
Uint8List id3Tag({required String title, String artist = ''}) {
  Uint8List text(String id, String value) {
    // UTF-16 with BOM: the encoding every ID3v2.3 reader understands.
    final utf16 = <int>[0xFF, 0xFE];
    for (final unit in value.codeUnits) {
      utf16
        ..add(unit & 0xFF)
        ..add(unit >> 8);
    }
    final body = [1, ...utf16];
    return Uint8List.fromList([
      ...ascii.encode(id),
      ..._be32(body.length),
      0,
      0,
      ...body,
    ]);
  }

  final frames = BytesBuilder()..add(text('TIT2', title));
  if (artist.isNotEmpty) frames.add(text('TPE1', artist));
  final body = frames.takeBytes();
  final size = body.length;
  return Uint8List.fromList([
    ...ascii.encode('ID3'),
    3,
    0,
    0,
    (size >> 21) & 0x7F,
    (size >> 14) & 0x7F,
    (size >> 7) & 0x7F,
    size & 0x7F,
    ...body,
  ]);
}

List<int> _be32(int v) => [
  (v >> 24) & 0xFF,
  (v >> 16) & 0xFF,
  (v >> 8) & 0xFF,
  v & 0xFF,
];
