import 'package:flutter_test/flutter_test.dart';
import 'package:melody/domain/stats/life_days.dart';
import 'package:melody/domain/stats/play_event.dart';

import '../helpers/fakes.dart';

void main() {
  PlayEvent play(String id, DateTime at, {String? place, bool skip = false}) =>
      PlayEvent(
        track: makeTrack(id),
        startedAt: at,
        listened: const Duration(minutes: 3),
        skipped: skip,
        place: place == null
            ? null
            : PlayPlace(latitude: 40, longitude: 49, name: place),
      );

  test('days newest first, with places, songs and first listens', () {
    final days = lifeDays(
      [
        play('t1', DateTime(2026, 5, 1, 9), place: 'Ev'),
        play('t2', DateTime(2026, 5, 1, 10), place: 'Sahil'),
        play('t2', DateTime(2026, 5, 1, 11), place: 'Sahil'),
        play('t3', DateTime(2026, 5, 1, 12), skip: true),
        play('t1', DateTime(2026, 5, 2, 9)),
      ],
      {
        't1': DateTime(2026, 4),
        't2': DateTime(2026, 5, 1, 10),
        't3': DateTime(2026, 5, 1, 12),
      },
    );
    expect(days.map((d) => d.day), [DateTime(2026, 5, 2), DateTime(2026, 5)]);
    final first = days.last;
    expect(first.places, ['Sahil', 'Ev']);
    expect(first.firsts, {'t2', 't3'});
    // First listens before the rest; skipped songs are not listed.
    expect(first.songs.map((s) => (s.$1.id, s.$2)), [('t2', 2), ('t1', 1)]);
    expect(first.listened, const Duration(minutes: 12));
    expect(days.first.places, isEmpty);
  });
}
