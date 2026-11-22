import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/stats/play_event.dart';
import 'package:melody/features/stats/life_screen.dart';
import 'package:melody/player/history_recorder.dart';
import 'package:melody/player/listening_settings.dart';
import 'package:melody/player/player_controller.dart';

import '../helpers/fake_places.dart';
import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

const Map<String, Object> _english = {LocaleController.localeKey: 'en'};

Track _song(String id, String title) => Track(
  id: id,
  title: title,
  artists: const [NamedRef(id: 'ar1', name: 'Sezen')],
  duration: const Duration(minutes: 3),
);

void main() {
  test('remembering places alone means the one switch is on', () {
    const placesOnly = {'places': true};
    expect(ListeningSettings.fromJson(placesOnly).lifeShelf, isTrue);
    expect(ListeningSettings.fromJson(const {}).lifeShelf, isFalse);
  });

  testWidgets('turning it on asks for location; days show places and firsts', (
    tester,
  ) async {
    final places = FakePlacesBridge();
    final c = await pumpApp(
      tester,
      preferences: _english,
      size: const Size(400, 6000),
      overrides: [placesBridgeProvider.overrideWithValue(places)],
    );
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Soundtrack of your life'),
    );
    await tester.pumpAndSettle();
    expect(c.read(listeningSettingsControllerProvider).places, isTrue);
    expect(c.read(listeningSettingsControllerProvider).lifeShelf, isTrue);
    expect(places.locationAllowed, isTrue);

    // A play now records the place.
    final store = c.read(historyStoreProvider);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final here = await c.read(placeLocatorProvider).current('en');
    expect(here?.name, 'Sahil, Bakı');
    await store.add(
      testAccount.id,
      PlayEvent(
        track: _song('t1', 'Firuze'),
        startedAt: yesterday,
        listened: const Duration(minutes: 3),
        place: here,
      ),
    );
    c.read(historyRevisionProvider.notifier).bump();

    await tester.tap(find.text('Listening statistics'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Soundtrack of your life'));
    await tester.pumpAndSettle();
    expect(find.text('Sahil, Bakı'), findsOneWidget);
    expect(find.text('Firuze'), findsOneWidget);
    expect(find.text('✨ First time'), findsOneWidget);
  });

  testWidgets('a song played long ago shows when and where on the player', (
    tester,
  ) async {
    final places = FakePlacesBridge()..locationAllowed = true;
    final c = await pumpApp(
      tester,
      preferences: {
        ..._english,
        ListeningSettingsController.key: '{"places":true}',
      },
      overrides: [placesBridgeProvider.overrideWithValue(places)],
    );
    await c
        .read(historyStoreProvider)
        .add(
          testAccount.id,
          PlayEvent(
            track: makeTrack('t1', title: 'Firuze'),
            startedAt: DateTime(2024, 3, 12),
            listened: const Duration(minutes: 3),
            place: PlayPlace(latitude: 40.4, longitude: 49.9, name: 'Bakı'),
          ),
        );
    final song = c.read(placeLocatorProvider);
    expect(song, isNotNull);

    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Songs'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Firuze'),
        matching: find.byTooltip('More options'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text("This song's story"));
    await tester.tap(find.text("This song's story"));
    await tester.pumpAndSettle();
    expect(find.text('First heard on March 12, 2024'), findsOneWidget);
    expect(find.text('Bakı'), findsOneWidget);
    expect(find.text('Played once'), findsOneWidget);
  });

  testWidgets('home shows the latest days and "on this day" years ago', (
    tester,
  ) async {
    final c = await pumpApp(
      tester,
      preferences: {
        ..._english,
        ListeningSettingsController.key: '{"lifeShelf":true,"lifeAsked":true}',
      },
      size: const Size(400, 2000),
      overrides: [placesBridgeProvider.overrideWithValue(FakePlacesBridge())],
    );
    final now = DateTime.now();
    final store = c.read(historyStoreProvider);
    Future<void> listen(String id, String title, DateTime at) => store.add(
      testAccount.id,
      PlayEvent(
        track: _song(id, title),
        startedAt: at,
        listened: const Duration(minutes: 3),
        place: PlayPlace(latitude: 40.4, longitude: 49.9, name: 'Bakı'),
      ),
    );
    await listen(
      't1',
      'Firuze',
      DateTime(now.year - 1, now.month, now.day, 12),
    );
    await listen('t2', 'Hadi', now.subtract(const Duration(days: 1)));
    c.read(historyRevisionProvider.notifier).bump();
    await tester.pumpAndSettle();

    expect(find.text('Soundtrack of your life'), findsOneWidget);
    expect(find.text('1 year ago today'), findsOneWidget);
    expect(find.text('♪ Firuze · Sezen'), findsOneWidget);
    expect(find.text('♪ Hadi · Sezen'), findsOneWidget);
    expect(find.text('📍 Bakı'), findsNWidgets(2));

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.byType(Card), findsWidgets);
  });

  testWidgets('home asks once after a few days, then remembers the answer', (
    tester,
  ) async {
    final places = FakePlacesBridge();
    final c = await pumpApp(
      tester,
      preferences: _english,
      size: const Size(400, 2000),
      overrides: [placesBridgeProvider.overrideWithValue(places)],
    );
    final store = c.read(historyStoreProvider);
    final now = DateTime.now();
    Future<void> listenDaysAgo(int days) => store.add(
      testAccount.id,
      PlayEvent(
        track: _song('t$days', 'Song $days'),
        startedAt: now.subtract(Duration(days: days)),
        listened: const Duration(minutes: 3),
      ),
    );
    await listenDaysAgo(1);
    await listenDaysAgo(2);
    c.read(historyRevisionProvider.notifier).bump();
    await tester.pumpAndSettle();
    expect(find.text('Turn on'), findsNothing, reason: 'too early to ask');

    await listenDaysAgo(3);
    c.read(historyRevisionProvider.notifier).bump();
    await tester.pumpAndSettle();
    expect(find.text('Turn on'), findsOneWidget);
    expect(find.text('♪ Song 1 · Sezen'), findsNothing, reason: 'not yet');

    // One answer turns on the cards and places together.
    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();
    final settings = c.read(listeningSettingsControllerProvider);
    expect(
      (settings.lifeAsked, settings.lifeShelf, settings.places),
      (true, true, true),
    );
    expect(find.text('♪ Song 1 · Sezen'), findsOneWidget);
    expect(find.text('Turn on'), findsNothing);
  });

  testWidgets('"No, thanks" hides it for good; Settings can turn it on', (
    tester,
  ) async {
    final c = await pumpApp(
      tester,
      preferences: _english,
      size: const Size(400, 6000),
      overrides: [placesBridgeProvider.overrideWithValue(FakePlacesBridge())],
    );
    final store = c.read(historyStoreProvider);
    final now = DateTime.now();
    for (var d = 1; d <= 3; d++) {
      await store.add(
        testAccount.id,
        PlayEvent(
          track: _song('t$d', 'Song $d'),
          startedAt: now.subtract(Duration(days: d)),
          listened: const Duration(minutes: 3),
        ),
      );
    }
    c.read(historyRevisionProvider.notifier).bump();
    await tester.pumpAndSettle();
    await tester.tap(find.text('No, thanks'));
    await tester.pumpAndSettle();
    expect(find.text('Turn on'), findsNothing);
    expect(find.text('♪ Song 1 · Sezen'), findsNothing);
    expect(c.read(listeningSettingsControllerProvider).places, isFalse);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    final lifeSwitch = find.widgetWithText(
      SwitchListTile,
      'Soundtrack of your life',
    );
    await tester.tap(lifeSwitch);
    await tester.pumpAndSettle();
    var settings = c.read(listeningSettingsControllerProvider);
    expect((settings.lifeShelf, settings.places), (true, true));

    // Off stops both the home cards and place recording.
    await tester.tap(lifeSwitch);
    await tester.pumpAndSettle();
    settings = c.read(listeningSettingsControllerProvider);
    expect((settings.lifeShelf, settings.places), (false, false));
  });

  testWidgets('back at a place: Home shows what was played there, once', (
    tester,
  ) async {
    final places = FakePlacesBridge()..locationAllowed = true;
    final c = await pumpApp(
      tester,
      preferences: {
        ..._english,
        ListeningSettingsController.key: '{"places":true,"lifeAsked":true}',
      },
      overrides: [placesBridgeProvider.overrideWithValue(places)],
    );
    final ago = DateTime.now().subtract(const Duration(days: 10));
    await c
        .read(historyStoreProvider)
        .add(
          testAccount.id,
          PlayEvent(
            track: makeTrack('t1', title: 'Firuze'),
            startedAt: ago,
            listened: const Duration(minutes: 3),
            place: PlayPlace(
              latitude: 40.37767,
              longitude: 49.89201,
              name: 'Sahil, Bakı',
            ),
          ),
        );
    c.invalidate(placeMemoryProvider);
    await tester.pumpAndSettle();
    expect(find.text("📍 You're back: Sahil, Bakı"), findsOneWidget);
    expect(find.textContaining('Firuze by Sezen here'), findsOneWidget);

    await tester.tap(find.text("That day's songs"));
    await tester.pumpAndSettle();
    expect(c.read(playerControllerProvider).current?.id, 't1');
    expect(find.text("📍 You're back: Sahil, Bakı"), findsNothing);

    // Coming back to the app the same week: not again.
    c
      ..read(placeMemoryDismissedProvider.notifier).reset()
      ..invalidate(placeMemoryProvider);
    await tester.pumpAndSettle();
    expect(find.text("📍 You're back: Sahil, Bakı"), findsNothing);
    await c.read(playerControllerProvider.notifier).clear();
    await tester.pumpAndSettle();
  });
}
