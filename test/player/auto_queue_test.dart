import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/stats/play_event.dart';
import 'package:melody/player/auto_queue.dart';
import 'package:melody/player/listening_settings.dart';
import 'package:melody/player/play_queue.dart';
import 'package:melody/player/player_state.dart';

import '../helpers/fakes.dart';

void main() {
  final now = DateTime(2026, 6, 10, 12);
  late FakeMusicSource source;
  late List<List<Track>> added;
  late List<PlayEvent> history;
  var settings = const ListeningSettings(autoDj: true);

  AutoQueueService service() => AutoQueueService(
    source: () => source,
    settings: () => settings,
    history: (since) async => [
      for (final e in history)
        if (!e.startedAt.isBefore(since)) e,
    ],
    enqueue: (tracks) async => added.add(tracks),
    random: Random(1),
    clock: () => now,
  );

  PlayerState playing(List<Track> tracks, {int at = 0}) =>
      PlayerState(queue: PlayQueue.of(tracks, start: at), playing: true);

  setUp(() {
    source = FakeMusicSource(
      tracks: [for (var i = 0; i < 30; i++) makeTrack('lib$i')],
    );
    added = [];
    history = [];
    settings = const ListeningSettings(autoDj: true);
  });

  test('adds a batch when the queue is about to end', () async {
    await service().onState(playing([makeTrack('q0'), makeTrack('q1')], at: 1));
    expect(added.single, hasLength(AutoQueueService.batch));
  });

  test('does nothing while enough tracks remain', () async {
    await service().onState(
      playing([for (var i = 0; i < 5; i++) makeTrack('q$i')]),
    );
    expect(added, isEmpty);
  });

  test('does nothing when off, paused or repeating', () async {
    final tracks = [makeTrack('q0')];
    settings = const ListeningSettings();
    await service().onState(playing(tracks));
    settings = const ListeningSettings(autoDj: true);
    await service().onState(PlayerState(queue: PlayQueue.of(tracks)));
    await service().onState(
      PlayerState(
        queue: PlayQueue.of(tracks, repeat: QueueRepeat.all),
        playing: true,
      ),
    );
    expect(added, isEmpty);
  });

  test('skips queued and recently played tracks', () async {
    history = [
      PlayEvent(
        track: makeTrack('lib1'),
        startedAt: now.subtract(const Duration(minutes: 20)),
        listened: const Duration(minutes: 3),
      ),
    ];
    await service().onState(playing([makeTrack('lib0')]));
    final ids = added.single.map((t) => t.id);
    expect(ids, isNot(contains('lib0')));
    expect(ids, isNot(contains('lib1')));
  });

  test('asks only once when nothing can be found', () async {
    source.trackItems = [];
    final s = service();
    final state = playing([makeTrack('q0')]);
    await s.onState(state);
    await s.onState(state);
    expect(added, isEmpty);
  });

  test('smart mode picks from the pool without repeats', () async {
    settings = const ListeningSettings(
      autoDj: true,
      autoDjMode: AutoDjMode.smart,
    );
    await service().onState(playing([makeTrack('lib0')]));
    final ids = added.single.map((t) => t.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids, isNot(contains('lib0')));
  });

  test('artist mode falls back to random without an artist', () async {
    settings = const ListeningSettings(
      autoDj: true,
      autoDjMode: AutoDjMode.artist,
    );
    await service().onState(playing([makeTrack('q0')]));
    expect(added.single, isNotEmpty);
  });
}
