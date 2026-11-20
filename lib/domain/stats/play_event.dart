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
    this.place,
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

  /// Rough place where it was played, when the user allowed it.
  final PlayPlace? place;

  /// Copy with [place].
  PlayEvent withPlace(PlayPlace? place) => PlayEvent(
    track: track,
    startedAt: startedAt,
    listened: listened,
    skipped: skipped,
    place: place,
  );
}

/// Rough place of a play: about a kilometre, and its name when known.
@immutable
class PlayPlace {
  /// Creates a place; coordinates are rounded to two decimals (~1 km).
  PlayPlace({required double latitude, required double longitude, this.name})
    : latitude = (latitude * 100).roundToDouble() / 100,
      longitude = (longitude * 100).roundToDouble() / 100;

  /// Latitude, two decimals.
  final double latitude;

  /// Longitude, two decimals.
  final double longitude;

  /// Neighbourhood or town and country, e.g. "Sahil, Bakı".
  final String? name;

  /// Name for display, or the coordinates.
  String get label =>
      name ?? '${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}';

  @override
  bool operator ==(Object other) =>
      other is PlayPlace &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.name == name;

  @override
  int get hashCode => Object.hash(latitude, longitude, name);
}
