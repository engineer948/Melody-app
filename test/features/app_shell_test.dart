import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/router/app_router.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/features/home/home_screen.dart';
import 'package:melody/features/library/library_screen.dart';
import 'package:melody/features/search/search_screen.dart';
import 'package:melody/features/settings/settings_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  const tr = {LocaleController.localeKey: 'tr'};

  testWidgets('phones get a bottom bar and can switch tabs', (tester) async {
    await pumpApp(tester, preferences: tr);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.text('Kütüphane').last);
    await tester.pumpAndSettle();
    expect(find.byType(LibraryScreen), findsOneWidget);
    expect(find.text('Albümler'), findsOneWidget);

    await tester.tap(find.text('Ara').last);
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('the selected tab has no indicator pill', (tester) async {
    await pumpApp(tester, preferences: tr);
    final theme = Theme.of(tester.element(find.byType(NavigationBar)));
    expect(theme.navigationBarTheme.indicatorColor, Colors.transparent);
  });

  testWidgets('settings keep the tab bar, so home is one tap away', (
    tester,
  ) async {
    final container = await pumpApp(tester, preferences: tr);
    await tester.tap(find.text('Kütüphane').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ayarlar').first);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('Ana sayfa').last);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    // The old settings location still works.
    container.read(appRouterProvider).go('/settings');
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('wide windows get a navigation rail', (tester) async {
    await pumpApp(tester, preferences: tr, size: const Size(900, 700));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('only Jellyfin is ever mentioned', (tester) async {
    await pumpApp(tester, preferences: tr, signedIn: false);
    expect(find.textContaining('Jellyfin'), findsWidgets);
    for (final hidden in ['Emby', 'Subsonic', 'Navidrome', 'Radyo']) {
      expect(find.textContaining(hidden), findsNothing);
    }
  });

  testWidgets('unknown locations show a friendly page', (tester) async {
    final container = await pumpApp(tester, preferences: tr);
    container.read(appRouterProvider).go('/does-not-exist');
    await tester.pumpAndSettle();

    expect(find.text('Bu sayfa bulunamadı.'), findsOneWidget);
    await tester.tap(find.text('Ana sayfaya dön'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('tap targets and labels meet accessibility guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, preferences: tr);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
