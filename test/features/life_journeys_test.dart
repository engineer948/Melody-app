import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/domain/stats/play_event.dart';
import 'package:melody/features/stats/life_journeys.dart';
import 'package:melody/player/history_recorder.dart';
import 'package:melody/player/listening_settings.dart';
import 'package:melody/player/player_controller.dart';

import '../helpers/fake_places.dart';
import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

const Map<String, Object> _english = {LocaleController.localeKey: 'en'};

void main() {
  testWidgets('a day card on Home plays that day again, in order', (
    tester,
  ) async {
    final c = await pumpApp(
      tester,
      preferences: {
        ..._english,
        ListeningSettingsController.key:
            '{"lifeShelf":true,"lifeAsked":true,"places":true}',
      },
      size: const Size(400, 2000),
      overrides: [
        placesBridgeProvider.overrideWithValue(
          FakePlacesBridge()..locationAllowed = true,
        ),
      ],
    );
    final store = c.read(historyStoreProvider);
    final day = DateTime.now().subtract(const Duration(days: 2));
    Future<void> listen(String id, String title, int hour) => store.add(
      testAccount.id,
      PlayEvent(
        track: makeTrack(id, title: title),
        startedAt: DateTime(day.year, day.month, day.day, hour),
        listened: const Duration(minutes: 3),
        place: PlayPlace(latitude: 40.4, longitude: 49.9, name: 'Bakı'),
      ),
    );
    await listen('t2', 'Morning song', 8);
    await listen('t1', 'Evening song', 20);
    await listen('t1', 'Evening song', 21);
    c.read(historyRevisionProvider.notifier).bump();
    await tester.pumpAndSettle();

    await tester.tap(find.text('📍 Bakı'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final queue = c.read(playerControllerProvider).queue;
    expect(queue.entries.map((e) => e.track.title), [
      'Morning song',
      'Evening song',
    ]);
    expect(find.byType(ReplayScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Morning song'), findsWidgets);

    await tester.tap(
      find.descendant(
        of: find.byType(ReplayScreen),
        matching: find.byTooltip('Close'),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(ReplayScreen), findsNothing);
    await c.read(playerControllerProvider.notifier).clear();
  });
}
