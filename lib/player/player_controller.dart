import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/player/audio_engine.dart';
import 'package:melody/player/just_audio_engine.dart';
import 'package:melody/player/play_queue.dart';
import 'package:melody/player/playback_reporter.dart';
import 'package:melody/player/playback_settings.dart';
import 'package:melody/player/player_state.dart';
import 'package:melody/player/queue_store.dart';
import 'package:melody/player/stream_cache.dart';
import 'package:melody/player/streaming_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'player_controller.g.dart';

/// Disk cache of played tracks.
@Riverpod(keepAlive: true)
StreamCache streamCache(Ref ref) => StreamCache();

/// The audio engine; overridden with a fake in tests.
@Riverpod(keepAlive: true)
AudioEngine audioEngine(Ref ref) {
  final engine = JustAudioEngine(cache: ref.watch(streamCacheProvider));
  ref.onDispose(engine.dispose);
  return engine;
}

/// Current position, refreshed a few times per second while playing.
@riverpod
Stream<Duration> playerPosition(Ref ref) async* {
  final engine = ref.watch(audioEngineProvider);
  yield engine.position;
  yield* Stream.periodic(
    const Duration(milliseconds: 250),
    (_) => engine.position,
  );
}

/// Owns the queue and drives the [AudioEngine].
@Riverpod(keepAlive: true)
class PlayerController extends _$PlayerController {
  /// Interval of progress reports.
  static const reportInterval = Duration(seconds: 10);

  /// Length of the fade before the sleep timer stops playback.
  static const sleepFade = Duration(seconds: 10);

  late AudioEngine _engine;
  late PlaybackReporter _reporter;
  late QueueStore _store;
  StreamSubscription<EngineState>? _engineSub;
  Timer? _reportTimer;
  Timer? _sleepTimer;
  int? _lastUid;
  double _volume = 1;

  @override
  PlayerState build() {
    _engine = ref.watch(audioEngineProvider);
    final prefs = ref.watch(preferencesProvider);
    _store = QueueStore(prefs);
    _reporter = PlaybackReporter(
      source: () => ref.read(activeSourceProvider),
      prefs: prefs,
    );
    _engineSub = _engine.states.listen(_onEngine);
    ref
      ..listen(sessionControllerProvider.select((s) => s.activeId), (
        previous,
        next,
      ) {
        if (previous != next) unawaited(clear());
      })
      ..listen(playbackSettingsControllerProvider, (_, settings) {
        unawaited(_applyEffects(settings));
        unawaited(_applyVolume());
      })
      ..listen(streamingSettingsControllerProvider, (previous, next) {
        if (previous?.cacheMb != next.cacheMb) unawaited(_trimCache());
        unawaited(_refreshUpcoming());
      })
      ..listen(onMobileDataProvider, (previous, next) {
        if (previous?.value != next.value) unawaited(_refreshUpcoming());
      })
      ..onDispose(() {
        unawaited(_engineSub?.cancel());
        _reportTimer?.cancel();
        _sleepTimer?.cancel();
      });
    final restored = _restore();
    unawaited(_applyEffects(ref.read(playbackSettingsControllerProvider)));
    return restored;
  }

  // ---- Restore & persistence ------------------------------------------

  PlayerState _restore() {
    final saved = _store.load();
    final accountId = ref.read(sessionControllerProvider).activeId;
    if (saved == null || saved.accountId != accountId) {
      return const PlayerState();
    }
    final sources = _sources(saved.queue);
    if (sources == null) return const PlayerState();
    // Loaded after build returns, so engine events find the state set.
    unawaited(
      Future(() async {
        await _engine.load(
          sources,
          index: saved.queue.index,
          position: saved.position,
        );
        await _engine.setRepeat(saved.queue.repeat);
      }),
    );
    _lastUid = saved.queue.current?.uid;
    return PlayerState(queue: saved.queue);
  }

  Future<void> _persist() async {
    if (!ref.mounted) return;
    final accountId = ref.read(sessionControllerProvider).activeId;
    if (accountId == null) return;
    await _store.save(accountId, state.queue, _engine.position);
  }

  // ---- Engine events ----------------------------------------------------

  List<EngineSource>? _sources(PlayQueue queue) {
    final source = ref.read(activeSourceProvider);
    if (source == null) return null;
    final streaming = ref.read(streamingSettingsControllerProvider);
    final mobile = ref.read(onMobileDataProvider).value ?? false;
    final options = streaming.optionsFor(mobile: mobile);
    final accountId = ref.read(sessionControllerProvider).activeId;
    final cache = options.isOriginal && streaming.cacheMb > 0;
    return [
      for (final entry in queue.entries)
        EngineSource(
          uri: source.streamUri(entry.track, options),
          headers: source.requestHeaders,
          tag: entry.uid,
          cacheKey: cache ? '${accountId}_${entry.track.id}' : null,
        ),
    ];
  }

  /// Reloads the tracks after the current one, e.g. after the connection
  /// type changed, so they use the right quality. The current track keeps
  /// playing undisturbed.
  Future<void> _refreshUpcoming() async {
    if (!_alive || !state.hasQueue) return;
    final queue = state.queue;
    final sources = _sources(queue);
    final from = queue.index + 1;
    if (sources == null || from >= queue.length) return;
    for (var i = queue.length - 1; i >= from; i--) {
      await _engine.removeAt(i);
    }
    await _engine.insert(from, sources.sublist(from));
  }

  Future<void> _trimCache() async {
    if (!_alive) return;
    final limit = ref.read(streamingSettingsControllerProvider).cacheMb;
    final cache = ref.read(streamCacheProvider);
    await cache.trim(limit * 1024 * 1024);
  }

  void _onEngine(EngineState engine) {
    if (!_alive) return;
    final wasPlaying = state.playing;
    var queue = state.queue;
    final index = engine.index;
    if (index != null && index != queue.index && index < queue.length) {
      queue = queue.jumpTo(index);
    }
    state = state.copyWith(
      queue: queue,
      playing: engine.playing && engine.status != EngineStatus.completed,
      buffering: engine.status == EngineStatus.buffering,
      duration: engine.duration,
      error: engine.error,
      clearError: engine.error == null,
    );
    unawaited(_afterChange(wasPlaying: wasPlaying));
    if (engine.status == EngineStatus.completed) {
      unawaited(_reporter.stopped(_engine.position));
      _lastUid = null;
    }
  }

  Future<void> _afterChange({required bool wasPlaying}) async {
    if (!ref.mounted) return;
    final uid = state.queue.current?.uid;
    if (uid != _lastUid) {
      final hadTrack = _lastUid != null;
      _lastUid = uid;
      await _onTrackChanged(hadTrack: hadTrack);
    }
    if (!ref.mounted) return;
    if (wasPlaying != state.playing) {
      _reportTimer?.cancel();
      if (state.playing) {
        _reportTimer = Timer.periodic(reportInterval, (_) {
          if (!_alive) return;
          unawaited(_reporter.progress(_engine.position, paused: false));
          unawaited(_persist());
        });
      }
      await _reporter.progress(_engine.position, paused: !state.playing);
      await _persist();
    }
  }

  bool get _alive => ref.mounted;

  Future<void> _onTrackChanged({required bool hadTrack}) async {
    if (hadTrack) await _reporter.stopped(state.duration ?? Duration.zero);
    if (!_alive) return;
    final track = state.current;
    if (track != null) await _reporter.started(track.id, Duration.zero);
    if (!_alive) return;
    await _applyVolume();
    await _persist();
    unawaited(_trimCache());
    if (!_alive) return;
    if (hadTrack && state.sleepTimer?.endOfTrack == true) {
      state = state.copyWith(clearSleepTimer: true);
      await _engine.pause();
      await _engine.seek(Duration.zero);
    }
  }

  // ---- Volume, effects, fades -------------------------------------------

  double _targetVolume() {
    if (!_alive) return 1;
    final track = state.current;
    if (track == null) return 1;
    return ref
        .read(playbackSettingsControllerProvider)
        .volumeFor(track, albumInOrder: state.albumInOrder);
  }

  Future<void> _applyVolume() async {
    _volume = _targetVolume();
    if (_sleepTimer == null || state.sleepTimer?.endsAt == null) {
      await _engine.setVolume(_volume);
    }
  }

  Future<void> _applyEffects(PlaybackSettings settings) async {
    await _engine.setEqualizer(
      enabled: settings.equalizerEnabled,
      gainsDb: settings.equalizerGains,
    );
    await _engine.setLoudnessBoost(settings.loudnessBoostDb);
    await _engine.setCrossfade(Duration(seconds: settings.crossfadeSeconds));
  }

  Future<void> _ramp(double from, double to, Duration length) async {
    const steps = 8;
    for (var i = 1; i <= steps; i++) {
      await Future<void>.delayed(length ~/ steps);
      await _engine.setVolume(from + (to - from) * i / steps);
    }
  }

  Duration get _fade => Duration(
    milliseconds: ref.read(playbackSettingsControllerProvider).fadeMs,
  );

  // ---- Commands ----------------------------------------------------------

  /// Replaces the queue with [tracks] and starts at [start].
  ///
  /// [albumInOrder] marks an album played in its own order (ReplayGain).
  Future<void> playTracks(
    List<Track> tracks, {
    int start = 0,
    bool shuffle = false,
    bool albumInOrder = false,
  }) async {
    if (tracks.isEmpty) return;
    final queue = PlayQueue.of(
      tracks,
      start: start,
      shuffle: shuffle,
      repeat: state.queue.repeat,
    );
    final sources = _sources(queue);
    if (sources == null) return;
    if (_lastUid != null) await _reporter.stopped(_engine.position);
    _lastUid = null;
    state = state.copyWith(
      queue: queue,
      albumInOrder: albumInOrder && !shuffle,
      clearError: true,
    );
    await _engine.load(sources, index: queue.index);
    await _engine.setRepeat(queue.repeat);
    await _engine.play();
    await _afterChange(wasPlaying: state.playing);
  }

  /// Starts or resumes playback, fading in.
  Future<void> play() async {
    if (!state.hasQueue) return;
    final fade = _fade;
    if (fade > Duration.zero) await _engine.setVolume(0);
    await _engine.play();
    if (fade > Duration.zero) await _ramp(0, _volume, fade);
  }

  /// Pauses, fading out.
  Future<void> pause() async {
    final fade = _fade;
    if (fade > Duration.zero && state.playing) {
      await _ramp(_volume, 0, fade);
    }
    await _engine.pause();
    await _engine.setVolume(_volume);
  }

  /// Toggles between play and pause.
  Future<void> togglePlay() => state.playing ? pause() : play();

  /// Skips to the next track.
  Future<void> next() async {
    final queue = state.queue;
    if (queue.isEmpty) return;
    final target = queue.index + 1 < queue.length
        ? queue.index + 1
        : queue.repeat == QueueRepeat.off
        ? null
        : 0;
    if (target != null) await skipTo(target);
  }

  /// Restarts the track, or goes to the previous one near its start.
  Future<void> previous() async {
    if (_engine.position > const Duration(seconds: 3)) {
      await _engine.seek(Duration.zero);
      return;
    }
    final target = state.queue.previousIndex;
    if (target != null) {
      await skipTo(target);
    } else {
      await _engine.seek(Duration.zero);
    }
  }

  /// Plays the entry at [index] of the queue.
  Future<void> skipTo(int index) async {
    if (index < 0 || index >= state.queue.length) return;
    await _engine.seek(Duration.zero, index: index);
    if (!state.playing) await _engine.play();
  }

  /// Seeks inside the current track.
  Future<void> seek(Duration position) => _engine.seek(position);

  /// Inserts [tracks] after the current one.
  Future<void> playNext(List<Track> tracks) async {
    if (!state.hasQueue) {
      await playTracks(tracks);
      return;
    }
    final queue = state.queue.playNext(tracks);
    await _mirrorInsert(queue, state.queue.index + 1, tracks.length);
  }

  /// Appends [tracks] to the queue.
  Future<void> addToQueue(List<Track> tracks) async {
    if (!state.hasQueue) {
      await playTracks(tracks);
      return;
    }
    final at = state.queue.length;
    await _mirrorInsert(state.queue.append(tracks), at, tracks.length);
  }

  Future<void> _mirrorInsert(PlayQueue queue, int at, int count) async {
    final sources = _sources(queue);
    if (sources == null) return;
    state = state.copyWith(queue: queue, albumInOrder: false);
    await _engine.insert(at, sources.sublist(at, at + count));
    await _persist();
  }

  /// Removes the entry at [index].
  Future<void> removeAt(int index) async {
    if (index < 0 || index >= state.queue.length) return;
    final queue = state.queue.removeAt(index);
    state = state.copyWith(queue: queue);
    if (queue.isEmpty) {
      await clear();
      return;
    }
    await _engine.removeAt(index);
    await _persist();
  }

  /// Moves an entry within the queue.
  Future<void> move(int from, int to) async {
    final queue = state.queue.move(from, to);
    if (identical(queue, state.queue)) return;
    state = state.copyWith(queue: queue, albumInOrder: false);
    await _engine.move(from, to);
    await _persist();
  }

  /// Removes everything except the current track.
  Future<void> clearUpcoming() => _reload(state.queue.clearUpcoming());

  /// Turns shuffle on or off.
  Future<void> toggleShuffle() async {
    final queue = state.queue.withShuffle(enabled: !state.queue.shuffled);
    state = state.copyWith(albumInOrder: false);
    await _reload(queue);
  }

  /// Cycles repeat: off → all → one → off.
  Future<void> cycleRepeat() async {
    final next = switch (state.queue.repeat) {
      QueueRepeat.off => QueueRepeat.all,
      QueueRepeat.all => QueueRepeat.one,
      QueueRepeat.one => QueueRepeat.off,
    };
    state = state.copyWith(queue: state.queue.withRepeat(next));
    await _engine.setRepeat(next);
    await _persist();
  }

  Future<void> _reload(PlayQueue queue) async {
    final sources = _sources(queue);
    if (sources == null) return;
    final position = _engine.position;
    final playing = state.playing;
    state = state.copyWith(queue: queue);
    await _engine.load(sources, index: queue.index, position: position);
    if (playing) await _engine.play();
    await _persist();
  }

  /// Changes the playback speed (0.5–2).
  Future<void> setSpeed(double speed) async {
    final value = speed.clamp(0.5, 2.0);
    state = state.copyWith(speed: value);
    await _engine.setSpeed(value);
  }

  /// Starts a sleep timer; `null` [after] means "at the end of the track".
  void setSleepTimer(Duration? after) {
    _sleepTimer?.cancel();
    if (after == null) {
      _sleepTimer = null;
      state = state.copyWith(sleepTimer: const SleepTimer.endOfTrack());
      return;
    }
    final endsAt = DateTime.now().add(after);
    state = state.copyWith(sleepTimer: SleepTimer.at(endsAt));
    final fadeStart = after - sleepFade;
    _sleepTimer = Timer(
      fadeStart.isNegative ? Duration.zero : fadeStart,
      () async {
        if (!_alive) return;
        final remaining = endsAt.difference(DateTime.now());
        if (state.playing && remaining > Duration.zero) {
          await _ramp(_volume, 0, remaining);
        }
        _sleepTimer = null;
        if (!_alive) return;
        state = state.copyWith(clearSleepTimer: true);
        await _engine.pause();
        await _engine.setVolume(_volume);
      },
    );
  }

  /// Cancels the sleep timer.
  Future<void> cancelSleepTimer() async {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    state = state.copyWith(clearSleepTimer: true);
    await _engine.setVolume(_volume);
  }

  /// Replaces every queued copy of [track] (same id), e.g. after it was
  /// marked as favourite. Playback is not touched.
  void updateTrack(Track track) {
    final entries = state.queue.entries;
    if (!entries.any((e) => e.track.id == track.id)) return;
    state = state.copyWith(
      queue: state.queue.replaceTracks((t) => t.id == track.id ? track : t),
    );
    unawaited(_persist());
  }

  /// Stops playback and forgets the queue.
  Future<void> clear() async {
    if (_lastUid != null) await _reporter.stopped(_engine.position);
    _lastUid = null;
    _reportTimer?.cancel();
    _sleepTimer?.cancel();
    _sleepTimer = null;
    state = const PlayerState();
    await _engine.stop();
    await _store.clear();
  }
}
