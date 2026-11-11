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
