import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/router/app_router.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/features/album/album_screen.dart';
import 'package:melody/features/home/home_screen.dart';
import 'package:melody/features/player/mini_player.dart';
import 'package:melody/features/player/now_playing_screen.dart';
import 'package:melody/features/player/queue_screen.dart';
import 'package:melody/player/play_queue.dart';
import 'package:melody/player/playback_settings.dart';
import 'package:melody/player/player_controller.dart';

import '../../helpers/fake_engine.dart';
import '../../helpers/pump_app.dart';

void main() {
  const prefs = {
    LocaleController.localeKey: 'en',
    PlaybackSettingsController.key: '{"fadeMs":0}',
  };

  /// Stops playback so no report timer outlives the test.
  Future<void> stop(WidgetTester tester, ProviderContainer container) async {
    await container.read(playerControllerProvider.notifier).clear();
    await tester.pumpAndSettle();
  }

  Future<void> playFirstSong(WidgetTester tester) async {
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Songs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Firuze'));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a song plays it and shows the mini player', (
    tester,
  ) async {
    final engine = FakeAudioEngine();
    final container = await pumpApp(
      tester,
      preferences: prefs,
      engine: engine,
      size: const Size(400, 1400),
    );
    expect(find.byType(MiniPlayer), findsOneWidget);
    expect(find.byTooltip('Pause'), findsNothing);

    await playFirstSong(tester);
    expect(container.read(playerControllerProvider).current?.id, 't1');
    expect(engine.loadedIds, ['t1', 't2']);
    expect(find.byTooltip('Pause'), findsOneWidget);

    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    expect(container.read(playerControllerProvider).playing, isFalse);
    expect(find.byTooltip('Play'), findsWidgets);

    await tester.tap(find.byTooltip('Next').first);
    await tester.pumpAndSettle();
    expect(container.read(playerControllerProvider).current?.id, 't2');
    await stop(tester, container);
  });

  testWidgets('the full player opens, controls playback and closes', (
    tester,
  ) async {
    final engine = FakeAudioEngine();
    final container = await pumpApp(
      tester,
      preferences: prefs,
      engine: engine,
      size: const Size(400, 1400),
    );
    await playFirstSong(tester);

    await tester.tap(find.text('Firuze').last);
    await tester.pumpAndSettle();
    expect(find.byType(NowPlayingScreen), findsOneWidget);
    expect(find.text('Firuze'), findsWidgets);

    await tester.tap(find.byTooltip('Repeat off'));
    await tester.pumpAndSettle();
    expect(
      container.read(playerControllerProvider).queue.repeat,
      QueueRepeat.all,
    );

    await tester.tap(find.byTooltip('Shuffle'));
    await tester.pumpAndSettle();
    expect(container.read(playerControllerProvider).queue.shuffled, isTrue);

    await tester.tap(find.text('1.0×'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1.5×'));
    await tester.pumpAndSettle();
    expect(engine.speed, 1.5);

    await tester.tap(find.byTooltip('Sleep timer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End of song'));
    await tester.pumpAndSettle();
    expect(
      container.read(playerControllerProvider).sleepTimer?.endOfTrack,
      isTrue,
    );
    expect(find.byTooltip('Stops after this song'), findsOneWidget);

    await tester.tap(find.byTooltip('Close player'));
    await tester.pumpAndSettle();
    expect(find.byType(NowPlayingScreen), findsNothing);
    await stop(tester, container);
  });

  testWidgets('the queue can be edited', (tester) async {
    final engine = FakeAudioEngine();
    final container = await pumpApp(
      tester,
      preferences: prefs,
      engine: engine,
      size: const Size(400, 1400),
    );
    await playFirstSong(tester);
    await tester.tap(find.text('Firuze').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Queue'));
    await tester.pumpAndSettle();
    expect(find.byType(QueueScreen), findsOneWidget);
    expect(find.text('Hadi'), findsOneWidget);

    await tester.drag(find.text('Hadi'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Removed from queue'), findsOneWidget);
    expect(container.read(playerControllerProvider).queue.length, 1);
    expect(engine.loadedIds, ['t1']);
    await stop(tester, container);
  });

  testWidgets('the track menu queues songs', (tester) async {
    final engine = FakeAudioEngine();
    final container = await pumpApp(
      tester,
      preferences: prefs,
      engine: engine,
      size: const Size(400, 1400),
    );
    await playFirstSong(tester);

    await tester.tap(find.byTooltip('More options').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play next'));
    await tester.pumpAndSettle();
    expect(find.text('Added to queue'), findsOneWidget);
    expect(
      container.read(playerControllerProvider).queue.tracks.map((t) => t.id),
      ['t1', 't2', 't2'],
    );
    await stop(tester, container);
  });

  testWidgets('going to an album from the player keeps the home tab working', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      preferences: prefs,
      engine: FakeAudioEngine(),
      size: const Size(400, 1400),
    );
    await playFirstSong(tester);
    await tester.tap(find.text('Firuze').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More options').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go to album'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(NowPlayingScreen), findsNothing);
    expect(find.byType(AlbumScreen), findsOneWidget);
    expect(
      container.read(appRouterProvider).state.uri.path,
      startsWith('/library/album/'),
    );

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(HomeScreen), findsOneWidget);

    // The album link under the title in the player behaves the same.
    await tester.tap(find.text('Firuze').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Firuze').last);
    await tester.pumpAndSettle();
    expect(find.byType(AlbumScreen), findsOneWidget);
    expect(
      container.read(appRouterProvider).state.uri.path,
      startsWith('/home/album/'),
    );
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // The home tab remembers its album page; a second tap goes to its root.
    expect(find.byType(AlbumScreen), findsOneWidget);
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    await stop(tester, container);
  });

  testWidgets('the player is accessible', (tester) async {
    final handle = tester.ensureSemantics();
    final container = await pumpApp(
      tester,
      preferences: prefs,
      engine: FakeAudioEngine(),
      size: const Size(400, 1400),
    );
    await playFirstSong(tester);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await tester.tap(find.text('Firuze').last);
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
    await stop(tester, container);
  });
}
