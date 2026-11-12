import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/data/downloads/download_models.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/stats/play_event.dart';
import 'package:melody/features/downloads/download_controller.dart';
import 'package:melody/features/stats/stats_providers.dart';
import 'package:melody/player/history_recorder.dart';
import 'package:melody/player/listening_settings.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

const Map<String, Object> _english = {LocaleController.localeKey: 'en'};

Track _song(String id, String title) => Track(
  id: id,
  title: title,
  artists: const [NamedRef(id: 'ar1', name: 'Sezen')],
  albumId: 'a1',
  albumTitle: 'Gülümse',
  duration: const Duration(minutes: 3),
);

/// Records [count] full listens of each given song on consecutive days.
Future<void> _listen(
  ProviderContainer c,
  List<Track> songs, {
  int count = 3,
}) async {
  final store = c.read(historyStoreProvider);
  final now = DateTime.now();
  for (final song in songs) {
    for (var i = 0; i < count; i++) {
      await store.add(
        testAccount.id,
        PlayEvent(
          track: song,
          startedAt: now.subtract(Duration(days: i + 1)),
          listened: const Duration(minutes: 3),
        ),
      );
    }
  }
  c.read(historyRevisionProvider.notifier).bump();
  c.invalidate(suggestionsProvider);
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('statistics start empty and fill up from the history', (
    tester,
  ) async {
    final c = await pumpApp(
      tester,
      preferences: _english,
      size: const Size(400, 6000),
    );
    await _openSettings(tester);
    await tester.tap(find.text('Listening statistics'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing to show yet'), findsOneWidget);

    await _listen(c, [_song('t1', 'Firuze'), _song('t2', 'Hadi')]);
    await tester.pumpAndSettle();
    expect(find.text('Top artists'), findsOneWidget);
    expect(find.text('Sezen'), findsOneWidget);
    expect(find.text('Firuze'), findsOneWidget);
    // 2 songs x 3 listens x 3 minutes.
    expect(find.text('18 minutes'), findsWidgets);
    expect(find.text('Gülümse'), findsOneWidget);
  });

  testWidgets('the year in review flips through its cards', (tester) async {
    final c = await pumpApp(
      tester,
      preferences: _english,
      size: const Size(400, 6000),
    );
    await _listen(c, [_song('t1', 'Firuze')]);
    await _openSettings(tester);
    await tester.tap(find.text('Listening statistics'));
    await tester.pumpAndSettle();
    final year = DateTime.now().year;
    await tester.tap(find.text('Your $year in review'));
    await tester.pumpAndSettle();
    expect(find.text('$year in review'), findsOneWidget);

    await tester.tapAt(const Offset(380, 400));
    await tester.pumpAndSettle();
    expect(find.text('YOU LISTENED FOR'), findsOneWidget);

    await tester.tapAt(const Offset(380, 400));
    await tester.pumpAndSettle();
    expect(find.text('YOUR TOP ARTIST'), findsOneWidget);
    expect(find.text('Sezen'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Your $year in review'), findsOneWidget);
  });

  testWidgets('home suggests a mix once there is some history', (tester) async {
    final c = await pumpApp(
      tester,
      preferences: _english,
      size: const Size(400, 3000),
    );
    expect(find.text('Mix for you'), findsNothing);

    await _listen(c, [_song('old1', 'Eski')]);
    await tester.pumpAndSettle();
    expect(find.text('Mix for you'), findsOneWidget);

    // Turning suggestions off hides them again.
    await c
        .read(listeningSettingsControllerProvider.notifier)
        .update((s) => s.copyWith(suggestions: false));
    await tester.pumpAndSettle();
    expect(find.text('Mix for you'), findsNothing);
  });

  testWidgets('the downloads page lists what is saved', (tester) async {
    final c = await pumpApp(tester, preferences: _english);
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Downloaded'));
    await tester.pumpAndSettle();
    expect(find.text('No downloads yet'), findsOneWidget);

    await tester.runAsync(() async {
      final downloads = c.read(downloadControllerProvider.notifier);
      await downloads.enqueue([_song('t1', 'Firuze')]);
      for (var i = 0; i < 200; i++) {
        if (c.read(downloadControllerProvider)['t1']?.status ==
            DownloadStatus.done) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });
    await tester.pumpAndSettle();
    expect(find.text('Firuze'), findsOneWidget);
    expect(find.textContaining('1 song'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove all downloads'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(find.text('No downloads yet'), findsOneWidget);
  });

  testWidgets('Auto DJ options appear when it is switched on', (tester) async {
    final c = await pumpApp(
      tester,
      preferences: _english,
      size: const Size(400, 6000),
    );
    await _openSettings(tester);
    expect(find.text('Auto DJ picks'), findsNothing);
    await tester.tap(find.text('Auto DJ'));
    await tester.pumpAndSettle();
    expect(find.text('Auto DJ picks'), findsOneWidget);
    expect(c.read(listeningSettingsControllerProvider).autoDj, isTrue);
  });
}
