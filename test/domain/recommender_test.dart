import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/recommendation/recommender.dart';
import 'package:melody/domain/stats/play_event.dart';

Track _track(String id, {String artist = 'Sezen', bool favorite = false}) =>
    Track(
      id: id,
      title: 'Track $id',
      artists: [NamedRef(id: 'ar-$artist', name: artist)],
      duration: const Duration(minutes: 3),
      isFavorite: favorite,
    );

PlayEvent _play(Track track, DateTime at, {bool skipped = false}) => PlayEvent(
  track: track,
  startedAt: at,
  listened: Duration(seconds: skipped ? 10 : 180),
  skipped: skipped,
);

void main() {
  final now = DateTime(2026, 6, 10, 20);
  DateTime daysAgo(int days) => now.subtract(Duration(days: days));

  test('full listens raise the score, skips lower it', () {
    final liked = _track('liked');
    final skipped = _track('skipped', artist: 'Other');
    final r = Recommender([
      _play(liked, daysAgo(1)),
      _play(liked, daysAgo(2)),
      _play(skipped, daysAgo(1), skipped: true),
    ], now: now);
    expect(r.score(liked), greaterThan(1));
    expect(r.score(skipped), lessThan(0));
  });

  test('old plays count less than recent ones', () {
    final recent = _track('recent', artist: 'A');
    final old = _track('old', artist: 'B');
    final r = Recommender([
      _play(recent, daysAgo(1)),
      _play(old, daysAgo(200)),
    ], now: now);
    expect(r.score(recent), greaterThan(r.score(old)));
  });

  test('an unknown track of a liked artist beats a stranger', () {
    final r = Recommender([
      for (var i = 0; i < 5; i++) _play(_track('s$i'), daysAgo(i + 1)),
    ], now: now);
    expect(
      r.score(_track('new')),
      greaterThan(r.score(_track('x', artist: 'Stranger'))),
    );
  });

  test('mix leaves out just played, excluded and mostly skipped tracks', () {
    final justPlayed = _track('just');
    final disliked = _track('bad', artist: 'Bad');
    final r = Recommender([
      _play(justPlayed, now.subtract(const Duration(minutes: 30))),
      _play(disliked, daysAgo(1), skipped: true),
      _play(disliked, daysAgo(2), skipped: true),
    ], now: now);
    final mix = r.mix(
      [justPlayed, disliked, _track('a'), _track('b'), _track('c')],
      exclude: {'c'},
      random: Random(1),
    );
    expect(mix.map((t) => t.id).toSet(), {'a', 'b'});
  });

  test('mix returns at most count tracks without duplicates', () {
    final r = Recommender([_play(_track('t0'), daysAgo(5))], now: now);
    final pool = [
      for (var i = 0; i < 50; i++) _track('t$i', artist: 'A${i % 7}'),
      _track('t1'),
    ];
    final mix = r.mix(pool, count: 20, random: Random(3));
    expect(mix, hasLength(20));
    expect(mix.map((t) => t.id).toSet(), hasLength(20));
  });

  test('forgotten favourites were liked but not played lately', () {
    final oldLove = _track('old');
    final current = _track('current');
    final r = Recommender([
      for (var i = 0; i < 3; i++) _play(oldLove, daysAgo(100 + i)),
      for (var i = 0; i < 3; i++) _play(current, daysAgo(i + 1)),
    ], now: now);
    final result = r.forgotten([_track('fav', favorite: true), current]);
    expect(result.map((t) => t.id), unorderedEquals(['old', 'fav']));
  });

  test('discover only offers tracks never played', () {
    final played = _track('played');
    final r = Recommender([_play(played, daysAgo(3))], now: now);
    final result = r.discover([
      played,
      _track('fresh'),
      _track('server-played').copyWith(playCount: 2),
    ], random: Random(1));
    expect(result.map((t) => t.id), ['fresh']);
  });
}
