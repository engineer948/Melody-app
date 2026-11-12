import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'artwork_palette.g.dart';

/// Vivid colours taken from a cover, used for backgrounds and accents.
@immutable
class ArtworkPalette {
  /// Creates a palette.
  const ArtworkPalette(this.colors);

  /// Two to four strong colours, most prominent first.
  final List<Color> colors;

  /// The main colour.
  Color get primary => colors.first;

  /// Colour at [index], repeating when there are fewer.
  Color at(int index) => colors[index % colors.length];

  /// Picks vivid colours out of [argbPixels] (ARGB, any order).
  ///
  /// Pale or grey covers still give colourful results: chroma is raised and
  /// tone kept in the middle, so white text stays readable on top.
  static Future<ArtworkPalette?> fromPixels(List<int> argbPixels) async {
    if (argbPixels.isEmpty) return null;
    final quantized = await QuantizerCelebi().quantize(argbPixels, 64);
    final ranked = Score.score(quantized.colorToCount, filter: false);
    final colors = <Color>[];
    for (final argb in ranked) {
      final hct = Hct.fromInt(argb);
      final vivid = Hct.from(
        hct.hue,
        hct.chroma < 4 ? hct.chroma : hct.chroma.clamp(56, 120),
        hct.tone.clamp(38, 58),
      );
      final color = Color(vivid.toInt());
      if (!colors.contains(color)) colors.add(color);
    }
    if (colors.isEmpty) return null;
    if (colors.length == 1) {
      // A second, neighbouring hue keeps gradients alive.
      final hct = Hct.fromInt(colors.first.toARGB32());
      colors.add(
        Color(
          Hct.from((hct.hue + 40) % 360, hct.chroma, hct.tone - 10).toInt(),
        ),
      );
    }
    return ArtworkPalette(colors);
  }
}

/// Palette of [artwork], or `null` while loading, offline or without art.
@Riverpod(keepAlive: true)
Future<ArtworkPalette?> artworkPalette(Ref ref, Artwork? artwork) async {
  final source = ref.watch(activeSourceProvider);
  final uri = source?.artworkUri(artwork, size: 160);
  if (uri == null) return null;
  final provider = ResizeImage(
    CachedNetworkImageProvider('$uri', headers: source?.requestHeaders),
    width: 48,
    height: 48,
  );
  final image = await _load(provider);
  if (image == null) return null;
  try {
    final data = await image.toByteData();
    if (data == null) return null;
    final pixels = <int>[];
    for (var i = 0; i + 3 < data.lengthInBytes; i += 4) {
      final a = data.getUint8(i + 3);
      if (a < 128) continue;
      pixels.add(
        (a << 24) |
            (data.getUint8(i) << 16) |
            (data.getUint8(i + 1) << 8) |
            data.getUint8(i + 2),
      );
    }
    return await ArtworkPalette.fromPixels(pixels);
  } finally {
    image.dispose();
  }
}

Future<ui.Image?> _load(ImageProvider provider) {
  final done = Completer<ui.Image?>();
  final stream = provider.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      if (!done.isCompleted) done.complete(info.image.clone());
      info.dispose();
      stream.removeListener(listener);
    },
    onError: (_, _) {
      if (!done.isCompleted) done.complete(null);
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  return done.future.timeout(
    const Duration(seconds: 15),
    onTimeout: () {
      stream.removeListener(listener);
      return null;
    },
  );
}
