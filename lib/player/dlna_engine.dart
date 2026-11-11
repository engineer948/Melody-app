import 'dart:async';

import 'package:melody/core/logging/app_logger.dart';
import 'package:melody/data/dlna/dlna_client.dart';
import 'package:melody/data/dlna/dlna_models.dart';
import 'package:melody/player/audio_engine.dart';
import 'package:melody/player/play_queue.dart';

const _log = AppLogger('dlna');

/// [AudioEngine] that plays on a UPnP / DLNA renderer instead of the phone.
///
/// The renderer only knows one track at a time, so the queue lives here:
/// the engine polls the renderer and loads the next track when the current
/// one ends. Volume changes, the equaliser and crossfade do not apply.
class DlnaEngine implements AudioEngine {
  /// Creates an engine for [renderer].
  DlnaEngine(
    this.renderer, {
    DlnaClient? client,
    this.pollEvery = const Duration(seconds: 1),
  }) : _client = client ?? DlnaClient();

  /// The device being controlled.
  final DlnaRenderer renderer;

  /// How often the renderer is asked for its position.
  final Duration pollEvery;

  final DlnaClient _client;
  final _states = StreamController<EngineState>.broadcast();
  EngineState _state = const EngineState();
  List<EngineSource> _list = const [];
  int? _index;
  QueueRepeat _repeat = QueueRepeat.off;
  Duration _position = Duration.zero;
  DateTime? _positionAt;
  Duration? _duration;
  Duration _startAt = Duration.zero;
  bool _playing = false;
  bool _opened = false;
  bool _heardPlaying = false;
  bool _switching = false;
  bool _playWhenLoaded = false;
  Timer? _poll;

  void _publish({EngineStatus? status, String? error}) {
    final next = EngineState(
      status: status ?? (_index == null ? EngineStatus.idle : _state.status),
      playing: _playing,
      index: _index,
      duration: _duration,
      error: error,
    );
    if (next == _state) return;
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error) {
      _log.error('Renderer did not answer', error);
      _publish(error: '$error');
    }
  }

  void _setPosition(Duration value) {
    _position = value;
    _positionAt = DateTime.now();
  }

  /// Loads the current item on the renderer and optionally starts it.
  Future<void> _open({required bool play}) async {
    final index = _index;
    if (index == null || index >= _list.length) return;
    final source = _list[index];
    _switching = true;
    _heardPlaying = false;
    _duration = null;
    _setPosition(Duration.zero);
    _publish(status: EngineStatus.buffering);
    try {
      await _client.setUri(
        renderer,
        source.uri,
        DlnaMetadata(
          title: source.title ?? '',
          artist: source.artist,
          album: source.album,
          artUri: source.artUri,
        ),
      );
      _opened = true;
      if (play) {
        await _client.play(renderer);
        if (_startAt > Duration.zero) {
          await _client.seek(renderer, _startAt);
          _setPosition(_startAt);
        }
        _startAt = Duration.zero;
        _startPolling();
      }
      _publish(status: EngineStatus.ready);
    } on Object catch (error) {
      _log.error('Could not load the track on the renderer', error);
      _playing = false;
      _publish(status: EngineStatus.ready, error: '$error');
    } finally {
      _switching = false;
    }
  }

  void _startPolling() {
    _poll ??= Timer.periodic(pollEvery, (_) => unawaited(_tick()));
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> _tick() async {
    if (_switching || !_opened) return;
    try {
      final info = await _client.position(renderer);
      final transport = await _client.transportState(renderer);
      if (_switching) return;
      _setPosition(info.position);
      if (info.duration != null && info.duration! > Duration.zero) {
        _duration = info.duration;
      }
      switch (transport) {
        case DlnaTransportState.playing:
          _heardPlaying = true;
          _playing = true;
          _publish(status: EngineStatus.ready);
        case DlnaTransportState.transitioning:
          _publish(status: EngineStatus.buffering);
        case DlnaTransportState.paused:
          // Paused with the renderer's own remote.
          _playing = false;
          _publish(status: EngineStatus.ready);
        case DlnaTransportState.stopped:
          if (_playing && _heardPlaying) await _advance();
      }
    } on Object catch (error) {
      _log.error('Renderer did not answer', error);
    }
  }

  /// The current track ended: go on as the repeat mode says.
  Future<void> _advance() async {
    final index = _index;
    if (index == null) return;
    final next = switch (_repeat) {
      QueueRepeat.one => index,
      _ when index + 1 < _list.length => index + 1,
      QueueRepeat.all => 0,
      QueueRepeat.off => null,
    };
    if (next == null) {
      _playing = false;
      _stopPolling();
      _publish(status: EngineStatus.completed);
      return;
    }
    _index = next;
    await _open(play: true);
  }

  @override
  Stream<EngineState> get states => _states.stream;

  @override
  EngineState get state => _state;

  @override
  Duration get position {
    final at = _positionAt;
    if (!_playing || at == null || _switching) return _position;
    // Smooth between two polls.
    final guess = _position + DateTime.now().difference(at);
    final duration = _duration;
    return duration != null && guess > duration ? duration : guess;
  }

  @override
  Future<void> load(
    List<EngineSource> sources, {
    int index = 0,
    Duration position = Duration.zero,
  }) async {
    _list = [...sources];
    _index = sources.isEmpty ? null : index.clamp(0, sources.length - 1);
    _opened = false;
    _startAt = position;
    _duration = null;
    _setPosition(position);
    _publish(status: EngineStatus.ready);
    if (_playWhenLoaded) {
      _playWhenLoaded = false;
      await play();
    }
  }

  @override
  Future<void> insert(int index, List<EngineSource> sources) async {
    _list = [..._list]..insertAll(index, sources);
    final current = _index;
    if (current != null && index <= current) _index = current + sources.length;
    _publish();
  }

  @override
  Future<void> removeAt(int index) async {
    final current = _index;
    _list = [..._list]..removeAt(index);
    if (current == null) return;
    if (index < current) {
      _index = current - 1;
    } else if (index == current) {
      _index = _list.isEmpty ? null : current.clamp(0, _list.length - 1);
      _opened = false;
      if (_playing && _index != null) await _open(play: true);
    }
    _publish();
  }

  @override
  Future<void> move(int from, int to) async {
    final current = _index == null ? null : _list[_index!];
    final list = [..._list];
    list.insert(to, list.removeAt(from));
    _list = list;
    if (current != null) _index = list.indexOf(current);
    _publish();
  }

  @override
  Future<void> play() async {
    if (_index == null) {
      _playWhenLoaded = true; // Asked before the queue arrived.
      return;
    }
    _playing = true;
    if (!_opened) {
      await _open(play: true);
      return;
    }
    _publish();
    await _guard(() => _client.play(renderer));
    _startPolling();
  }

  @override
  Future<void> pause() async {
    _playWhenLoaded = false;
    _setPosition(position);
    _playing = false;
    _publish();
    if (_opened) await _guard(() => _client.pause(renderer));
  }

  @override
  Future<void> stop() async {
    _stopPolling();
    _playing = false;
    _playWhenLoaded = false;
    final wasOpened = _opened;
    _opened = false;
    _list = const [];
    _index = null;
    _publish(status: EngineStatus.idle);
    if (wasOpened) await _guard(() => _client.stop(renderer));
  }

  @override
  Future<void> seek(Duration position, {int? index}) async {
    if (index != null && index != _index) {
      if (index < 0 || index >= _list.length) return;
      _index = index;
      _opened = false;
      _startAt = position;
      _setPosition(position);
      if (_playing) {
        await _open(play: true);
      } else {
        _publish(status: EngineStatus.ready);
      }
      return;
    }
    _setPosition(position);
    if (_opened) {
      await _guard(() => _client.seek(renderer, position));
    } else {
      _startAt = position;
    }
  }

  @override
  Future<void> setRepeat(QueueRepeat mode) async => _repeat = mode;

  @override
  Future<void> setSpeed(double speed) async {}

  // The renderer has its own volume; fades and normalisation stay local.
  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<List<EqualizerBand>> equalizerBands() async => const [];

  @override
  Future<void> setEqualizer({
    required bool enabled,
    required List<double> gainsDb,
  }) async {}

  @override
  Future<void> setLoudnessBoost(double db) async {}

  @override
  Future<void> setCrossfade(Duration overlap) async {}

  @override
  Future<void> dispose() async {
    _stopPolling();
    final wasOpened = _opened;
    _opened = false;
    await _states.close();
    if (wasOpened) {
      try {
        await _client.stop(renderer);
      } on Object catch (error) {
        _log.error('Could not stop the renderer', error);
      }
    }
  }
}
