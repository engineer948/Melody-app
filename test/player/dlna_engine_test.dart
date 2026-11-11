import 'package:flutter_test/flutter_test.dart';
import 'package:melody/data/dlna/dlna_client.dart';
import 'package:melody/data/dlna/dlna_models.dart';
import 'package:melody/player/audio_engine.dart';
import 'package:melody/player/dlna_engine.dart';
import 'package:melody/player/play_queue.dart';

/// Scripted renderer.
class _FakeClient implements DlnaClient {
  final log = <String>[];
  DlnaTransportState transport = DlnaTransportState.stopped;
  Duration at = Duration.zero;

  @override
  Future<void> setUri(DlnaRenderer r, Uri uri, DlnaMetadata meta) async {
    log.add('uri ${uri.pathSegments.last} "${meta.title}"');
    transport = DlnaTransportState.stopped;
    at = Duration.zero;
  }

  @override
  Future<void> play(DlnaRenderer r) async {
    log.add('play');
    transport = DlnaTransportState.playing;
  }

  @override
  Future<void> pause(DlnaRenderer r) async {
    log.add('pause');
    transport = DlnaTransportState.paused;
  }

  @override
  Future<void> stop(DlnaRenderer r) async {
    log.add('stop');
    transport = DlnaTransportState.stopped;
  }

  @override
  Future<void> seek(DlnaRenderer r, Duration position) async {
    log.add('seek ${position.inSeconds}');
    at = position;
  }

  @override
  Future<DlnaPosition> position(DlnaRenderer r) async =>
      (position: at, duration: const Duration(minutes: 3));

  @override
  Future<DlnaTransportState> transportState(DlnaRenderer r) async => transport;

  @override
  Future<int?> volume(DlnaRenderer r) async => 50;

  @override
  Future<void> setVolume(DlnaRenderer r, int volume) async {}

  @override
  Future<DlnaRenderer?> describe(Uri location) async => null;
}

void main() {
  final renderer = DlnaRenderer(
    id: 'r1',
    name: 'TV',
    avTransportUrl: Uri.parse('http://tv/avt'),
  );
  const poll = Duration(milliseconds: 20);
  late _FakeClient client;
  late DlnaEngine engine;

  List<EngineSource> sources(int count) => [
    for (var i = 0; i < count; i++)
      EngineSource(uri: Uri.parse('http://server/t$i'), title: 'Song $i'),
  ];

  /// Lets a few polls happen.
  Future<void> polls() => Future<void>.delayed(poll * 4);

  setUp(() {
    client = _FakeClient();
    engine = DlnaEngine(renderer, client: client, pollEvery: poll);
  });
  tearDown(() => engine.dispose());

  test('nothing is sent until playback starts', () async {
    await engine.load(sources(2), index: 1);
    expect(client.log, isEmpty);
    expect(engine.state.index, 1);
    expect(engine.state.playing, isFalse);
  });

  test(
    'play loads the current track and resumes at the saved position',
    () async {
      await engine.load(sources(2), position: const Duration(seconds: 42));
      await engine.play();
      expect(client.log, ['uri t0 "Song 0"', 'play', 'seek 42']);
      expect(engine.state.playing, isTrue);
      expect(engine.state.status, EngineStatus.ready);
    },
  );

  test('moves on when the renderer finishes a track', () async {
    await engine.load(sources(2));
    await engine.play();
    await polls(); // Hears "playing".
    client.transport = DlnaTransportState.stopped; // The track ended.
    await polls();
    expect(engine.state.index, 1);
    expect(
      client.log,
      containsAllInOrder(['uri t0 "Song 0"', 'uri t1 "Song 1"']),
    );
    expect(engine.state.playing, isTrue);
  });

  test('completes after the last track, or wraps with repeat all', () async {
    await engine.load(sources(1));
    await engine.play();
    await polls();
    client.transport = DlnaTransportState.stopped;
    await polls();
    expect(engine.state.status, EngineStatus.completed);
    expect(engine.state.playing, isFalse);

    await engine.setRepeat(QueueRepeat.all);
    await engine.load(sources(2), index: 1);
    await engine.play();
    await polls();
    client.transport = DlnaTransportState.stopped;
    await polls();
    expect(engine.state.index, 0);
  });

  test('a pause on the renderer itself is noticed', () async {
    await engine.load(sources(1));
    await engine.play();
    await polls();
    client.transport = DlnaTransportState.paused;
    await polls();
    expect(engine.state.playing, isFalse);
  });

  test('skipping while playing opens the new track', () async {
    await engine.load(sources(3));
    await engine.play();
    await engine.seek(Duration.zero, index: 2);
    expect(engine.state.index, 2);
    expect(client.log.last, 'play');
    expect(client.log, contains('uri t2 "Song 2"'));
  });

  test('queue edits keep the current item', () async {
    await engine.load(sources(3), index: 1);
    await engine.insert(0, sources(2));
    expect(engine.state.index, 3);
    await engine.removeAt(0);
    expect(engine.state.index, 2);
    await engine.move(2, 0);
    expect(engine.state.index, 0);
  });

  test('play before load starts once the queue arrives', () async {
    await engine.play();
    await engine.load(sources(1));
    expect(client.log, ['uri t0 "Song 0"', 'play']);
  });

  test('stop and dispose stop the renderer', () async {
    await engine.load(sources(1));
    await engine.play();
    await engine.stop();
    expect(client.log.last, 'stop');
    expect(engine.state.status, EngineStatus.idle);
  });
}
