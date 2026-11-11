import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/stats/play_event.dart';
import 'package:meta/meta.dart';

/// An entry of a "most listened" ranking.
@immutable
class Ranked<T> {
  /// Creates an entry.
  const Ranked(this.item, {required this.plays, required this.listened});

  /// What was listened to.
  final T item;

  /// Number of plays that were not skipped.
  final int plays;

  /// Total time listened.
  final Duration listened;
}

/// Figures computed from the listening history, entirely on the device.
@immutable
class ListeningStats {
  /// Creates the statistics.
  const ListeningStats({
    this.plays = 0,
    this.listened = Duration.zero,
    this.topTracks = const [],
    this.topArtists = const [],
    this.topAlbums = const [],
    this.topGenres = const [],
    this.byHour = const [],
    this.byWeekday = const [],
    this.busiestDay,
    this.busiestDayListened = Duration.zero,
    this.longestStreak = 0,
    this.currentStreak = 0,
    this.activeDays = 0,
    this.albumArtwork = const {},
  });

  /// Computes the statistics of [events]; [now] anchors the current streak.
  factory ListeningStats.of(
    List<PlayEvent> events, {
    required DateTime now,
    int top = 10,
  }) {
    if (events.isEmpty) return const ListeningStats();
    final tracks = <String, _Tally<Track>>{};
    final artists = <String, _Tally<NamedRef>>{};
    final albums = <String, _Tally<NamedRef>>{};
    final genres = <String, _Tally<String>>{};
    final byHour = List.filled(24, Duration.zero);
    final byWeekday = List.filled(7, Duration.zero);
    final byDay = <DateTime, Duration>{};
    var plays = 0;
    var listened = Duration.zero;

    for (final e in events) {
      final track = e.track;
      final count = e.skipped ? 0 : 1;
      plays += count;
      listened += e.listened;
      tracks.putIfAbsent(track.id, () => _Tally(track)).add(count, e.listened);
      final artist = track.artists.firstOrNull;
      final artistName = artist?.name ?? track.albumArtist;
      if (artistName != null && artistName.isNotEmpty) {
        artists
            .putIfAbsent(
              artist?.id ?? 'name:$artistName',
              () => _Tally(NamedRef(id: artist?.id ?? '', name: artistName)),
            )
            .add(count, e.listened);
      }
      final albumId = track.albumId;
      final albumTitle = track.albumTitle;
      if (albumId != null && albumTitle != null) {
        albums
            .putIfAbsent(
              albumId,
              () => _Tally(
                NamedRef(id: albumId, name: albumTitle),
                artwork: track.artwork,
              ),
            )
            .add(count, e.listened);
      }
      for (final genre in track.genres) {
        genres.putIfAbsent(genre, () => _Tally(genre)).add(count, e.listened);
      }
      final at = e.startedAt;
      byHour[at.hour] += e.listened;
      byWeekday[at.weekday - 1] += e.listened;
      final day = DateTime(at.year, at.month, at.day);
      byDay[day] = (byDay[day] ?? Duration.zero) + e.listened;
    }

    final busiest = byDay.entries.reduce((a, b) => b.value > a.value ? b : a);
    final (longest, current) = _streaks(byDay.keys.toSet(), now);
    return ListeningStats(
      plays: plays,
      listened: listened,
      topTracks: _rank(tracks, top),
      topArtists: _rank(artists, top),
      topAlbums: _rank(albums, top),
      topGenres: _rank(genres, top),
      byHour: byHour,
      byWeekday: byWeekday,
      busiestDay: busiest.key,
      busiestDayListened: busiest.value,
      longestStreak: longest,
      currentStreak: current,
      activeDays: byDay.length,
      albumArtwork: {
        for (final e in albums.entries)
          if (e.value.artwork != null) e.key: e.value.artwork!,
      },
    );
  }

  static List<Ranked<T>> _rank<T>(Map<String, _Tally<T>> tallies, int top) {
    final sorted = tallies.values.toList()
      ..sort((a, b) {
        final byTime = b.listened.compareTo(a.listened);
        return byTime != 0 ? byTime : b.plays.compareTo(a.plays);
      });
    return [
      for (final t in sorted.take(top))
        Ranked(t.item, plays: t.plays, listened: t.listened),
    ];
  }

  /// Longest run of consecutive days, and the run ending today or yesterday.
  static (int, int) _streaks(Set<DateTime> days, DateTime now) {
    int runEndingAt(DateTime day) {
      var length = 0;
      var cursor = day;
      while (days.contains(cursor)) {
        length++;
        cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
      }
      return length;
    }

    var longest = 0;
    for (final day in days) {
      final next = DateTime(day.year, day.month, day.day + 1);
      if (days.contains(next)) continue; // Not the end of a run.
      final length = runEndingAt(day);
      if (length > longest) longest = length;
    }
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final current = days.contains(today)
        ? runEndingAt(today)
        : runEndingAt(yesterday);
    return (longest, current);
  }

  /// Plays that were not skipped.
  final int plays;

  /// Total time listened.
  final Duration listened;

  /// Most listened tracks.
  final List<Ranked<Track>> topTracks;

  /// Most listened artists.
  final List<Ranked<NamedRef>> topArtists;

  /// Most listened albums (id and title).
  final List<Ranked<NamedRef>> topAlbums;

  /// Most listened genres.
  final List<Ranked<String>> topGenres;

  /// Time listened per hour of the day (24 entries, or empty).
  final List<Duration> byHour;

  /// Time listened per weekday, Monday first (7 entries, or empty).
  final List<Duration> byWeekday;

  /// Day with the most listening.
  final DateTime? busiestDay;

  /// Time listened on [busiestDay].
  final Duration busiestDayListened;

  /// Longest run of days with listening.
  final int longestStreak;

  /// Run of days ending today (or yesterday).
  final int currentStreak;

  /// Number of days with listening.
  final int activeDays;

  /// Covers of the albums in [topAlbums], by album id.
  final Map<String, Artwork> albumArtwork;

  /// Whether there is nothing to show.
  bool get isEmpty => listened == Duration.zero;

  /// Hour of the day with the most listening, if any.
  int? get busiestHour => _maxIndex(byHour);

  /// Weekday (1 = Monday) with the most listening, if any.
  int? get busiestWeekday {
    final index = _maxIndex(byWeekday);
    return index == null ? null : index + 1;
  }

  static int? _maxIndex(List<Duration> values) {
    int? best;
    for (var i = 0; i < values.length; i++) {
      if (values[i] > Duration.zero &&
          (best == null || values[i] > values[best])) {
        best = i;
      }
    }
    return best;
  }
}

class _Tally<T> {
  _Tally(this.item, {this.artwork});

  final T item;
  final Artwork? artwork;
  int plays = 0;
  Duration listened = Duration.zero;

  void add(int count, Duration time) {
    plays += count;
    listened += time;
  }
}
