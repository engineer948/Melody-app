import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/data/db/app_database.dart';
import 'package:melody/data/history/song_notes_store.dart';
import 'package:melody/domain/stats/play_event.dart';
import 'package:melody/features/stats/life_cards.dart';
import 'package:melody/features/stats/song_notes.dart';
import 'package:melody/player/history_recorder.dart';
import 'package:melody/player/listening_settings.dart';

import '../helpers/fake_places.dart';
import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

const Map<String, Object> _english = {LocaleController.localeKey: 'en'};

void main() {
  test(
    'memories: saved per song, empty ones removed, people counted',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final store = SongNotesStore(db);
      SongNote note(String id, String body, [String? person]) => SongNote(
        track: makeTrack(id),
        body: body,
        person: person,
        updatedAt: DateTime(2026, 1, int.parse(id.substring(1))),
      );
      await store.put('acc1', note('t1', ' First dance ', 'Leyla'));
      await store.put('acc1', note('t2', 'Road trip', ' leyla '));
      await store.put('acc1', note('t3', 'Exams', ''));
      await store.put('acc2', note('t9', 'Other account'));

      final all = await store.all('acc1');
      expect(all.map((n) => n.track.id), ['t3', 't2', 't1']);
      expect(all.last.body, 'First dance');
      expect(all.first.person, isNull);
      expect(notePeople(all), [('leyla', 2)]);

      await store.put('acc1', note('t1', 'Wedding', 'Leyla'));
      expect((await store.get('acc1', 't1'))!.body, 'Wedding');
      await store.put('acc1', note('t1', '  '));
      expect(await store.get('acc1', 't1'), isNull);
    },
  );

  testWidgets('write a memory: shown in the story and on the player line', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('melody_memories');
    addTearDown(() => dir.deleteSync(recursive: true));
    final c = await pumpApp(
      tester,
      preferences: _english,
      size: const Size(400, 1600),
      overrides: [
        placesBridgeProvider.overrideWithValue(FakePlacesBridge()),
        memoriesDirProvider.overrideWith((ref) async => dir),
      ],
    );
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
    await tester.tap(find.text('Write a memory'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'What does this song remind you of?'),
      'Our first dance',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Who is it about? (optional)'),
      'Leyla',
    );
    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Our first dance'), findsOneWidget);
    expect(find.text('♥ Leyla'), findsOneWidget);
    final notes = await c.read(songNotesProvider.future);
    expect(notes.single.person, 'Leyla');
  });

  testWidgets('home: forgotten loves and teen years cards', (tester) async {
    final c = await pumpApp(
      tester,
      preferences: {
        ..._english,
        ListeningSettingsController.key: '{"lifeShelf":true,"lifeAsked":true}',
      },
      size: const Size(400, 2000),
      overrides: [placesBridgeProvider.overrideWithValue(FakePlacesBridge())],
    );
    final store = c.read(historyStoreProvider);
    final now = DateTime.now();
    for (var i = 0; i < 8; i++) {
      await store.add(
        testAccount.id,
        PlayEvent(
          track: makeTrack('t1', title: 'Old love'),
          startedAt: now.subtract(Duration(days: 400 + i)),
          listened: const Duration(minutes: 3),
        ),
      );
    }
    await store.add(
      testAccount.id,
      PlayEvent(
        track: makeTrack('t2', title: 'Yesterday'),
        startedAt: now.subtract(const Duration(days: 1)),
        listened: const Duration(minutes: 3),
      ),
    );
    c.read(historyRevisionProvider.notifier).bump();
    await tester.pumpAndSettle();

    expect(find.text('Forgotten loves'), findsOneWidget);
    expect(find.text('A song you once loved'), findsOneWidget);

    // The last card of the shelf.
    await tester.scrollUntilVisible(
      find.text('Your teen years'),
      200,
      scrollable: find
          .ancestor(
            of: find.text('Forgotten loves'),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tap and enter your birth year'));
    await tester.pumpAndSettle();
    expect(find.text('Which year were you born?'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(EditableText),
      ),
      '1995',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(c.read(birthYearProvider), 1995);
    expect(find.text('Songs from 2008–2017'), findsOneWidget);
  });
}
