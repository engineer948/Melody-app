import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:melody/core/theme/app_fonts.dart';

/// Adds the bundled fonts' licenses to the license page.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final font in AppFont.values) {
      final family = font.family;
      if (family == null) continue;
      final text = await rootBundle.loadString('assets/fonts/$family.OFL.txt');
      yield LicenseEntryWithLineBreaks([font.displayName], text);
    }
  });
}

/// Adds the licenses of the Go modules inside the Tailscale library
/// (Android only; see tool/go_licenses.sh).
void registerGoLicenses() {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/licenses/go_modules.txt');
    for (final part in text.split(RegExp('^=== ', multiLine: true))) {
      final newline = part.indexOf('\n');
      if (newline <= 0) continue;
      final name = part.substring(0, newline).split(' ').first;
      yield LicenseEntryWithLineBreaks([name], part.substring(newline + 1));
    }
  });
}
