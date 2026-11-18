import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/features/playlist/smart_playlists.dart';
import 'package:melody/player/player_controller.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  const en = {LocaleController.localeKey: 'en'};

  Future<void> openCategory(WidgetTester tester, String label) async {
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, label));
    await tester.pumpAndSettle();
  }

  testWidgets('long press picks several songs and queues them', (tester) async {
    final container = await pumpApp(tester, preferences: en);
    await openCategory(tester, 'Songs');

    await tester.longPress(find.text('Firuze'));
    await tester.pumpAndSettle();
    expect(find.text('1 song selected'), findsOneWidget);

    // While picking, a tap picks instead of playing.
    await tester.tap(find.text('Hadi'));
    await tester.pumpAndSettle();
    expect(find.text('2 songs selected'), findsOneWidget);
    expect(container.read(playerControllerProvider).current, isNull);

    await tester.tap(find.text('Select none'));
    await tester.pumpAndSettle();
    expect(find.textContaining('selected'), findsNothing);

    await tester.longPress(find.text('Hadi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    expect(find.text('2 songs selected'), findsOneWidget);

    await tester.tap(find.text('Play').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('selected'), findsNothing);
    final queue = container.read(playerControllerProvider).queue.tracks;
    expect([for (final t in queue) t.id], ['t1', 't2']);
    await container.read(playerControllerProvider.notifier).clear();
    await tester.pumpAndSettle();
  });

  testWidgets('a smart playlist is created, listed and opened', (tester) async {
    final container = await pumpApp(
      tester,
      preferences: en,
      source: FakeMusicSource(
        tracks: [
          makeTrack('t1', title: 'Firuze').copyWith(year: 1991),
          makeTrack('t2', title: 'Hadi').copyWith(year: 2005),
        ],
      ),
    );
    await openCategory(tester, 'Playlists');

    await tester.tap(find.byTooltip('New playlist'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New smart playlist'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '90s');
    await tester.enterText(find.widgetWithText(TextField, 'From year'), '1990');
    await tester.enterText(find.widgetWithText(TextField, 'To year'), '1999');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('90s'), findsWidgets);
    expect(find.text('Firuze'), findsOneWidget);
    expect(find.text('Hadi'), findsNothing);
    final saved = container.read(smartPlaylistsProvider).single;
    expect((saved.name, saved.yearFrom, saved.yearTo), ('90s', 1990, 1999));

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, '90s'), findsOneWidget);
  });

  testWidgets('a playlist can be exported as M3U', (tester) async {
    final source = FakeMusicSource();
    await source.addToPlaylist('p1', ['t1']);
    await pumpApp(tester, preferences: en, source: source);
    await openCategory(tester, 'Playlists');
    await tester.tap(find.text('Yol şarkıları'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More options').first);
    await tester.pumpAndSettle();
    expect(find.text('Export as M3U'), findsOneWidget);
  });
}
