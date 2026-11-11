import 'package:melody/domain/models/media.dart';
import 'package:melody/player/play_queue.dart';
import 'package:meta/meta.dart';

/// Active sleep timer.
@immutable
class SleepTimer {
  /// Stops at [endsAt].
  const SleepTimer.at(DateTime this.endsAt) : endOfTrack = false;

  /// Stops when the current track ends.
  const SleepTimer.endOfTrack() : endsAt = null, endOfTrack = true;

  /// When playback stops, for the timed variant.
  final DateTime? endsAt;

  /// Whether playback stops at the end of the current track.
  final bool endOfTrack;

  @override
  bool operator ==(Object other) =>
      other is SleepTimer &&
      other.endsAt == endsAt &&
      other.endOfTrack == endOfTrack;

  @override
  int get hashCode => Object.hash(endsAt, endOfTrack);
}

/// Everything the UI shows about playback, except the moving position.
@immutable
class PlayerState {
  /// Creates a state.
  const PlayerState({
    this.queue = const PlayQueue(),
    this.playing = false,
    this.buffering = false,
    this.duration,
    this.speed = 1,
    this.sleepTimer,
    this.error,
    this.albumInOrder = false,
  });

  /// What is queued.
  final PlayQueue queue;

  /// Whether playback is running.
  final bool playing;

  /// Whether audio is loading.
  final bool buffering;

  /// Duration of the current track.
  final Duration? duration;

  /// Playback speed.
  final double speed;

  /// Active sleep timer.
  final SleepTimer? sleepTimer;

  /// Last playback error.
  final String? error;

  /// Whether the queue is one album in its own order (for ReplayGain).
  final bool albumInOrder;

  /// The current track.
  Track? get current => queue.current?.track;

  /// Whether something is loaded.
  bool get hasQueue => !queue.isEmpty;

  /// Returns a copy with the given fields replaced.
  PlayerState copyWith({
    PlayQueue? queue,
    bool? playing,
    bool? buffering,
    Duration? duration,
    double? speed,
    SleepTimer? sleepTimer,
    bool clearSleepTimer = false,
    String? error,
    bool clearError = false,
    bool? albumInOrder,
  }) => PlayerState(
    queue: queue ?? this.queue,
    playing: playing ?? this.playing,
    buffering: buffering ?? this.buffering,
    duration: duration ?? this.duration,
    speed: speed ?? this.speed,
    sleepTimer: clearSleepTimer ? null : sleepTimer ?? this.sleepTimer,
    error: clearError ? null : error ?? this.error,
    albumInOrder: albumInOrder ?? this.albumInOrder,
  );
}
