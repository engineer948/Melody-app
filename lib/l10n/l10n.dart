import 'package:flutter/widgets.dart';
import 'package:melody/l10n/app_localizations.dart';

export 'package:melody/l10n/app_localizations.dart';

/// Shorthand access to localized strings.
extension AppLocalizationsX on BuildContext {
  /// Strings for the active locale.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
