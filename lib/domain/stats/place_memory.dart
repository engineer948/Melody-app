import 'dart:math';

import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/stats/play_event.dart';
import 'package:meta/meta.dart';

/// "You are back where you listened to …": the last day music was played
/// near here, and its songs.
@immutable
class PlaceMemory {
  /// Creates a memory.
  const PlaceMemory({
    required this.place,
    required this.day,
    required this.songs,
  });

  /// The place as it was saved.
  final PlayPlace place;

  /// Midnight of the last day music was played there.
  final DateTime day;

  /// Songs played there that day, most played first.
  final List<Track> songs;

  /// Key of the place, to remember when it was last brought up.
  String get key => '${place.latitude},${place.longitude}';
}

/// Plays within this distance count as "here".
const placeRadiusKm = 1.0;

/// No memory when music was played here more recently than this.
const placeAwayAtLeast = Duration(days: 3);

/// Places with music on more days than this are everyday places (home,
/// work) and are not brought up.
const everydayPlaceDays = 20;

/// The memory for being at [latitude], [longitude] at [now], from [events]
/// (plays with a place, any order), or `null` when there is nothing worth
/// bringing up.
PlaceMemory? findPlaceMemory(
  List<PlayEvent> events, {
  required double latitude,
  required double longitude,
  required DateTime now,
}) {
  final near = [
    for (final e in events)
      if (e.place case final p?
          when _km(latitude, longitude, p.latitude, p.longitude) <=
              placeRadiusKm)
        e,
  ]..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  if (near.isEmpty) return null;
  final last = near.last;
  if (now.difference(last.startedAt) < placeAwayAtLeast) return null;
  DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);
  final days = {for (final e in near) dayOf(e.startedAt)};
  if (days.length > everydayPlaceDays) return null;
  final day = dayOf(last.startedAt);
  final counts = <String, int>{};
  final tracks = <String, Track>{};
  for (final e in near) {
    if (dayOf(e.startedAt) != day || e.skipped) continue;
    counts[e.track.id] = (counts[e.track.id] ?? 0) + 1;
    tracks[e.track.id] = e.track;
  }
  if (counts.isEmpty) return null;
  final ids = counts.keys.toList()
    ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  return PlaceMemory(
    place: last.place!,
    day: day,
    songs: [for (final id in ids) tracks[id]!],
  );
}

/// Distance in kilometres (haversine).
double _km(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  double rad(double d) => d * pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(rad(lat1)) * cos(rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  return 2 * r * asin(min(1, sqrt(a)));
}
