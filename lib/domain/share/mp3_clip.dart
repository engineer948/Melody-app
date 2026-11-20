import 'dart:convert';
import 'dart:typed_data';

/// Cuts a piece out of an MP3 stream at frame boundaries, without decoding.
///
/// Feed the bytes as they arrive with [add]; it returns `true` once the
/// clip is long enough, so the rest of the download can be stopped.
class Mp3Clipper {
  /// Creates a clipper that drops the first [skip] of audio and keeps the
  /// next [length].
  Mp3Clipper({required this.length, this.skip = Duration.zero});

  /// Audio dropped before the clip.
  final Duration skip;

  /// Wanted clip length.
  final Duration length;

  final _out = BytesBuilder(copy: false);
  var _buffer = Uint8List(0);
  var _id3Checked = false;
  var _firstFrame = true;
  var _elapsedUs = 0;
  var _keptUs = 0;

  /// Audio kept so far.
  Duration get kept => Duration(microseconds: _keptUs);

  /// Whether the clip has reached [length].
  bool get isDone => _keptUs >= length.inMicroseconds;

  /// The MP3 frames of the clip.
  Uint8List takeBytes() => _out.takeBytes();

  /// Adds downloaded [chunk]; returns [isDone].
  bool add(List<int> chunk) {
    if (isDone) return true;
    _buffer = _buffer.isEmpty
        ? Uint8List.fromList(chunk)
        : (BytesBuilder(copy: false)
                ..add(_buffer)
                ..add(chunk))
              .takeBytes();
    var p = 0;
    if (!_id3Checked) {
      if (_buffer.length < 10) return false;
      _id3Checked = true;
      p = _id3Size(_buffer);
    }
    final skipUs = skip.inMicroseconds;
    while (!isDone && p + 4 <= _buffer.length) {
      final frame = _frame(_buffer, p);
      if (frame == null) {
        p++; // Not a frame header: look for the next one.
        continue;
      }
      if (p + frame.bytes > _buffer.length) break; // Wait for the rest.
      final isTag = _firstFrame && _isInfoFrame(_buffer, p, frame.bytes);
      _firstFrame = false;
      if (!isTag) {
        if (_elapsedUs >= skipUs) {
          _out.add(Uint8List.sublistView(_buffer, p, p + frame.bytes));
          _keptUs += frame.us;
        }
        _elapsedUs += frame.us;
      }
      p += frame.bytes;
    }
    _buffer = p >= _buffer.length
        ? Uint8List(0)
        : Uint8List.fromList(Uint8List.sublistView(_buffer, p));
    return isDone;
  }

  static int _id3Size(Uint8List b) {
    if (b[0] != 0x49 || b[1] != 0x44 || b[2] != 0x33) return 0; // "ID3"
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

  /// Size in bytes and length of the Layer III frame at [p], or `null`.
  static ({int bytes, int us})? _frame(Uint8List b, int p) {
    if (b[p] != 0xFF || (b[p + 1] & 0xE0) != 0xE0) return null;
    final version = (b[p + 1] >> 3) & 3; // 3: MPEG-1, 2: MPEG-2, 0: 2.5
    final layer = (b[p + 1] >> 1) & 3; // 1: Layer III
    final rateIndex = (b[p + 2] >> 4) & 0xF;
    final srIndex = (b[p + 2] >> 2) & 3;
    if (version == 1 || layer != 1) return null;
    if (rateIndex == 0 || rateIndex == 15 || srIndex == 3) return null;
    final mpeg1 = version == 3;
    final kbps = (mpeg1 ? _rates1 : _rates2)[rateIndex];
    final sampleRate =
        [44100, 48000, 32000][srIndex] >> (mpeg1 ? 0 : (version == 2 ? 1 : 2));
    final samples = mpeg1 ? 1152 : 576;
    final padding = (b[p + 2] >> 1) & 1;
    final bytes = samples ~/ 8 * kbps * 1000 ~/ sampleRate + padding;
    return (bytes: bytes, us: samples * 1000000 ~/ sampleRate);
  }

  /// Whether the frame holds a Xing / Info header (length of the whole
  /// original file, which would be wrong for the clip).
  static bool _isInfoFrame(Uint8List b, int p, int length) {
    final end = (p + length).clamp(0, p + 64);
    for (var i = p + 4; i + 4 <= end; i++) {
      final tag = String.fromCharCodes(b, i, i + 4);
      if (tag == 'Xing' || tag == 'Info') return true;
    }
    return false;
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
