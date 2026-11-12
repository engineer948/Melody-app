import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/player/media_browser.dart';
import 'package:melody/player/playback_settings.dart';
import 'package:melody/player/player_controller.dart';

import '../helpers/fake_engine.dart';
import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

void main() {
  late FakeMusicSource source;
  late FakeAudioEngine engine;

  Future<ProviderContainer> setUpBrowser() async {
    source = FakeMusicSource();
    engine = FakeAudioEngine();
    final c = await createContainer(
      source: source,
      engine: engine,
      preferences: {PlaybackSettingsController.key: '{"fadeMs":0}'},
    );
    c.read(playerControllerProvider);
    return c;
  }

  tearDown(pumpEventQueue);

  test('the root lists the visible sections', () async {
    final c = await setUpBrowser();
    final browser = MediaBrowser(c);
    var root = await browser.children(AudioService.browsableRootId);
    expect(root.map((m) => m.id), [
      for (final tab in AutoTab.values) 'tab:${tab.name}',
    ]);
    expect(root.every((m) => m.playable == false), isTrue);

    await c
        .read(autoTabsProvider.notifier)
        .setVisible(AutoTab.genres, visible: false);
    root = await browser.children(AudioService.browsableRootId);
    expect(root.map((m) => m.id), isNot(contains('tab:genres')));
  });

  test(
    'albums open to their songs, which play with their neighbours',
    () async {
      final c = await setUpBrowser();
      final browser = MediaBrowser(c);
      final albums = await browser.children('tab:albums');
      expect(albums.map((m) => m.id), ['album:a1', 'album:a2']);

      final songs = await browser.children('album:a1');
      expect(songs.map((m) => m.id), ['play|album:a1|t1', 'play|album:a1|t2']);
      expect(songs.first.playable, isTrue);

      await browser.play('play|album:a1|t2');
      final state = c.read(playerControllerProvider);
      expect(state.current?.id, 't2');
      expect(state.queue.length, 2);
      expect(state.playing, isTrue);
    },
  );

  test('playlists, artists and the queue can be browsed', () async {
    final c = await setUpBrowser();
    final browser = MediaBrowser(c);
    source.playlistEntries['p1'] = [('e1', makeTrack('t9', title: 'Yol'))];
    expect((await browser.children('tab:playlists')).single.id, 'playlist:p1');
    expect((await browser.children('playlist:p1')).single.title, 'Yol');
    expect(
      (await browser.children('artist:ar1')).map((m) => m.id),
      containsAll(['top:ar1', 'album:a1']),
    );

    await browser.play('play|playlist:p1|t9');
    final queue = await browser.children('tab:queue');
    expect(queue.single.id, 'play|tab:queue|t9');
  });

  test('voice search plays the best match, or anything when empty', () async {
    final c = await setUpBrowser();
    final browser = MediaBrowser(c);
    await browser.playFromSearch('firuze');
    expect(c.read(playerControllerProvider).current?.id, 't1');

    // No matching song: the album is played instead.
    await browser.playFromSearch('deli');
    expect(c.read(playerControllerProvider).queue.length, 2);

    await browser.playFromSearch('');
    expect(c.read(playerControllerProvider).hasQueue, isTrue);
    expect(source.searches, ['firuze', 'deli']);
  });

  test('unknown ids are ignored', () async {
    final c = await setUpBrowser();
    final browser = MediaBrowser(c);
    expect(await browser.children('nonsense'), isEmpty);
    await browser.play('play|album:a1|missing');
    expect(c.read(playerControllerProvider).hasQueue, isFalse);
  });
}
