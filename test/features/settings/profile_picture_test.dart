import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/features/settings/widgets/profile_picture.dart';

void main() {
  test('pictures are cut to a square from the middle', () async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 300, 100),
      Paint()..color = const Color(0xFF00FF00),
    );
    final image = await recorder.endRecording().toImage(300, 100);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
        .asUint8List();
    final square = (await squarePng(png, size: 64))!;
    final codec = await ui.instantiateImageCodec(square);
    final out = (await codec.getNextFrame()).image;
    expect(out.width, 64);
    expect(out.height, 64);
    expect(await squarePng(Uint8List.fromList([1, 2, 3])), isNull);
  });
}
