import 'package:flutter_test/flutter_test.dart';
import 'package:melody/domain/stats/life_places.dart';
import 'package:melody/domain/stats/play_event.dart';

import '../helpers/fakes.dart';

PlayEvent _at(
  String id,
  DateTime at, {
  double lat = 40.40,
  double lon = 49.87,
  String? name = 'Bakı',
  bool skipped = false,
}) => PlayEvent(
  track: makeTrack(id),
  startedAt: at,
  listened: const Duration(minutes: 3),
  skipped: skipped,
  place: PlayPlace(latitude: lat, longitude: lon, name: name),
);

void main() {
  test('distance between Baku and Ganja is about 290 km', () {
    expect(distanceKm(40.41, 49.87, 40.68, 46.36), closeTo(297, 10));
  });

  test('trips: days far from home in a row, newest first', () {
    final events = [
      for (var d = 1; d <= 10; d++) _at('h$d', DateTime(2026, 3, d, 9)),
      // Gabala, two days.
      _at('g1', DateTime(2026, 3, 11, 12), lat: 41, lon: 47.85, name: 'Qəbələ'),
      _at('g1', DateTime(2026, 3, 12, 12), lat: 41, lon: 47.85, name: 'Qəbələ'),
      _at('g2', DateTime(2026, 3, 12, 13), lat: 41, lon: 47.85, name: 'Qəbələ'),
      // Back home, then Istanbul.
      _at('h1', DateTime(2026, 3, 14, 9)),
      _at(
        'i1',
        DateTime(2026, 4, 2, 9),
        lat: 41.01,
        lon: 28.97,
        name: 'İstanbul',
      ),
    ];
    final trips = findTrips(events);
    expect(trips.map((t) => t.place), ['İstanbul', 'Qəbələ']);
    expect(trips.last.days, 2);
    expect(trips.last.songs.map((s) => s.id), ['g1', 'g2']);
    expect(trips.first.days, 1);
    expect(findTrips(const []), isEmpty);
  });

  test('songs in the order played, skips and repeats left out', () {
    final songs = playedInOrder([
      _at('b', DateTime(2026, 1, 1, 10)),
      _at('a', DateTime(2026, 1, 1, 9)),
      _at('a', DateTime(2026, 1, 1, 9, 5)),
      _at('x', DateTime(2026, 1, 1, 9, 10), skipped: true),
      _at('a', DateTime(2026, 1, 1, 11)),
    ]);
    expect(songs.map((s) => s.id), ['a', 'b', 'a']);
  });
}
