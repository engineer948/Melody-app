import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/player/play_queue.dart';
import 'package:melody/player/playback_reporter.dart';
import 'package:melody/player/playback_settings.dart';
import 'package:melody/player/player_controller.dart';
import 'package:melody/player/queue_store.dart';
import 'package:melody/player/streaming_settings.dart';

import '../helpers/fake_engine.dart';
import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

void main() {
  final tracks = [for (var i = 0; i < 4; i++) makeTrack('t$i')];
  late FakeAudioEngine engine;
  late FakeMusicSource source;

  Future<ProviderContainer> setUpPlayer({
    Map<String, Object> preferences = const {},
  }) async {
    engine = FakeAudioEngine();
    source = FakeMusicSource();
    final container = await createContainer(
      engine: engine,
      source: source,
      preferences: {
        ...preferences,
        PlaybackSettingsController.key: '{"fadeMs":0}',
      },
    );
    container.read(playerControllerProvider);
    return container;
  }

  /// Start and stop reports, ignoring periodic progress.
  List<(PlaybackEventKind, String)> lifecycle() => [
    for (final r in source.reports)
      if (r.kind != PlaybackEventKind.progress) (r.kind, r.trackId),
  ];

  tearDown(pumpEventQueue);

  PlayerController player(ProviderContainer c) =>
      c.read(playerControllerProvider.notifier);

  test('plays a list from the tapped track', () async {
    final c = await setUpPlayer();
    await player(c).playTracks(tracks, start: 2);

    final state = c.read(playerControllerProvider);
    expect(state.current?.id, 't2');
    expect(state.playing, isTrue);
    expect(engine.loadedIds, ['t0', 't1', 't2', 't3']);
    expect(engine.log, containsAllInOrder(['load 2', 'play']));
    expect(lifecycle(), [(PlaybackEventKind.start, 't2')]);
  });

  test('follows the engine when a track ends', () async {
    final c = await setUpPlayer();
    await player(c).playTracks(tracks);
    engine.advanceTo(1);
    await pumpEventQueue();

    expect(c.read(playerControllerProvider).current?.id, 't1');
    expect(lifecycle(), [
      (PlaybackEventKind.start, 't0'),
      (PlaybackEventKind.stopped, 't0'),
      (PlaybackEventKind.start, 't1'),
    ]);
    final sessions = [
      for (final r in source.reports)
        if (r.kind != PlaybackEventKind.progress) r.sessionId,
    ];
    expect(sessions[1], sessions[0]);
    expect(sessions[2], isNot(sessions[0]));
  });

  test('next, previous and restart near the start', () async {
    final c = await setUpPlayer();
    await player(c).playTracks(tracks, start: 1);
    await player(c).next();
    expect(c.read(playerControllerProvider).current?.id, 't2');

    engine.position = const Duration(seconds: 10);
    await player(c).previous();
    expect(c.read(playerControllerProvider).current?.id, 't2');
    expect(engine.log.last, 'seek 0');

    engine.position = Duration.zero;
    await player(c).previous();
    expect(c.read(playerControllerProvider).current?.id, 't1');

    await player(c).skipTo(3);
    await player(c).next();
    expect(c.read(playerControllerProvider).current?.id, 't3');
    await player(c).cycleRepeat();
    await player(c).next();
    expect(c.read(playerControllerProvider).current?.id, 't0');
  });

  test('queue edits are mirrored on the engine', () async {
    final c = await setUpPlayer();
    await player(c).playTracks(tracks.take(2).toList());
    await player(c).playNext([makeTrack('x')]);
    await player(c).addToQueue([makeTrack('y')]);
    expect(engine.loadedIds, ['t0', 'x', 't1', 'y']);
    expect(engine.log, containsAll(['insert 1 1', 'insert 3 1']));

    await player(c).move(3, 1);
    expect(engine.loadedIds, ['t0', 'y', 'x', 't1']);
    await player(c).removeAt(2);
    expect(engine.loadedIds, ['t0', 'y', 't1']);
    expect(
      c.read(playerControllerProvider).queue.tracks.map((t) => t.id),
      engine.loadedIds,
    );

    await player(c).clearUpcoming();
    expect(engine.loadedIds, ['t0']);
  });

  test('adding to an empty queue starts playback', () async {
    final c = await setUpPlayer();
    await player(c).addToQueue([makeTrack('solo')]);
    expect(c.read(playerControllerProvider).current?.id, 'solo');
    expect(engine.log, contains('play'));
  });

  test('shuffle and repeat', () async {
    final c = await setUpPlayer();
    await player(c).playTracks(tracks, start: 2);
    await player(c).toggleShuffle();
    var state = c.read(playerControllerProvider);
    expect(state.queue.shuffled, isTrue);
    expect(state.current?.id, 't2');
    expect(engine.loadedIds.first, 't2');
    await player(c).toggleShuffle();
    expect(engine.loadedIds, ['t0', 't1', 't2', 't3']);

    await player(c).cycleRepeat();
    expect(engine.repeat, QueueRepeat.all);
    await player(c).cycleRepeat();
    await player(c).cycleRepeat();
    state = c.read(playerControllerProvider);
    expect(state.queue.repeat, QueueRepeat.off);
    expect(engine.repeat, QueueRepeat.off);
  });

  test('speed is clamped', () async {
    final c = await setUpPlayer();
    await player(c).setSpeed(3);
    expect(engine.speed, 2);
    expect(c.read(playerControllerProvider).speed, 2);
  });

  test('ReplayGain lowers the volume for loud tracks', () async {
    final c = await setUpPlayer();
    final loud = makeTrack('loud').copyWith(trackGainDb: -6);
    await player(c).playTracks([loud]);
    expect(engine.volume, closeTo(0.501, 0.001));

    await c
        .read(playbackSettingsControllerProvider.notifier)
        .update((s) => s.copyWith(replayGain: ReplayGainMode.off));
    await pumpEventQueue();
    expect(engine.volume, 1);
  });

  test('sleep timer at the end of the song pauses on the next track', () async {
    final c = await setUpPlayer();
    await player(c).playTracks(tracks);
    player(c).setSleepTimer(null);
    expect(c.read(playerControllerProvider).sleepTimer?.endOfTrack, isTrue);

    engine.advanceTo(1);
    await pumpEventQueue();
    final state = c.read(playerControllerProvider);
    expect(state.sleepTimer, isNull);
    expect(state.playing, isFalse);
    expect(engine.log, contains('pause'));
  });

  test('timed sleep timer fades out and pauses', () async {
    final c = await setUpPlayer();
    await player(c).playTracks(tracks);
    player(c).setSleepTimer(const Duration(milliseconds: 300));
    expect(c.read(playerControllerProvider).sleepTimer?.endsAt, isNotNull);

    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(engine.volume, lessThan(1));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final state = c.read(playerControllerProvider);
    expect(state.sleepTimer, isNull);
    expect(state.playing, isFalse);
    expect(engine.volume, 1);
  });

  test('the queue is saved and restored after a restart', () async {
    var c = await setUpPlayer();
    await player(c).playTracks(tracks, start: 1);
    engine.position = const Duration(seconds: 42);
    await player(c).pause();
    final saved = QueueStore(c.read(preferencesProvider)).load();
    expect(saved?.queue.current?.track.id, 't1');
    expect(saved?.position, const Duration(seconds: 42));

    final prefsSnapshot = {
      QueueStore.key: c.read(preferencesProvider).getString(QueueStore.key)!,
    };
    c = await setUpPlayer(preferences: prefsSnapshot);
    final restored = c.read(playerControllerProvider);
    expect(restored.current?.id, 't1');
    expect(restored.playing, isFalse);
    await pumpEventQueue();
    expect(engine.log.first, 'load 1');
    expect(engine.position, const Duration(seconds: 42));
  });

  test('a queue from another account is not restored', () async {
    var c = await setUpPlayer();
    await player(c).playTracks(tracks);
    final raw = c.read(preferencesProvider).getString(QueueStore.key)!;
    c = await setUpPlayer(
      preferences: {
        QueueStore.key: raw.replaceAll(testAccount.id, 'someone-else'),
      },
    );
    expect(c.read(playerControllerProvider).hasQueue, isFalse);
  });

  test('switching accounts stops playback', () async {
    final c = await setUpPlayer();
    await player(c).playTracks(tracks);
    await c
        .read(sessionControllerProvider.notifier)
        .signedIn(
          AuthSession(
            account: testAccount.copyWith(id: 'jellyfin:srv1:u2'),
            accessToken: 'other',
          ),
        );
    await pumpEventQueue();
    expect(c.read(playerControllerProvider).hasQueue, isFalse);
    expect(engine.log, contains('stop'));
  });

  test('reports made offline are sent later', () async {
    final c = await setUpPlayer();
    source.failure = const NetworkFailure();
    await player(c).playTracks(tracks);
    final reporter = PlaybackReporter(
      source: () => source,
      prefs: c.read(preferencesProvider),
    );
    expect(reporter.pending, isNotEmpty);

    source.failure = null;
    await player(c).next();
    await pumpEventQueue();
    expect(reporter.pending, isEmpty);
    expect(
      lifecycle(),
      containsAllInOrder([
        (PlaybackEventKind.start, 't0'),
        (PlaybackEventKind.stopped, 't0'),
        (PlaybackEventKind.start, 't1'),
      ]),
    );
  });

  test('streaming quality changes reload the upcoming tracks only', () async {
    final c = await setUpPlayer();
    await player(c).playTracks(tracks, start: 1);
    expect(engine.sources.every((s) => s.cacheKey != null), isTrue);

    await c
        .read(streamingSettingsControllerProvider.notifier)
        .update((s) => s.copyWith(wifiBitrate: 128));
    await pumpEventQueue();
    expect(engine.loadedUris[1], isNot(contains('kbps')));
    expect(engine.loadedUris[2], contains('kbps=128'));
    expect(engine.loadedUris[3], contains('kbps=128'));
    expect(engine.sources[2].cacheKey, isNull);
    expect(engine.loadedIds, ['t0', 't1', 't2', 't3']);
  });

  test('crossfade and favourites reach the engine and the queue', () async {
    final c = await setUpPlayer();
    await player(c).playTracks(tracks);
    await c
        .read(playbackSettingsControllerProvider.notifier)
        .update((s) => s.copyWith(crossfadeSeconds: 6));
    await pumpEventQueue();
    expect(engine.crossfade, const Duration(seconds: 6));

    player(c).updateTrack(tracks[0].copyWith(isFavorite: true));
    expect(c.read(playerControllerProvider).current?.isFavorite, isTrue);
  });
}
