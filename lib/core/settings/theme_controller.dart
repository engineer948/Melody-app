import 'dart:ui';

import 'package:melody/core/settings/preferences.dart';
import 'package:melody/core/theme/app_fonts.dart';
import 'package:melody/core/theme/theme_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_controller.g.dart';

/// Holds and persists the user's appearance preferences.
@Riverpod(keepAlive: true)
class ThemeController extends _$ThemeController {
  /// Preference key of the brightness mode.
  static const modeKey = 'theme.mode';

  /// Preference key of the pure black switch.
  static const pureBlackKey = 'theme.pureBlack';

  /// Preference key of the "use wallpaper colors" switch.
  static const systemColorsKey = 'theme.systemColors';

  /// Preference key of the accent color (ARGB integer).
  static const accentKey = 'theme.accentArgb';

  /// Preference key of the surface tint.
  static const tintKey = 'theme.tint';

  /// Preference key of the bar opacity.
  static const barOpacityKey = 'theme.barOpacity';

  /// Preference key of the font.
  static const fontKey = 'theme.font';

  SharedPreferences get _prefs => ref.read(preferencesProvider);

  @override
  ThemeSettings build() {
    final prefs = ref.watch(preferencesProvider);
    const defaults = ThemeSettings();
    final storedMode = prefs.getString(modeKey);
    // Before 0.3 "black" was a separate mode; it is now dark + pure black.
    final legacyBlack = storedMode == 'black';
    final argb = prefs.getInt(accentKey);
    return ThemeSettings(
      mode: legacyBlack
          ? AppThemeMode.dark
          : AppThemeMode.values.asNameMap()[storedMode] ?? defaults.mode,
      pureBlack: prefs.getBool(pureBlackKey) ?? legacyBlack,
      useSystemColors:
          prefs.getBool(systemColorsKey) ?? defaults.useSystemColors,
      accent: argb == null ? defaults.accent : Color(argb),
      tint: (prefs.getDouble(tintKey) ?? defaults.tint).clamp(0.0, 1.0),
      barOpacity: (prefs.getDouble(barOpacityKey) ?? defaults.barOpacity).clamp(
        0.3,
        1.0,
      ),
      font:
          AppFont.values.asNameMap()[prefs.getString(fontKey)] ?? defaults.font,
    );
  }

  /// Changes the brightness mode.
  Future<void> setMode(AppThemeMode mode) async {
    state = state.copyWith(mode: mode);
    await _prefs.setString(modeKey, mode.name);
  }

  /// Turns pure black dark surfaces on or off.
  Future<void> setPureBlack({required bool value}) async {
    state = state.copyWith(pureBlack: value);
    await _prefs.setBool(pureBlackKey, value);
  }

  /// Turns wallpaper colors on or off.
  Future<void> setUseSystemColors({required bool value}) async {
    state = state.copyWith(useSystemColors: value);
    await _prefs.setBool(systemColorsKey, value);
  }

  /// Changes the accent color and stops following wallpaper colors.
  Future<void> setAccent(Color color) async {
    final opaque = color.withValues(alpha: 1);
    state = state.copyWith(accent: opaque, useSystemColors: false);
    await _prefs.setInt(accentKey, opaque.toARGB32());
    await _prefs.setBool(systemColorsKey, false);
  }

  /// Changes how strongly surfaces are tinted.
  Future<void> setTint(double value) async {
    state = state.copyWith(tint: value.clamp(0.0, 1.0));
    await _prefs.setDouble(tintKey, state.tint);
  }

  /// Changes the opacity of the frosted bars.
  Future<void> setBarOpacity(double value) async {
    state = state.copyWith(barOpacity: value.clamp(0.3, 1.0));
    await _prefs.setDouble(barOpacityKey, state.barOpacity);
  }

  /// Changes the typeface.
  Future<void> setFont(AppFont font) async {
    state = state.copyWith(font: font);
    await _prefs.setString(fontKey, font.name);
  }

  /// Restores every appearance setting to its default.
  Future<void> reset() async {
    state = const ThemeSettings();
    for (final key in [
      modeKey,
      pureBlackKey,
      systemColorsKey,
      accentKey,
      tintKey,
      barOpacityKey,
      fontKey,
    ]) {
      await _prefs.remove(key);
    }
  }
}
