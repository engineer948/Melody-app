import 'dart:ui';

import 'package:melody/core/settings/preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_controller.g.dart';

/// Holds the language override; `null` means "follow the system".
@Riverpod(keepAlive: true)
class LocaleController extends _$LocaleController {
  /// Preference key of the language override.
  static const localeKey = 'app.locale';

  @override
  Locale? build() {
    final code = ref.watch(preferencesProvider).getString(localeKey);
    return code == null || code.isEmpty ? null : Locale(code);
  }

  /// Sets the language override, or clears it when [locale] is `null`.
  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = ref.read(preferencesProvider);
    if (locale == null) {
      await prefs.remove(localeKey);
    } else {
      await prefs.setString(localeKey, locale.languageCode);
    }
  }
}
