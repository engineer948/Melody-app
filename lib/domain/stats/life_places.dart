import 'dart:math';

import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/stats/play_event.dart';
import 'package:meta/meta.dart';

/// Distance in km between two points (haversine).
double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  double rad(double d) => d * pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(rad(lat1)) * cos(rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  return 2 * r * asin(min(1, sqrt(a)));
}

/// A place music was played at, for the star map.
@immutable
class PlaceStar {
  /// Creates a star.
  const PlaceStar({
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.plays,
    required this.firstVisit,
    required this.songs,
  });

  /// Rough position.
  final double latitude;

  /// Rough position.
  final double longitude;

  /// Name of the place.
  final String name;

  /// Plays there.
  final int plays;

  /// First time music was played there.
  final DateTime firstVisit;

  /// Songs played there, most played first.
  final List<Track> songs;
}

/// Groups [events] by place (plays without a place are left out); stars
/// in the order they were first visited.
List<PlaceStar> placeStars(List<PlayEvent> events) {
  final groups = <String, List<PlayEvent>>{};
  for (final e in events) {
    final p = e.place;
    if (p == null) continue;
    final key =
        '${p.latitude.toStringAsFixed(2)},${p.longitude.toStringAsFixed(2)}';
    groups.putIfAbsent(key, () => []).add(e);
  }
  final stars = <PlaceStar>[];
  for (final group in groups.values) {
    group.sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final names = <String, int>{};
    final counts = <String, int>{};
    final tracks = <String, Track>{};
    for (final e in group) {
      if (e.place!.name case final name?) names[name] = (names[name] ?? 0) + 1;
      if (e.skipped) continue;
      counts[e.track.id] = (counts[e.track.id] ?? 0) + 1;
      tracks[e.track.id] = e.track;
    }
    final ids = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    final first = group.first.place!;
    stars.add(
      PlaceStar(
        latitude: first.latitude,
        longitude: first.longitude,
        name: names.isEmpty
            ? first.label
            : (names.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value)))
                  .first
                  .key,
        plays: group.length,
        firstVisit: group.first.startedAt,
        songs: [for (final id in ids) tracks[id]!],
      ),
    );
  }
  stars.sort((a, b) => a.firstVisit.compareTo(b.firstVisit));
  return stars;
}

/// Days away from home, one after the other: a trip.
@immutable
class Trip {
  /// Creates a trip.
  const Trip({
    required this.from,
    required this.to,
    required this.place,
    required this.songs,
  });

  /// Midnight of the first day.
  final DateTime from;

  /// Midnight of the last day.
  final DateTime to;

  /// Name of the place most music was played at.
  final String place;

  /// Songs of the trip, most played first.
  final List<Track> songs;

  /// Number of days.
  int get days => to.difference(from).inDays + 1;
}

/// A day counts as away when music was played this far from home.
const tripMinKm = 50.0;

/// Finds trips in [events] (any order): runs of days with music played
/// at least [tripMinKm] from home, where home is the place with music on
/// the most days. Newest first.
List<Trip> findTrips(List<PlayEvent> events) {
  final placed = [
    for (final e in events)
      if (e.place != null) e,
  ]..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  if (placed.isEmpty) return const [];
  DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

  // Home: the ~10 km cell with music on the most days.
  final cellDays = <String, Set<DateTime>>{};
  final cellPoint = <String, PlayPlace>{};
  for (final e in placed) {
    final p = e.place!;
    final key =
        '${p.latitude.toStringAsFixed(1)},${p.longitude.toStringAsFixed(1)}';
    cellDays.putIfAbsent(key, () => {}).add(dayOf(e.startedAt));
    cellPoint.putIfAbsent(key, () => p);
  }
  final homeKey =
      (cellDays.entries.toList()
            ..sort((a, b) => b.value.length.compareTo(a.value.length)))
          .first
          .key;
  final home = cellPoint[homeKey]!;

  final awayDays = <DateTime, List<PlayEvent>>{};
  for (final e in placed) {
    final p = e.place!;
    if (distanceKm(home.latitude, home.longitude, p.latitude, p.longitude) >=
        tripMinKm) {
      awayDays.putIfAbsent(dayOf(e.startedAt), () => []).add(e);
    }
  }
  final days = awayDays.keys.toList()..sort();
  final trips = <Trip>[];
  var start = 0;
  for (var i = 1; i <= days.length; i++) {
    // A day without music in between does not end a trip.
    final ends = i == days.length || days[i].difference(days[i - 1]).inDays > 2;
    if (!ends) continue;
    final tripEvents = [for (var d = start; d < i; d++) ...awayDays[days[d]]!];
    trips.add(_trip(days[start], days[i - 1], tripEvents));
    start = i;
  }
  return trips.reversed.toList();
}

Trip _trip(DateTime from, DateTime to, List<PlayEvent> events) {
  final names = <String, int>{};
  final counts = <String, int>{};
  final tracks = <String, Track>{};
  for (final e in events) {
    final label = e.place!.label;
    names[label] = (names[label] ?? 0) + 1;
    if (e.skipped) continue;
    counts[e.track.id] = (counts[e.track.id] ?? 0) + 1;
    tracks[e.track.id] = e.track;
  }
  final ids = counts.keys.toList()
    ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  final place =
      (names.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
          .first
          .key;
  return Trip(
    from: from,
    to: to,
    place: place,
    songs: [for (final id in ids) tracks[id]!],
  );
}

/// The songs of [events] in the order they were played, without
/// skipped plays and without playing the same song twice in a row.
List<Track> playedInOrder(List<PlayEvent> events) {
  final sorted = [...events]
    ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  final out = <Track>[];
  for (final e in sorted) {
    if (e.skipped) continue;
    if (out.isNotEmpty && out.last.id == e.track.id) continue;
    out.add(e.track);
  }
  return out;
}
