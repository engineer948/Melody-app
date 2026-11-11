import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'system_colors.g.dart';

/// Wallpaper based primary color (Material You), or `null` when the platform
/// does not provide dynamic colors.
@Riverpod(keepAlive: true)
Future<Color?> systemSeedColor(Ref ref) async {
  try {
    final palette = await DynamicColorPlugin.getCorePalette();
    return palette?.toColorScheme().primary;
  } on Exception {
    return null;
  }
}
