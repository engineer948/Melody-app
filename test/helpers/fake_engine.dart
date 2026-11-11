import 'dart:async';

import 'package:melody/player/audio_engine.dart';
import 'package:melody/player/play_queue.dart';

/// In-memory [AudioEngine] that records commands.
class FakeAudioEngine implements AudioEngine {
  final _states = StreamController<EngineState>.broadcast(sync: true);

  @override
  EngineState state = const EngineState();

  /// Loaded sources.
  List<EngineSource> sources = [];

  @override
  Duration position = Duration.zero;

  /// Last volume set.
  double volume = 1;

  /// Last speed set.
  double speed = 1;

  /// Last repeat mode set.
  QueueRepeat repeat = QueueRepeat.off;

  /// Every command, for assertions.
  final log = <String>[];

  /// Band list returned by [equalizerBands].
  List<EqualizerBand> bands = const [
    EqualizerBand(centerHz: 60, minDb: -15, maxDb: 15),
    EqualizerBand(centerHz: 1000, minDb: -15, maxDb: 15),
    EqualizerBand(centerHz: 14000, minDb: -15, maxDb: 15),
  ];

  /// Last equaliser gains.
  List<double> eqGains = const [];

  /// Whether the equaliser is on.
  bool eqEnabled = false;

  void _emit(EngineState next) {
    state = next;
    _states.add(next);
  }

  /// Simulates the engine moving to [index] on its own (track ended).
  void advanceTo(int index) {
    position = Duration.zero;
    _emit(
      EngineState(
        status: EngineStatus.ready,
        playing: state.playing,
        index: index,
        duration: const Duration(minutes: 3),
      ),
    );
  }

  /// Simulates the end of the last item.
  void complete() => _emit(
    EngineState(
      status: EngineStatus.completed,
      index: state.index,
      duration: state.duration,
    ),
  );

  /// Ids of the loaded sources (last path segment).
  List<String> get loadedIds => [
    for (final s in sources) s.uri.pathSegments.last,
  ];

  /// Full addresses of the loaded sources.
  List<String> get loadedUris => [for (final s in sources) '${s.uri}'];

  @override
  Stream<EngineState> get states => _states.stream;

  @override
  Future<void> load(
    List<EngineSource> sources, {
    int index = 0,
    Duration position = Duration.zero,
  }) async {
    log.add('load $index');
    this.sources = [...sources];
    this.position = position;
    _emit(
      EngineState(
        status: EngineStatus.ready,
        playing: state.playing,
        index: index,
        duration: const Duration(minutes: 3),
      ),
    );
  }

  @override
  Future<void> insert(int index, List<EngineSource> sources) async {
    log.add('insert $index ${sources.length}');
    this.sources.insertAll(index, sources);
  }

  @override
  Future<void> removeAt(int index) async {
    log.add('remove $index');
    sources.removeAt(index);
  }

  @override
  Future<void> move(int from, int to) async {
    log.add('move $from $to');
    sources.insert(to, sources.removeAt(from));
  }

  @override
  Future<void> play() async {
    log.add('play');
    _emit(
      EngineState(
        status: EngineStatus.ready,
        playing: true,
        index: state.index,
        duration: state.duration,
      ),
    );
  }

  @override
  Future<void> pause() async {
    log.add('pause');
    _emit(
      EngineState(
        status: EngineStatus.ready,
        index: state.index,
        duration: state.duration,
      ),
    );
  }

  @override
  Future<void> stop() async {
    log.add('stop');
    sources = [];
    _emit(const EngineState());
  }

  @override
  Future<void> seek(Duration position, {int? index}) async {
    log.add('seek ${position.inSeconds}${index == null ? '' : ' @$index'}');
    this.position = position;
    if (index != null && index != state.index) advanceTo(index);
  }

  @override
  Future<void> setRepeat(QueueRepeat mode) async => repeat = mode;

  @override
  Future<void> setSpeed(double speed) async => this.speed = speed;

  @override
  Future<void> setVolume(double volume) async => this.volume = volume;

  @override
  Future<List<EqualizerBand>> equalizerBands() async => bands;

  @override
  Future<void> setEqualizer({
    required bool enabled,
    required List<double> gainsDb,
  }) async {
    eqEnabled = enabled;
    eqGains = gainsDb;
  }

  @override
  Future<void> setLoudnessBoost(double db) async {}

  /// Last crossfade length set.
  Duration crossfade = Duration.zero;

  @override
  Future<void> setCrossfade(Duration overlap) async => crossfade = overlap;

  @override
  Future<void> dispose() => _states.close();
}
