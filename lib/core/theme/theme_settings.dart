import 'package:flutter/material.dart';
import 'package:melody/core/theme/app_fonts.dart';

/// Brightness choices offered to the user.
enum AppThemeMode {
  /// Follow the operating system.
  system,

  /// Always light.
  light,

  /// Always dark.
  dark,
}

/// Appearance preferences that drive `ThemeData` creation.
@immutable
class ThemeSettings {
  /// Creates a set of appearance preferences.
  const ThemeSettings({
    this.mode = AppThemeMode.system,
    this.pureBlack = false,
    this.useSystemColors = false,
    this.accent = defaultAccent,
    this.tint = defaultTint,
    this.barOpacity = defaultBarOpacity,
    this.font = AppFont.workSans,
  });

  /// Accent used out of the box.
  static const defaultAccent = Color(0xFFE5383B);

  /// How strongly surfaces are tinted with the accent out of the box.
  static const defaultTint = 0.5;

  /// Opacity of the frosted navigation bars out of the box.
  static const defaultBarOpacity = 0.8;

  /// Selected brightness behavior.
  final AppThemeMode mode;

  /// Whether dark surfaces are pure black (OLED). Only affects dark mode.
  final bool pureBlack;

  /// Whether wallpaper colors (Material You) replace [accent] when the
  /// platform offers them.
  final bool useSystemColors;

  /// Accent color picked by the user.
  final Color accent;

  /// 0 keeps surfaces neutral grey, 1 tints them clearly with the accent.
  final double tint;

  /// Opacity of the frosted app and navigation bars, 0.3 to 1.
  final double barOpacity;

  /// Typeface of the whole app.
  final AppFont font;

  /// Flutter theme mode matching [mode].
  ThemeMode get themeMode => switch (mode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };

  /// Returns a copy with the given fields replaced.
  ThemeSettings copyWith({
    AppThemeMode? mode,
    bool? pureBlack,
    bool? useSystemColors,
    Color? accent,
    double? tint,
    double? barOpacity,
    AppFont? font,
  }) => ThemeSettings(
    mode: mode ?? this.mode,
    pureBlack: pureBlack ?? this.pureBlack,
    useSystemColors: useSystemColors ?? this.useSystemColors,
    accent: accent ?? this.accent,
    tint: tint ?? this.tint,
    barOpacity: barOpacity ?? this.barOpacity,
    font: font ?? this.font,
  );

  @override
  bool operator ==(Object other) =>
      other is ThemeSettings &&
      other.mode == mode &&
      other.pureBlack == pureBlack &&
      other.useSystemColors == useSystemColors &&
      other.accent == accent &&
      other.tint == tint &&
      other.barOpacity == barOpacity &&
      other.font == font;

  @override
  int get hashCode => Object.hash(
    mode,
    pureBlack,
    useSystemColors,
    accent,
    tint,
    barOpacity,
    font,
  );
}

/// Ready-made accent colors shown above the color wheel.
const accentPresets = <Color>[
  Color(0xFFE5383B), // red (default)
  Color(0xFFFF2D55),
  Color(0xFFD81B60),
  Color(0xFFFF4F9A),
  Color(0xFFC2185B),
  Color(0xFFB3364A),
  Color(0xFFFF6B35),
  Color(0xFFFF9500),
  Color(0xFFF4A300),
  Color(0xFFFFCC00),
  Color(0xFFC0CA33),
  Color(0xFF7CB342),
  Color(0xFF34C759),
  Color(0xFF2E7D32),
  Color(0xFF00A86B),
  Color(0xFF00BFA5),
  Color(0xFF00A3B4),
  Color(0xFF30B0C7),
  Color(0xFF0A84FF),
  Color(0xFF1E5EFF),
  Color(0xFF3F51B5),
  Color(0xFF5856D6),
  Color(0xFF7E57C2),
  Color(0xFFAF52DE),
  Color(0xFF8E4585),
  Color(0xFFA2845E),
  Color(0xFF795548),
  Color(0xFF607D8B),
  Color(0xFF8E8E93),
  Color(0xFF3A3A3C),
];
