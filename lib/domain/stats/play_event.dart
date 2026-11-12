import 'package:melody/domain/models/media.dart';
import 'package:meta/meta.dart';

/// One play of a track, as kept in the on-device listening history.
@immutable
class PlayEvent {
  /// Creates an event.
  const PlayEvent({
    required this.track,
    required this.startedAt,
    required this.listened,
    this.skipped = false,
  });

  /// Shortest listen that is recorded at all.
  static const minListen = Duration(seconds: 2);

  /// Whether listening for [listened] of a track lasting [duration] counts as
  /// skipping it: less than half of it and less than four minutes.
  static bool isSkip(Duration listened, Duration? duration) {
    if (listened >= const Duration(minutes: 4)) return false;
    if (duration == null || duration == Duration.zero) {
      return listened < const Duration(seconds: 30);
    }
    return listened.inMilliseconds < duration.inMilliseconds / 2;
  }

  /// The track, as it was when played.
  final Track track;

  /// When playback of the track began (local time).
  final DateTime startedAt;

  /// Time actually listened.
  final Duration listened;

  /// Whether the track was left early.
  final bool skipped;
}
