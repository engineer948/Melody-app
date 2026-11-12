import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/core/settings/theme_controller.dart';
import 'package:melody/core/theme/app_fonts.dart';
import 'package:melody/core/theme/theme_settings.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('ThemeController', () {
    test('starts with defaults', () async {
      final container = await createContainer();
      expect(container.read(themeControllerProvider), const ThemeSettings());
    });

    test('the old black mode becomes dark with pure black', () async {
      final container = await createContainer(
        preferences: {ThemeController.modeKey: 'black'},
      );
      expect(
        container.read(themeControllerProvider),
        const ThemeSettings(mode: AppThemeMode.dark, pureBlack: true),
      );
    });

    test('ignores unknown values and clamps sliders', () async {
      final container = await createContainer(
        preferences: {
          ThemeController.modeKey: 'neon',
          ThemeController.fontKey: 'comicSans',
          ThemeController.tintKey: 7.0,
          ThemeController.barOpacityKey: 0.0,
        },
      );
      final settings = container.read(themeControllerProvider);
      expect(settings.mode, AppThemeMode.system);
      expect(settings.font, AppFont.workSans);
      expect(settings.tint, 1);
      expect(settings.barOpacity, 0.3);
    });

    test('persists changes and can reset them', () async {
      final container = await createContainer();
      final controller = container.read(themeControllerProvider.notifier);
      await controller.setMode(AppThemeMode.dark);
      await controller.setPureBlack(value: true);
      await controller.setUseSystemColors(value: true);
      await controller.setAccent(const Color(0x80123456));
      await controller.setTint(0.5);
      await controller.setBarOpacity(0.6);
      await controller.setFont(AppFont.inter);

      const expected = ThemeSettings(
        mode: AppThemeMode.dark,
        pureBlack: true,
        accent: Color(0xFF123456),
        tint: 0.5,
        barOpacity: 0.6,
        font: AppFont.inter,
      );
      expect(container.read(themeControllerProvider), expected);
      final prefs = container.read(preferencesProvider);
      expect(prefs.getString(ThemeController.modeKey), 'dark');
      expect(prefs.getInt(ThemeController.accentKey), 0xFF123456);
      expect(prefs.getBool(ThemeController.systemColorsKey), isFalse);
      expect(prefs.getString(ThemeController.fontKey), 'inter');

      container.invalidate(themeControllerProvider);
      expect(container.read(themeControllerProvider), expected);

      await container.read(themeControllerProvider.notifier).reset();
      expect(container.read(themeControllerProvider), const ThemeSettings());
      expect(prefs.containsKey(ThemeController.accentKey), isFalse);
    });
  });

  group('LocaleController', () {
    test('follows the system by default', () async {
      final container = await createContainer();
      expect(container.read(localeControllerProvider), isNull);
    });

    test('restores, changes and clears the override', () async {
      final container = await createContainer(
        preferences: {LocaleController.localeKey: 'az'},
      );
      expect(container.read(localeControllerProvider), const Locale('az'));

      final controller = container.read(localeControllerProvider.notifier);
      await controller.setLocale(const Locale('tr'));
      expect(container.read(localeControllerProvider), const Locale('tr'));
      expect(
        container
            .read(preferencesProvider)
            .getString(LocaleController.localeKey),
        'tr',
      );

      await controller.setLocale(null);
      expect(container.read(localeControllerProvider), isNull);
      expect(
        container
            .read(preferencesProvider)
            .containsKey(LocaleController.localeKey),
        isFalse,
      );
    });
  });
}
