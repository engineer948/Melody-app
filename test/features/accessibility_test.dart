import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/player/playback_settings.dart';
import 'package:melody/player/player_controller.dart';

import '../helpers/fake_engine.dart';
import '../helpers/pump_app.dart';

/// Screen readers get a label for every button, and the screens still fit
/// with the largest system font.
void main() {
  const prefs = {
    LocaleController.localeKey: 'en',
    PlaybackSettingsController.key: '{"fadeMs":0}',
  };

  Future<void> visitAll(
    WidgetTester tester,
    Future<void> Function() check,
  ) async {
    for (final tab in ['Search', 'Library', 'Home']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      await check();
    }
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Songs'));
    await tester.pumpAndSettle();
    await check();
    await tester.tap(find.text('Firuze'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Firuze').last);
    await tester.pumpAndSettle();
    await check();
  }

  testWidgets('every tap target has a label', (tester) async {
    final handle = tester.ensureSemantics();
    final c = await pumpApp(
      tester,
      preferences: prefs,
      engine: FakeAudioEngine(),
      size: const Size(400, 900),
    );
    await visitAll(tester, () async {
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
    await c.read(playerControllerProvider.notifier).clear();
    await tester.pumpAndSettle();
    handle.dispose();
  });

  testWidgets('twice the font size still fits', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final c = await pumpApp(
      tester,
      preferences: prefs,
      engine: FakeAudioEngine(),
      size: const Size(400, 900),
    );
    await visitAll(tester, () async {
      expect(tester.takeException(), isNull);
    });
    await c.read(playerControllerProvider.notifier).clear();
    await tester.pumpAndSettle();
  });
}
