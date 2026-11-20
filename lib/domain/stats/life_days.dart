import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/stats/play_event.dart';
import 'package:meta/meta.dart';

/// One day of the "soundtrack of your life".
@immutable
class LifeDay {
  /// Creates a day.
  const LifeDay({
    required this.day,
    required this.places,
    required this.songs,
    required this.firsts,
    required this.listened,
  });

  /// Midnight of the day (local time).
  final DateTime day;

  /// Names of the places of the day, most plays first.
  final List<String> places;

  /// Songs of the day with their plays, most played first.
  final List<(Track, int)> songs;

  /// Ids of songs heard for the very first time that day.
  final Set<String> firsts;

  /// Time spent listening that day.
  final Duration listened;
}

/// Groups [events] into days, newest first. [firstPlays] holds the first
/// play of every song ever (by id) to mark first listens.
List<LifeDay> lifeDays(
  List<PlayEvent> events,
  Map<String, DateTime> firstPlays,
) {
  final byDay = <DateTime, List<PlayEvent>>{};
  for (final e in events) {
    final day = DateTime(e.startedAt.year, e.startedAt.month, e.startedAt.day);
    byDay.putIfAbsent(day, () => []).add(e);
  }
  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
  return [for (final day in days) _day(day, byDay[day]!, firstPlays)];
}

LifeDay _day(
  DateTime day,
  List<PlayEvent> events,
  Map<String, DateTime> firstPlays,
) {
  final placeCounts = <String, int>{};
  final songCounts = <String, int>{};
  final tracks = <String, Track>{};
  var listened = Duration.zero;
  final firsts = <String>{};
  for (final e in events) {
    listened += e.listened;
    if (e.place case final place?) {
      placeCounts[place.label] = (placeCounts[place.label] ?? 0) + 1;
    }
    final id = e.track.id;
    tracks[id] = e.track;
    if (!e.skipped) songCounts[id] = (songCounts[id] ?? 0) + 1;
    if (firstPlays[id] case final first? when _sameDay(first, day)) {
      firsts.add(id);
    }
  }
  final places = placeCounts.keys.toList()
    ..sort((a, b) => placeCounts[b]!.compareTo(placeCounts[a]!));
  final ids = songCounts.keys.toList()
    ..sort((a, b) {
      // First listens first, then the most played.
      final first = (firsts.contains(b) ? 1 : 0) - (firsts.contains(a) ? 1 : 0);
      return first != 0 ? first : songCounts[b]!.compareTo(songCounts[a]!);
    });
  return LifeDay(
    day: day,
    places: places,
    songs: [for (final id in ids) (tracks[id]!, songCounts[id]!)],
    firsts: firsts,
    listened: listened,
  );
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
