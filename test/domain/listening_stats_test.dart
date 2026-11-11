import 'package:flutter_test/flutter_test.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/stats/listening_stats.dart';
import 'package:melody/domain/stats/play_event.dart';

Track _track(String id, {String artist = 'Sezen', String album = 'a1'}) =>
    Track(
      id: id,
      title: 'Track $id',
      artists: [NamedRef(id: 'ar-$artist', name: artist)],
      albumId: album,
      albumTitle: 'Album $album',
      duration: const Duration(minutes: 3),
      genres: const ['Pop'],
    );

PlayEvent _play(
  Track track,
  DateTime at, {
  int minutes = 3,
  bool skipped = false,
}) => PlayEvent(
  track: track,
  startedAt: at,
  listened: Duration(minutes: minutes),
  skipped: skipped,
);

void main() {
  final now = DateTime(2026, 6, 10, 12);

  test('is empty without events', () {
    final stats = ListeningStats.of(const [], now: now);
    expect(stats.isEmpty, isTrue);
    expect(stats.busiestHour, isNull);
  });

  test('totals, rankings and busiest times', () {
    final a = _track('t1');
    final b = _track('t2', artist: 'Tarkan', album: 'a2');
    final stats = ListeningStats.of([
      _play(a, DateTime(2026, 6, 8, 9)),
      _play(a, DateTime(2026, 6, 9, 9)),
      _play(b, DateTime(2026, 6, 9, 21), minutes: 1, skipped: true),
      _play(a, DateTime(2026, 6, 10, 9)),
    ], now: now);

    expect(stats.plays, 3);
    expect(stats.listened, const Duration(minutes: 10));
    expect(stats.topTracks.first.item.id, 't1');
    expect(stats.topTracks.first.plays, 3);
    expect(stats.topArtists.map((a) => a.item.name), ['Sezen', 'Tarkan']);
    expect(stats.topAlbums.first.item.id, 'a1');
    expect(stats.topGenres.single.item, 'Pop');
    expect(stats.busiestHour, 9);
    expect(stats.busiestDay, DateTime(2026, 6, 9));
    expect(stats.busiestWeekday, DateTime(2026, 6, 9).weekday);
    expect(stats.activeDays, 3);
  });

  test('streaks count consecutive days', () {
    final t = _track('t1');
    final stats = ListeningStats.of([
      for (final day in [1, 2, 3, 4, 8, 9])
        _play(t, DateTime(2026, 6, day, 10)),
    ], now: now);
    expect(stats.longestStreak, 4);
    // Nothing today (the 10th), but yesterday still counts.
    expect(stats.currentStreak, 2);
  });

  test('the current streak ends after a missed day', () {
    final stats = ListeningStats.of([
      _play(_track('t1'), DateTime(2026, 6, 7, 10)),
    ], now: now);
    expect(stats.currentStreak, 0);
    expect(stats.longestStreak, 1);
  });

  test('skip rule: under half of the track and under four minutes', () {
    const three = Duration(minutes: 3);
    expect(PlayEvent.isSkip(const Duration(seconds: 80), three), isTrue);
    expect(PlayEvent.isSkip(const Duration(seconds: 100), three), isFalse);
    expect(
      PlayEvent.isSkip(const Duration(minutes: 5), const Duration(hours: 1)),
      isFalse,
    );
    expect(PlayEvent.isSkip(const Duration(seconds: 10), null), isTrue);
  });
}
