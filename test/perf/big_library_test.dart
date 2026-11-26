import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/recommendation/recommender.dart';
import 'package:melody/domain/stats/life_places.dart';
import 'package:melody/domain/stats/listening_stats.dart';
import 'package:melody/domain/stats/play_event.dart';
import 'package:melody/player/play_queue.dart';

/// A 50 000-song library and two years of listening must stay quick: these
/// run on the phone, often on every visit to Home.
void main() {
  final rng = Random(1);
  final tracks = [
    for (var i = 0; i < 50000; i++)
      Track(
        id: 't$i',
        title: 'Song $i',
        artists: [NamedRef(id: 'a${i % 3000}', name: 'Artist ${i % 3000}')],
        albumId: 'al${i ~/ 12}',
        genres: ['g${i % 40}'],
        duration: const Duration(minutes: 3),
      ),
  ];
  final now = DateTime(2026, 11, 26);
  final events = [
    for (var i = 0; i < 200000; i++)
      PlayEvent(
        track: tracks[rng.nextInt(tracks.length)],
        startedAt: now.subtract(Duration(minutes: rng.nextInt(1051200))),
        listened: const Duration(minutes: 2),
        skipped: rng.nextInt(5) == 0,
      ),
  ];

  void fast(String name, void Function() run, {int ms = 1500}) {
    final watch = Stopwatch()..start();
    run();
    watch.stop();
    // The timings help when a budget is broken.
    // ignore: avoid_print
    print('$name: ${watch.elapsedMilliseconds} ms');
    expect(watch.elapsedMilliseconds, lessThan(ms), reason: name);
  }

  test('suggestions, statistics and the queue on a big library', () {
    late Recommender r;
    fast('recommender', () => r = Recommender(events, now: now));
    fast('mix', () => r.mix(tracks, random: Random(2)));
    fast('forgotten', () => r.forgotten(tracks));
    fast('discover', () => r.discover(tracks, random: Random(3)));
    fast('statistics', () => ListeningStats.of(events, now: now));
    fast('played in order', () => playedInOrder(events));
    late PlayQueue q;
    fast('queue + shuffle', () {
      q = PlayQueue.of(tracks, start: 100, shuffle: true, random: Random(4));
    });
    fast('queue edits', () {
      for (var i = 0; i < 50; i++) {
        q = q.jumpTo(i).insertAt(i + 1, [tracks[i]]);
      }
    });
  });
}
