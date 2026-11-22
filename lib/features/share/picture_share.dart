import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Renders the [RepaintBoundary] behind [key] at [width] pixels wide and
/// opens the share sheet with it as `<name>.png`.
Future<void> sharePicture(
  GlobalKey key, {
  required String name,
  double width = 1080,
  String? text,
  Rect? origin,
}) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: width / boundary.size.width);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final dir = Directory('${(await getTemporaryDirectory()).path}/pictures');
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);
  final file = File('${dir.path}/$name.png');
  await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'image/png')],
      text: text,
      sharePositionOrigin: origin,
    ),
  );
}

/// Where the share sheet should point to on tablets: the widget of
/// [context].
Rect? shareOrigin(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
}
