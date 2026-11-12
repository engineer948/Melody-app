import 'package:flutter_test/flutter_test.dart';
import 'package:melody/domain/stats/play_event.dart';
import 'package:melody/player/history_recorder.dart';
import 'package:melody/player/play_queue.dart';
import 'package:melody/player/player_state.dart';

import '../helpers/fakes.dart';

void main() {
  late DateTime now;
  late List<PlayEvent> saved;
  late HistoryRecorder recorder;
  final queue = PlayQueue.of([makeTrack('t0'), makeTrack('t1')]);

  setUp(() {
    now = DateTime(2026, 6, 10, 12);
    saved = [];
    recorder = HistoryRecorder(
      save: (e) async => saved.add(e),
      clock: () => now,
    );
  });

  void pass(Duration time) => now = now.add(time);

  test('records the time really heard, without pauses', () {
    recorder.onState(PlayerState(queue: queue, playing: true));
    pass(const Duration(seconds: 60));
    recorder.onState(PlayerState(queue: queue));
    pass(const Duration(minutes: 10)); // Paused.
    recorder.onState(PlayerState(queue: queue, playing: true));
    pass(const Duration(seconds: 50));
    recorder.onState(PlayerState(queue: queue.jumpTo(1), playing: true));

    expect(saved, hasLength(1));
    expect(saved.single.track.id, 't0');
    expect(saved.single.listened, const Duration(seconds: 110));
    expect(saved.single.skipped, isFalse);
    expect(saved.single.startedAt, DateTime(2026, 6, 10, 12));
  });

  test('leaving a track early is a skip; a blip is ignored', () {
    recorder.onState(PlayerState(queue: queue, playing: true));
    pass(const Duration(seconds: 20));
    recorder.onState(PlayerState(queue: queue.jumpTo(1), playing: true));
    pass(const Duration(seconds: 1));
    recorder.onState(const PlayerState());

    expect(saved, hasLength(1));
    expect(saved.single.skipped, isTrue);
  });

  test('a track that runs to its end is written when it stops', () {
    final last = queue.jumpTo(1);
    recorder.onState(PlayerState(queue: last, playing: true));
    pass(const Duration(minutes: 3, seconds: 5));
    recorder.onState(
      PlayerState(queue: last, duration: const Duration(minutes: 3)),
    );
    expect(saved.single.track.id, 't1');

    // Playing it again starts a new entry.
    recorder.onState(PlayerState(queue: last, playing: true));
    pass(const Duration(minutes: 2));
    recorder.flush();
    expect(saved, hasLength(2));
    expect(saved.last.listened, const Duration(minutes: 2));
  });

  test('a restored, never started queue records nothing', () {
    recorder
      ..onState(PlayerState(queue: queue))
      ..onState(const PlayerState());
    expect(saved, isEmpty);
  });
}
