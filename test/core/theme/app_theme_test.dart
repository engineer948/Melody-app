import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/theme/app_fonts.dart';
import 'package:melody/core/theme/app_theme.dart';
import 'package:melody/core/theme/theme_settings.dart';

void main() {
  const systemSeed = Color(0xFF00629D);

  test('defaults: system mode, red accent, Work Sans, neutral surfaces', () {
    const settings = ThemeSettings();
    final light = AppTheme.light(settings);
    expect(settings.themeMode, ThemeMode.system);
    expect(light.brightness, Brightness.light);
    expect(AppTheme.dark(settings).brightness, Brightness.dark);
    expect(light.colorScheme.primary, ThemeSettings.defaultAccent);
    expect(light.colorScheme.surface, const Color(0xFFFFFFFF));
    expect(light.textTheme.bodyMedium?.fontFamily, 'WorkSans');
  });

  test('the accent is used exactly, not as a pastel tone', () {
    for (final accent in accentPresets) {
      final theme = AppTheme.light(ThemeSettings(accent: accent));
      expect(theme.colorScheme.primary, accent);
    }
  });

  test('pure black only affects dark mode', () {
    const black = ThemeSettings(mode: AppThemeMode.dark, pureBlack: true);
    expect(AppTheme.dark(black).colorScheme.surface, Colors.black);
    expect(AppTheme.dark(black).scaffoldBackgroundColor, Colors.black);
    expect(
      AppTheme.dark(const ThemeSettings(mode: AppThemeMode.dark))
          .colorScheme
          .surface,
      isNot(Colors.black),
    );
    expect(AppTheme.light(black).colorScheme.surface, isNot(Colors.black));
  });

  test('tint mixes the accent into surfaces', () {
    final neutral = AppTheme.light(const ThemeSettings()).colorScheme;
    final tinted = AppTheme.light(const ThemeSettings(tint: 1)).colorScheme;
    expect(tinted.surface, isNot(neutral.surface));
    expect(tinted.primary, neutral.primary);
  });

  test('wallpaper colors are used only when chosen and available', () {
    const chosen = ThemeSettings(useSystemColors: true);
    expect(
      AppTheme.light(chosen, systemSeed: systemSeed).colorScheme.primary,
      systemSeed,
    );
    expect(
      AppTheme.light(chosen).colorScheme.primary,
      ThemeSettings.defaultAccent,
    );
    expect(
      AppTheme.light(
        const ThemeSettings(),
        systemSeed: systemSeed,
      ).colorScheme.primary,
      ThemeSettings.defaultAccent,
    );
  });

  test('the navigation bar has no indicator pill', () {
    final theme = AppTheme.light(const ThemeSettings());
    expect(theme.navigationBarTheme.indicatorColor, Colors.transparent);
    final selected = theme.navigationBarTheme.iconTheme?.resolve({
      WidgetState.selected,
    });
    expect(selected?.color, ThemeSettings.defaultAccent);
  });

  test('every bundled font has a family, the system font has none', () {
    for (final font in AppFont.values) {
      expect(font.family == null, font == AppFont.system);
    }
    expect(
      AppTheme.light(const ThemeSettings(font: AppFont.system))
          .textTheme
          .bodyMedium
          ?.fontFamily,
      isNot('WorkSans'),
    );
  });

  test('ThemeSettings has value equality', () {
    const a = ThemeSettings(mode: AppThemeMode.dark);
    expect(a, const ThemeSettings(mode: AppThemeMode.dark));
    expect(a.hashCode, const ThemeSettings(mode: AppThemeMode.dark).hashCode);
    expect(a.copyWith(accent: const Color(0xFF123456)), isNot(a));
  });
}
