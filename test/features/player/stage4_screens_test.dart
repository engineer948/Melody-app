import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/data/sources/lrclib/lrclib_client.dart';
import 'package:melody/domain/lyrics/lrc_parser.dart';
import 'package:melody/features/lyrics/lyrics_providers.dart';
import 'package:melody/features/playlist/playlist_screen.dart';
import 'package:melody/player/playback_settings.dart';
import 'package:melody/player/player_controller.dart';
import 'package:melody/player/streaming_settings.dart';

import '../../helpers/fake_engine.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  const prefs = {
    LocaleController.localeKey: 'en',
    PlaybackSettingsController.key: '{"fadeMs":0}',
  };

  Future<ProviderContainer> start(
    WidgetTester tester, {
    FakeMusicSource? source,
    FakeAudioEngine? engine,
    Map<String, Object> preferences = prefs,
    List<Override> overrides = const [],
  }) => pumpApp(
    tester,
    preferences: preferences,
    source: source,
    engine: engine ?? FakeAudioEngine(),
    overrides: overrides,
    size: const Size(400, 1400),
  );

  Future<void> openSongs(WidgetTester tester) async {
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Songs'));
    await tester.pumpAndSettle();
  }

  Future<void> playAndOpenPlayer(WidgetTester tester) async {
    await openSongs(tester);
    await tester.tap(find.text('Firuze'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Firuze').last);
    await tester.pumpAndSettle();
  }

  Future<void> stop(WidgetTester tester, ProviderContainer c) async {
    await c.read(playerControllerProvider.notifier).clear();
    await tester.pumpAndSettle();
  }

  testWidgets('synced lyrics follow the song and lines can be tapped', (
    tester,
  ) async {
    final source = FakeMusicSource()
      ..lyricsByTrack['t1'] = parseLrc('[00:00.00]Birinci\n[00:05.00]İkinci');
    final engine = FakeAudioEngine();
    final c = await start(tester, source: source, engine: engine);
    await playAndOpenPlayer(tester);

    await tester.tap(find.byTooltip('Lyrics'));
    await tester.pumpAndSettle();
    expect(find.text('Birinci'), findsOneWidget);
    expect(find.text('İkinci'), findsOneWidget);

    await tester.tap(find.text('İkinci'));
    await tester.pumpAndSettle();
    expect(engine.log, contains('seek 5'));

    await tester.tap(find.byTooltip('Show later'));
    await tester.pumpAndSettle();
    expect(
      c.read(lyricsSettingsControllerProvider).offsetOf('t1'),
      const Duration(milliseconds: 500),
    );
    expect(find.text('Timing: +0.5 s'), findsOneWidget);
    await stop(tester, c);
  });

  testWidgets('LRCLIB is asked only when allowed', (tester) async {
    final adapter = FakeHttpAdapter(
      (_) => (status: 200, body: {'syncedLyrics': '[00:01.00]Uzaktan'}),
    );
    final c = await start(
      tester,
      overrides: [
        lrclibProvider.overrideWithValue(LrclibClient(adapter: adapter)),
      ],
    );
    await playAndOpenPlayer(tester);
    await tester.tap(find.byTooltip('Lyrics'));
    await tester.pumpAndSettle();
    expect(find.text('No lyrics for this song'), findsOneWidget);
    expect(adapter.requests, isEmpty);

    await c
        .read(lyricsSettingsControllerProvider.notifier)
        .update((s) => s.copyWith(useLrclib: true));
    await tester.pumpAndSettle();
    expect(find.text('Uzaktan'), findsOneWidget);
    expect(find.text('Lyrics from LRCLIB'), findsOneWidget);
    await stop(tester, c);
  });

  testWidgets('the heart marks the playing song as favourite', (tester) async {
    final source = FakeMusicSource();
    final c = await start(tester, source: source);
    await playAndOpenPlayer(tester);

    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();
    expect(source.favoriteCalls, [('t1', true)]);
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    expect(c.read(playerControllerProvider).current?.isFavorite, isTrue);
    await stop(tester, c);
  });

  testWidgets('a song can be added to a new playlist', (tester) async {
    final source = FakeMusicSource();
    await start(tester, source: source);
    await openSongs(tester);

    await tester.tap(find.byTooltip('More options').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to playlist'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New playlist'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Gece');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Added to Gece'), findsOneWidget);
    expect(source.playlistNames.values, contains('Gece'));
    final id = source.playlistNames.entries
        .firstWhere((e) => e.value == 'Gece')
        .key;
    expect(source.playlistEntries[id]!.single.$2.id, 't1');
  });

  testWidgets('playlists can be renamed, trimmed and deleted', (tester) async {
    final source = FakeMusicSource();
    await source.addToPlaylist('p1', ['t1', 't2']);
    await start(tester, source: source);
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Playlists'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yol şarkıları'));
    await tester.pumpAndSettle();
    expect(find.byType(MosaicCover), findsOneWidget);

    await tester.tap(find.byTooltip('More options').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Yolculuk');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(source.playlistNames['p1'], 'Yolculuk');
    expect(find.text('Yolculuk'), findsWidgets);

    await tester.tap(find.byTooltip('More options').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remove from playlist').first);
    await tester.pumpAndSettle();
    expect(source.playlistEntries['p1']!.map((e) => e.$2.id), ['t2']);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(PlaylistScreen), findsOneWidget);

    await tester.tap(find.byTooltip('More options').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete playlist'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(source.playlistNames.containsKey('p1'), isFalse);
    expect(find.byType(PlaylistScreen), findsNothing);
  });

  testWidgets('the queue can be saved as a playlist', (tester) async {
    final source = FakeMusicSource();
    final c = await start(tester, source: source);
    await playAndOpenPlayer(tester);
    await tester.tap(find.byTooltip('Queue'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Save as playlist'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Sıram');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    final id = source.playlistNames.entries
        .firstWhere((e) => e.value == 'Sıram')
        .key;
    expect(source.playlistEntries[id]!.map((e) => e.$2.id), ['t1', 't2']);
    await stop(tester, c);
  });

  testWidgets('streaming and lyrics settings are saved', (tester) async {
    final c = await start(tester);
    tester.view.physicalSize = const Size(400, 6000);
    await tester.tap(find.byTooltip('Settings').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Original').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('128 kbps').last);
    await tester.pumpAndSettle();
    expect(c.read(streamingSettingsControllerProvider).wifiBitrate, 128);

    await tester.tap(find.text('Search LRCLIB'));
    await tester.pumpAndSettle();
    expect(c.read(lyricsSettingsControllerProvider).useLrclib, isTrue);
  });
}
