import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/core/settings/theme_controller.dart';
import 'package:melody/core/theme/app_fonts.dart';
import 'package:melody/core/theme/theme_settings.dart';
import 'package:melody/player/playback_settings.dart';

import '../helpers/pump_app.dart';

Future<ProviderContainer> _openSettings(
  WidgetTester tester, {
  Map<String, Object> preferences = const {LocaleController.localeKey: 'en'},
  Color? systemSeed,
}) async {
  final container = await pumpApp(
    tester,
    preferences: preferences,
    systemSeed: systemSeed,
    size: const Size(400, 5000),
  );
  await tester.tap(
    find.byTooltip(preferences.containsValue('tr') ? 'Ayarlar' : 'Settings'),
  );
  await tester.pumpAndSettle();
  return container;
}

ThemeData _theme(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold).last));

void main() {
  testWidgets('pure black appears under dark and makes surfaces black', (
    tester,
  ) async {
    final container = await _openSettings(tester);
    expect(find.text('Pure black'), findsOneWidget);

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(find.text('Pure black'), findsNothing);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pure black'));
    await tester.pumpAndSettle();

    final settings = container.read(themeControllerProvider);
    expect(settings.mode, AppThemeMode.dark);
    expect(settings.pureBlack, isTrue);
    expect(_theme(tester).colorScheme.surface, Colors.black);
  });

  testWidgets('system colors are disabled when unavailable', (tester) async {
    await _openSettings(tester);
    final tile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'System colors'),
    );
    expect(tile.onChanged, isNull);
    expect(tile.value, isFalse);
    expect(find.textContaining('not available'), findsOneWidget);
  });

  testWidgets('picking a preset turns system colors off', (tester) async {
    final container = await _openSettings(
      tester,
      systemSeed: const Color(0xFF00629D),
    );
    await tester.tap(find.widgetWithText(SwitchListTile, 'System colors'));
    await tester.pumpAndSettle();
    expect(_theme(tester).colorScheme.primary, const Color(0xFF00629D));

    await tester.tap(find.byTooltip('Color #34C759'));
    await tester.pumpAndSettle();

    final settings = container.read(themeControllerProvider);
    expect(settings.accent, const Color(0xFF34C759));
    expect(settings.useSystemColors, isFalse);
    expect(_theme(tester).colorScheme.primary, const Color(0xFF34C759));
  });

  testWidgets('a custom color can be typed into the color wheel', (
    tester,
  ) async {
    final container = await _openSettings(tester);
    await tester.tap(find.byTooltip('Custom color'));
    await tester.pumpAndSettle();
    expect(find.text('Pick a color'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '#1E90FF');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(
      container.read(themeControllerProvider).accent,
      const Color(0xFF1E90FF),
    );
  });

  testWidgets('the font can be changed', (tester) async {
    final container = await _openSettings(tester);
    expect(find.text('Work Sans'), findsOneWidget);
    await tester.tap(find.text('Font'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lexend'));
    await tester.pumpAndSettle();
    expect(container.read(themeControllerProvider).font, AppFont.lexend);
    expect(_theme(tester).textTheme.bodyMedium?.fontFamily, 'Lexend');
  });

  testWidgets('playback settings are saved', (tester) async {
    final container = await _openSettings(tester);
    await tester.tap(find.text('Automatic'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Per album').last);
    await tester.pumpAndSettle();
    expect(
      container.read(playbackSettingsControllerProvider).replayGain,
      ReplayGainMode.album,
    );
  });

  testWidgets('language can be changed at runtime', (tester) async {
    final container = await _openSettings(tester);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Azərbaycanca'));
    await tester.pumpAndSettle();
    expect(container.read(localeControllerProvider), const Locale('az'));
    expect(find.text('Görünüş'), findsOneWidget);

    await tester.tap(find.text('Türkçe'));
    await tester.pumpAndSettle();
    expect(find.text('Görünüm'), findsOneWidget);
    expect(find.text('Açık kaynak lisansları'), findsOneWidget);
  });

  testWidgets('about shows the version and opens the license page', (
    tester,
  ) async {
    await _openSettings(tester);
    expect(find.text('9.9.9 (99)'), findsOneWidget);

    await tester.tap(find.text('Open source licenses'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('settings meet accessibility guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await _openSettings(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
