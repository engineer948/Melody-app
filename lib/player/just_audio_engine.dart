import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:melody/core/logging/app_logger.dart';
import 'package:melody/player/audio_engine.dart';
import 'package:melody/player/play_queue.dart';
import 'package:melody/player/stream_cache.dart';

const _log = AppLogger('engine');

/// [AudioEngine] backed by just_audio (ExoPlayer on Android, AVPlayer on
/// iOS). A playlist gives gapless transitions.
class JustAudioEngine implements AudioEngine {
  /// Creates the engine and its audio effects.
  JustAudioEngine({this._cache}) {
    _player = AudioPlayer(
      audioPipeline: Platform.isAndroid
          ? AudioPipeline(androidAudioEffects: [_loudness, _equalizer])
          : null,
    );
    _subscriptions = [
      _player.playerStateStream.listen((_) => _publish()),
      _player.currentIndexStream.listen((_) => _publish()),
      _player.durationStream.listen((_) => _publish()),
      _player.positionStream.listen(_maybeStartFade),
      _player.currentIndexStream.listen(_onIndexForFade),
      _player.playbackEventStream.listen(
        (_) {},
        onError: (Object error, StackTrace stack) {
          _log.error('Playback error', error, stack);
          _publish(error: '$error');
        },
      ),
    ];
  }

  late final AudioPlayer _player;
  final StreamCache? _cache;
  final _equalizer = AndroidEqualizer();
  final _loudness = AndroidLoudnessEnhancer();
  late final List<StreamSubscription<Object?>> _subscriptions;
  final _states = StreamController<EngineState>.broadcast();
  EngineState _state = const EngineState();

  void _publish({String? error}) {
    final processing = _player.processingState;
    final next = EngineState(
      status: switch (processing) {
        ProcessingState.idle => EngineStatus.idle,
        ProcessingState.loading ||
        ProcessingState.buffering => EngineStatus.buffering,
        ProcessingState.ready => EngineStatus.ready,
        ProcessingState.completed => EngineStatus.completed,
      },
      playing: _player.playing,
      index: _player.currentIndex,
      duration: _player.duration,
      error: error,
    );
    if (next == _state) return;
    _state = next;
    _states.add(next);
  }

  Future<AudioSource> _source(EngineSource s) async {
    final key = s.cacheKey;
    final file = key == null ? null : await _cache?.fileFor(key);
    if (file == null) {
      return AudioSource.uri(s.uri, headers: s.headers, tag: s.tag);
    }
    // The only caching source just_audio offers; marked experimental, it is
    // used for original-quality files only and can be switched off.
    // ignore: experimental_member_use
    return LockCachingAudioSource(
      s.uri,
      headers: s.headers,
      cacheFile: file,
      tag: s.tag,
    );
  }

  Future<List<AudioSource>> _sources(List<EngineSource> sources) =>
      Future.wait(sources.map(_source));

  // ---- Crossfade ----------------------------------------------------------
  //
  // Near the end of a track the next one starts on a second player while
  // the volumes cross. When the main player reaches the next item, it jumps
  // to where the second player is and takes over. Experimental: the hand-
  // over can cause a short hiccup on slow connections.

  Duration _crossfade = Duration.zero;
  List<EngineSource> _list = const [];
  AudioPlayer? _fader;
  int? _fadeTarget;
  Timer? _fadeTimer;
  double _volume = 1;

  @override
  Future<void> setCrossfade(Duration overlap) async {
    _crossfade = overlap;
    if (overlap == Duration.zero) await _cancelFade();
  }

  void _maybeStartFade(Duration position) {
    final duration = _player.duration;
    final next = _player.nextIndex;
    if (_crossfade == Duration.zero ||
        _fader != null ||
        !_player.playing ||
        duration == null ||
        next == null ||
        next == _player.currentIndex ||
        next >= _list.length) {
      return;
    }
    final remaining = duration - position;
    if (remaining > _crossfade || remaining < const Duration(seconds: 1)) {
      return;
    }
    unawaited(_startFade(next, remaining));
  }

  Future<void> _startFade(int next, Duration length) async {
    final fader = _fader = AudioPlayer();
    _fadeTarget = next;
    try {
      await fader.setAudioSource(await _source(_list[next]));
      await fader.setVolume(0);
      unawaited(fader.play());
    } on Object catch (error) {
      _log.error('Crossfade unavailable', error);
      await _cancelFade();
      return;
    }
    const tick = Duration(milliseconds: 100);
    final steps = (length.inMilliseconds / tick.inMilliseconds).ceil();
    var step = 0;
    _fadeTimer = Timer.periodic(tick, (timer) {
      step++;
      final t = (step / steps).clamp(0.0, 1.0);
      unawaited(_player.setVolume(_volume * (1 - t)));
      unawaited(fader.setVolume(_volume * t));
      if (t >= 1) timer.cancel();
    });
  }

  void _onIndexForFade(int? index) {
    final fader = _fader;
    if (fader == null) return;
    if (index == _fadeTarget) {
      unawaited(_handOver(fader));
    } else {
      unawaited(_cancelFade());
    }
  }

  Future<void> _handOver(AudioPlayer fader) async {
    final position = fader.position;
    _fadeTimer?.cancel();
    _fader = null;
    _fadeTarget = null;
    await _player.seek(position);
    await _player.setVolume(_volume);
    await fader.dispose();
  }

  Future<void> _cancelFade() async {
    _fadeTimer?.cancel();
    final fader = _fader;
    _fader = null;
    _fadeTarget = null;
    if (fader != null) await fader.dispose();
    await _player.setVolume(_volume);
  }

  @override
  Stream<EngineState> get states => _states.stream;

  @override
  EngineState get state => _state;

  @override
  Duration get position => _player.position;

  @override
  Future<void> load(
    List<EngineSource> sources, {
    int index = 0,
    Duration position = Duration.zero,
  }) async {
    await _cancelFade();
    _list = [...sources];
    try {
      await _player.setAudioSources(
        await _sources(sources),
        initialIndex: index,
        initialPosition: position,
        preload: false,
      );
    } on PlayerInterruptedException {
      // A newer load replaced this one.
    }
  }

  @override
  Future<void> insert(int index, List<EngineSource> sources) async {
    _list = [..._list]..insertAll(index, sources);
    await _player.insertAudioSources(index, await _sources(sources));
  }

  @override
  Future<void> removeAt(int index) async {
    await _cancelFade();
    _list = [..._list]..removeAt(index);
    await _player.removeAudioSourceAt(index);
  }

  @override
  Future<void> move(int from, int to) async {
    await _cancelFade();
    final list = [..._list];
    list.insert(to, list.removeAt(from));
    _list = list;
    await _player.moveAudioSource(from, to);
  }

  @override
  Future<void> play() async {
    unawaited(_player.play());
  }

  @override
  Future<void> pause() async {
    await _cancelFade();
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _cancelFade();
    await _player.stop();
  }

  @override
  Future<void> seek(Duration position, {int? index}) async {
    await _cancelFade();
    await _player.seek(position, index: index);
  }

  @override
  Future<void> setRepeat(QueueRepeat mode) =>
      _player.setLoopMode(switch (mode) {
        QueueRepeat.off => LoopMode.off,
        QueueRepeat.all => LoopMode.all,
        QueueRepeat.one => LoopMode.one,
      });

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_fader == null) await _player.setVolume(_volume);
  }

  @override
  Future<List<EqualizerBand>> equalizerBands() async {
    if (!Platform.isAndroid) return const [];
    try {
      final parameters = await _equalizer.parameters;
      return [
        for (final band in parameters.bands)
          EqualizerBand(
            centerHz: band.centerFrequency,
            minDb: parameters.minDecibels,
            maxDb: parameters.maxDecibels,
          ),
      ];
    } on Object catch (error) {
      _log.error('Equalizer unavailable', error);
      return const [];
    }
  }

  @override
  Future<void> setEqualizer({
    required bool enabled,
    required List<double> gainsDb,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await _equalizer.setEnabled(enabled);
      final bands = (await _equalizer.parameters).bands;
      for (var i = 0; i < bands.length && i < gainsDb.length; i++) {
        await bands[i].setGain(gainsDb[i]);
      }
    } on Object catch (error) {
      _log.error('Equalizer unavailable', error);
    }
  }

  @override
  Future<void> setLoudnessBoost(double db) async {
    if (!Platform.isAndroid) return;
    try {
      await _loudness.setEnabled(db > 0);
      await _loudness.setTargetGain(db);
    } on Object catch (error) {
      _log.error('Loudness enhancer unavailable', error);
    }
  }

  @override
  Future<void> dispose() async {
    await _cancelFade();
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _player.dispose();
    await _states.close();
  }
}
