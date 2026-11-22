import 'package:flutter_test/flutter_test.dart';
import 'package:melody/domain/stats/place_memory.dart';
import 'package:melody/domain/stats/play_event.dart';

import '../helpers/fakes.dart';

void main() {
  final now = DateTime(2026, 11, 22, 18);
  PlayEvent play(
    String id,
    DateTime at, {
    double lat = 40.38,
    double lon = 49.89,
    bool skip = false,
  }) => PlayEvent(
    track: makeTrack(id),
    startedAt: at,
    listened: const Duration(minutes: 3),
    skipped: skip,
    place: PlayPlace(latitude: lat, longitude: lon, name: 'Sahil'),
  );

  test('back after a while: the last day here and its songs', () {
    final memory = findPlaceMemory(
      [
        play('old', DateTime(2026, 3)),
        play('t1', DateTime(2026, 6, 12, 20)),
        play('t2', DateTime(2026, 6, 12, 21)),
        play('t2', DateTime(2026, 6, 12, 22)),
        play('t3', DateTime(2026, 6, 12, 23), skip: true),
        play('far', DateTime(2026, 11), lat: 41, lon: 29),
      ],
      latitude: 40.3812,
      longitude: 49.8934,
      now: now,
    )!;
    expect(memory.day, DateTime(2026, 6, 12));
    expect(memory.songs.map((t) => t.id), ['t2', 't1']);
    expect(memory.place.label, 'Sahil');
  });

  test('nothing when here recently, never here, or here every day', () {
    expect(
      findPlaceMemory(
        [play('t1', now.subtract(const Duration(days: 1)))],
        latitude: 40.38,
        longitude: 49.89,
        now: now,
      ),
      isNull,
    );
    expect(
      findPlaceMemory(
        [play('t1', DateTime(2026, 6, 12))],
        latitude: 41,
        longitude: 29,
        now: now,
      ),
      isNull,
    );
    expect(
      findPlaceMemory(
        [
          for (var d = 0; d < 25; d++)
            play('t$d', DateTime(2026, 9).add(Duration(days: d))),
        ],
        latitude: 40.38,
        longitude: 49.89,
        now: now,
      ),
      isNull,
      reason: 'home or work',
    );
  });
}
