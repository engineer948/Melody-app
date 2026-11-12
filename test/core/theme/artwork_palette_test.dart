import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:melody/core/theme/artwork_palette.dart';

void main() {
  test('takes vivid colours from a cover, most prominent first', () async {
    final pixels = [
      ...List.filled(600, 0xFF1E3A8A), // Lots of blue.
      ...List.filled(250, 0xFFF59E0B), // Some amber.
    ];
    final palette = (await ArtworkPalette.fromPixels(pixels))!;
    expect(palette.colors.length, greaterThanOrEqualTo(2));
    final first = Hct.fromInt(palette.primary.toARGB32());
    expect(first.hue, closeTo(Hct.fromInt(0xFF1E3A8A).hue, 15));
    for (final c in palette.colors) {
      final hct = Hct.fromInt(c.toARGB32());
      expect(hct.tone, inInclusiveRange(37, 59));
    }
  });

  test('a single pale colour is made vivid and gets a companion', () async {
    final palette = (await ArtworkPalette.fromPixels(
      List.filled(400, 0xFFE8D5D5),
    ))!;
    expect(palette.colors, hasLength(2));
    expect(Hct.fromInt(palette.primary.toARGB32()).chroma, greaterThan(40));
    expect(palette.at(5), isA<Color>());
  });

  test('no pixels, no palette', () async {
    expect(await ArtworkPalette.fromPixels(const []), isNull);
  });
}
