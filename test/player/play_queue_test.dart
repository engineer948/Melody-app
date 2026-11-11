import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:melody/player/play_queue.dart';

import '../helpers/fakes.dart';

void main() {
  final tracks = [for (var i = 0; i < 6; i++) makeTrack('t$i')];
  List<String> ids(PlayQueue q) => [for (final t in q.tracks) t.id];

  test('builds a queue and clamps the start', () {
    final q = PlayQueue.of(tracks, start: 2);
    expect(q.current?.track.id, 't2');
    expect(q.length, 6);
    expect(PlayQueue.of(tracks, start: 99).index, 5);
    expect(PlayQueue.of(const []).current, isNull);
  });

  test('next and previous respect repeat', () {
    var q = PlayQueue.of(tracks, start: 5);
    expect(q.nextIndex, isNull);
    expect(q.withRepeat(QueueRepeat.all).nextIndex, 0);
    expect(q.withRepeat(QueueRepeat.one).nextIndex, 5);
    q = q.jumpTo(0);
    expect(q.previousIndex, isNull);
    expect(q.withRepeat(QueueRepeat.all).previousIndex, 5);
    expect(q.jumpTo(3).previousIndex, 2);
  });

  test('shuffle keeps the current track first and can be undone', () {
    final q = PlayQueue.of(tracks, start: 3, random: Random(1));
    final shuffled = q.withShuffle(enabled: true, random: Random(1));
    expect(shuffled.shuffled, isTrue);
    expect(shuffled.index, 0);
    expect(shuffled.current?.track.id, 't3');
    expect(ids(shuffled).toSet(), ids(q).toSet());

    final moved = shuffled.jumpTo(4);
    final restored = moved.withShuffle(enabled: false);
    expect(ids(restored), ids(q));
    expect(restored.current, moved.current);
    expect(restored.originalOrder, isEmpty);
  });

  test('play next and append, also while shuffled', () {
    final q = PlayQueue.of(tracks.take(3).toList(), start: 1);
    final next = q.playNext([makeTrack('x')]);
    expect(ids(next), ['t0', 't1', 'x', 't2']);
    expect(next.current?.track.id, 't1');
    expect(ids(next.append([makeTrack('y')])).last, 'y');

    final shuffled = PlayQueue.of(
      tracks,
      start: 2,
    ).withShuffle(enabled: true, random: Random(3));
    final withNext = shuffled.playNext([makeTrack('x')]);
    expect(withNext.tracks[1].id, 'x');
    final unshuffled = withNext.withShuffle(enabled: false);
    expect(ids(unshuffled), ['t0', 't1', 't2', 'x', 't3', 't4', 't5']);
    expect(unshuffled.current?.track.id, 't2');
  });

  test('the same track can be queued twice', () {
    final q = PlayQueue.of([makeTrack('a')]).append([makeTrack('a')]);
    expect(q.entries.map((e) => e.uid).toSet(), hasLength(2));
  });

  test('removing entries keeps the current track when possible', () {
    final q = PlayQueue.of(tracks, start: 3);
    expect(q.removeAt(1).current?.track.id, 't3');
    expect(q.removeAt(1).index, 2);
    expect(q.removeAt(4).current?.track.id, 't3');
    expect(q.removeAt(3).current?.track.id, 't4');
    final last = PlayQueue.of(tracks, start: 5).removeAt(5);
    expect(last.current?.track.id, 't4');
    expect(q.removeAt(42), same(q));
    expect(PlayQueue.of([makeTrack('a')]).removeAt(0).isEmpty, isTrue);
  });

  test('moving entries follows the current track', () {
    final q = PlayQueue.of(tracks, start: 2);
    final moved = q.move(2, 5);
    expect(ids(moved), ['t0', 't1', 't3', 't4', 't5', 't2']);
    expect(moved.index, 5);
    expect(q.move(0, 4).index, 1);
    expect(q.move(1, 1), same(q));
    expect(q.move(-1, 2), same(q));
  });

  test('clearing upcoming keeps only the current track', () {
    final q = PlayQueue.of(tracks, start: 4).clearUpcoming();
    expect(ids(q), ['t4']);
    expect(q.index, 0);
  });

  test('survives a JSON round trip, including shuffle', () {
    final q = PlayQueue.of(
      tracks,
      start: 2,
      repeat: QueueRepeat.all,
    ).withShuffle(enabled: true, random: Random(5)).append([makeTrack('z')]);
    final restored = PlayQueue.fromJson(q.toJson());
    expect(restored.entries, q.entries);
    expect(restored.index, q.index);
    expect(restored.shuffled, isTrue);
    expect(restored.originalOrder, q.originalOrder);
    expect(restored.repeat, QueueRepeat.all);
    expect(restored.nextUid, q.nextUid);
    expect(
      ids(restored.withShuffle(enabled: false)),
      ids(q.withShuffle(enabled: false)),
    );
  });
}
