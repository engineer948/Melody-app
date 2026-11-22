import 'dart:convert';
import 'dart:typed_data';

/// Hides text in the lowest bit of the red, green and blue values of RGBA
/// pixels, so a photo looks the same but carries a song letter. Survives
/// only lossless files (PNG sent as a file), not recompressed photos.
abstract final class HiddenLetter {
  static const _magic = [0x4D, 0x4C, 0x44, 0x59]; // "MLDY"
  static const _header = 8; // magic + 4-byte length

  /// Bytes of text that fit in [pixels] pixels.
  static int capacity(int pixels) => (pixels * 3) ~/ 8 - _header;

  /// Writes [text] into [rgba] (changed in place) and makes every pixel
  /// opaque; returns `false` when it does not fit.
  static bool hide(Uint8List rgba, String text) {
    final body = utf8.encode(text);
    final pixels = rgba.length ~/ 4;
    if (body.length > capacity(pixels)) return false;
    final data = Uint8List(_header + body.length)
      ..setRange(0, 4, _magic)
      ..buffer.asByteData().setUint32(4, body.length)
      ..setRange(_header, _header + body.length, body);
    var bit = 0;
    for (final byte in data) {
      for (var i = 7; i >= 0; i--) {
        final index = _channel(bit++);
        rgba[index] = (rgba[index] & 0xFE) | ((byte >> i) & 1);
      }
    }
    for (var p = 3; p < rgba.length; p += 4) {
      rgba[p] = 0xFF;
    }
    return true;
  }

  /// The text hidden in [rgba] by [hide], or `null`.
  static String? reveal(Uint8List rgba) {
    final pixels = rgba.length ~/ 4;
    if (capacity(pixels) <= 0) return null;
    var bit = 0;
    int readByte() {
      var value = 0;
      for (var i = 0; i < 8; i++) {
        value = (value << 1) | (rgba[_channel(bit++)] & 1);
      }
      return value;
    }

    for (final m in _magic) {
      if (readByte() != m) return null;
    }
    final length =
        (readByte() << 24) |
        (readByte() << 16) |
        (readByte() << 8) |
        readByte();
    if (length <= 0 || length > capacity(pixels)) return null;
    final body = Uint8List(length);
    for (var i = 0; i < length; i++) {
      body[i] = readByte();
    }
    try {
      return utf8.decode(body);
    } on FormatException {
      return null;
    }
  }

  /// Index in the RGBA bytes of data bit [bit] (alpha is skipped).
  static int _channel(int bit) => (bit ~/ 3) * 4 + bit % 3;
}
