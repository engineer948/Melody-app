import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:zxing2/qrcode.dart';

/// Modules of a QR code: `true` is a dark square.
typedef QrModules = List<List<bool>>;

/// Encodes [text] as a QR code (error correction M).
QrModules encodeQr(String text) {
  final matrix = Encoder.encode(text, ErrorCorrectionLevel.m).matrix!;
  return [
    for (var y = 0; y < matrix.height; y++)
      [for (var x = 0; x < matrix.width; x++) matrix.get(x, y) == 1],
  ];
}

void _paintQr(Canvas canvas, Size size, QrModules modules) {
  const quiet = 4;
  final count = modules.length + quiet * 2;
  final cell = size.shortestSide / count;
  canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
  final dark = Paint()..color = Colors.black;
  for (var y = 0; y < modules.length; y++) {
    for (var x = 0; x < modules.length; x++) {
      if (modules[y][x]) {
        canvas.drawRect(
          Rect.fromLTWH((x + quiet) * cell, (y + quiet) * cell, cell, cell),
          dark,
        );
      }
    }
  }
}

/// Black-on-white QR code (always light, so any camera can read it).
class QrCodeView extends StatelessWidget {
  /// Shows [data] as a QR code [size] wide.
  QrCodeView({required String data, this.size = 240, super.key})
    : _modules = encodeQr(data);

  /// Edge length.
  final double size;

  final QrModules _modules;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _QrPainter(_modules)),
  );
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.modules);

  final QrModules modules;

  @override
  void paint(Canvas canvas, Size size) => _paintQr(canvas, size, modules);

  @override
  bool shouldRepaint(_QrPainter old) => old.modules != modules;
}

/// PNG image of [data] as a QR code, [pixels] wide.
Future<Uint8List> qrPng(String data, {int pixels = 1024}) async {
  final recorder = ui.PictureRecorder();
  final size = Size.square(pixels.toDouble());
  _paintQr(Canvas(recorder), size, encodeQr(data));
  final image = await recorder.endRecording().toImage(pixels, pixels);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes!.buffer.asUint8List();
}

/// Reads a QR code from an image file (PNG, JPEG, WebP, ...).
///
/// Works on a picked picture or screenshot, so no camera permission is
/// needed. Returns `null` when no code is found.
Future<String?> decodeQrImage(Uint8List bytes) async {
  final ui.Image image;
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    image = (await codec.getNextFrame()).image;
    codec.dispose();
  } on Object {
    return null;
  }
  // Large photos are scaled down: QR codes stay readable and decoding
  // stays fast.
  const maxSide = 1600;
  var target = image;
  final longest = image.width > image.height ? image.width : image.height;
  if (longest > maxSide) {
    final scale = maxSide / longest;
    final w = (image.width * scale).round();
    final h = (image.height * scale).round();
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()..filterQuality = FilterQuality.medium,
    );
    target = await recorder.endRecording().toImage(w, h);
    image.dispose();
  }
  final rgba = await target.toByteData();
  final width = target.width;
  final height = target.height;
  target.dispose();
  if (rgba == null) return null;
  final pixels = Int32List(width * height);
  for (var i = 0; i < pixels.length; i++) {
    final o = i * 4;
    pixels[i] =
        (rgba.getUint8(o + 3) << 24) |
        (rgba.getUint8(o) << 16) |
        (rgba.getUint8(o + 1) << 8) |
        rgba.getUint8(o + 2);
  }
  final source = RGBLuminanceSource(width, height, pixels);
  final hints = DecodeHints()..put(DecodeHintType.tryHarder);
  for (final bitmap in [
    BinaryBitmap(HybridBinarizer(source)),
    BinaryBitmap(GlobalHistogramBinarizer(source)),
    BinaryBitmap(HybridBinarizer(InvertedLuminanceSource(source))),
  ]) {
    try {
      return QRCodeReader().decode(bitmap, hints: hints).text;
    } on ReaderException {
      continue;
    }
  }
  return null;
}
