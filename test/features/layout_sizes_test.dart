import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/settings/locale_controller.dart';

import '../helpers/pump_app.dart';

/// The main screens fit phones in landscape and big tablets.
void main() {
  for (final size in const [
    Size(800, 380),
    Size(1280, 800),
    Size(2000, 1200),
  ]) {
    testWidgets('main tabs and settings at ${size.width}x${size.height}', (
      tester,
    ) async {
      await pumpApp(
        tester,
        preferences: {LocaleController.localeKey: 'en'},
        size: size,
      );
      for (final tab in ['Search', 'Library', 'Home']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: tab);
      }
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Settings');
    });
  }
}
