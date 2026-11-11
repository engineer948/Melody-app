import 'dart:math';

import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/stats/play_event.dart';

/// Scores tracks from the listening history. Runs entirely on the device.
///
/// A full listen adds to a track's score, an early skip subtracts, and both
/// fade with time (half-life [halfLife]). Artists inherit the scores of their
/// tracks, and tracks usually played around the current hour get a bonus.
class Recommender {
  /// Builds the scores from [events] as seen at [now].
  Recommender(
    List<PlayEvent> events, {
    required this.now,
    this.halfLife = const Duration(days: 45),
  }) {
    for (final e in events) {
      final track = e.track;
      final age = now.difference(e.startedAt);
      final weight = pow(0.5, age.inMinutes / halfLife.inMinutes).toDouble();
      final delta = (e.skipped ? -0.6 : 1.0) * weight;
      _trackScore[track.id] = (_trackScore[track.id] ?? 0) + delta;
      for (final key in _artistKeys(track)) {
        _artistScore[key] = (_artistScore[key] ?? 0) + delta;
      }
      for (final genre in track.genres) {
        _genreScore[genre] = (_genreScore[genre] ?? 0) + delta;
      }
      if (!e.skipped && _hourDistance(e.startedAt.hour, now.hour) <= 1) {
        _hourScore[track.id] = (_hourScore[track.id] ?? 0) + weight;
      }
      final last = _lastPlayed[track.id];
      if (last == null || e.startedAt.isAfter(last)) {
        _lastPlayed[track.id] = e.startedAt;
      }
      if (!e.skipped) _plays[track.id] = (_plays[track.id] ?? 0) + 1;
      _known[track.id] = track;
    }
  }

  /// "Now".
  final DateTime now;

  /// Time after which a play counts half.
  final Duration halfLife;

  final _trackScore = <String, double>{};
  final _artistScore = <String, double>{};
  final _genreScore = <String, double>{};
  final _hourScore = <String, double>{};
  final _lastPlayed = <String, DateTime>{};
  final _plays = <String, int>{};
  final _known = <String, Track>{};

  static Iterable<String> _artistKeys(Track track) => track.artists.isEmpty
      ? [if (track.albumArtist != null) 'name:${track.albumArtist}']
      : track.artists.map((a) => a.id);

  static int _hourDistance(int a, int b) {
    final d = (a - b).abs();
    return min(d, 24 - d);
  }

  /// Whether there is any history to learn from.
  bool get hasHistory => _known.isNotEmpty;

  /// Tracks seen in the history, as they were when last played.
  Iterable<Track> get knownTracks => _known.values;

  /// When [trackId] was last played, if ever.
  DateTime? lastPlayed(String trackId) => _lastPlayed[trackId];

  /// How much the listener seems to like [track]; higher is better.
  double score(Track track) {
    var artist = 0.0;
    final keys = _artistKeys(track).toList();
    for (final key in keys) {
      artist += _artistScore[key] ?? 0;
    }
    if (keys.isNotEmpty) artist /= keys.length;
    var genre = 0.0;
    for (final g in track.genres) {
      genre += _genreScore[g] ?? 0;
    }
    if (track.genres.isNotEmpty) genre /= track.genres.length;
    return (_trackScore[track.id] ?? 0) +
        0.35 * _squash(artist) +
        0.15 * _squash(genre) +
        0.5 * (_hourScore[track.id] ?? 0) +
        (track.isFavorite ? 1.5 : 0);
  }

  // Keeps one very popular artist from drowning out everything else.
  static double _squash(double value) =>
      value >= 0 ? log(1 + value) : -log(1 - value);

  List<Track> _unique(Iterable<Track> tracks) {
    final seen = <String>{};
    return [
      for (final t in tracks)
        if (seen.add(t.id)) t,
    ];
  }

  /// Picks [count] tracks of [candidates] the listener probably likes,
  /// leaving out what was played in the last [rest] and anything in
  /// [exclude]. Better scores are more likely, but the result varies.
  List<Track> mix(
    Iterable<Track> candidates, {
    int count = 30,
    Duration rest = const Duration(hours: 3),
    Set<String> exclude = const {},
    Random? random,
  }) {
    final rng = random ?? Random();
    final pool = <(Track, double)>[];
    for (final track in _unique(candidates)) {
      if (exclude.contains(track.id)) continue;
      final last = _lastPlayed[track.id];
      if (last != null && now.difference(last) < rest) continue;
      final value = score(track);
      if (value < -0.5) continue; // Mostly skipped.
      // Weighted sampling without replacement (Efraimidis–Spirakis).
      final weight = 0.2 + max(0, value);
      pool.add((track, pow(rng.nextDouble(), 1 / weight).toDouble()));
    }
    pool.sort((a, b) => b.$2.compareTo(a.$2));
    return _spread([for (final p in pool.take(count)) p.$1]);
  }

  /// Favourites and once well-liked tracks not played for [after].
  List<Track> forgotten(
    Iterable<Track> candidates, {
    int count = 30,
    Duration after = const Duration(days: 60),
  }) {
    final picks = <(Track, double)>[];
    for (final track in _unique([...candidates, ..._known.values])) {
      final last = _lastPlayed[track.id];
      if (last != null && now.difference(last) < after) continue;
      final liked = track.isFavorite || (_plays[track.id] ?? 0) >= 3;
      if (!liked) continue;
      picks.add((track, (_plays[track.id] ?? 0) + (track.isFavorite ? 3 : 0)));
    }
    picks.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final p in picks.take(count)) p.$1];
  }

  /// Tracks of [candidates] that were never played, preferring artists and
  /// genres the listener likes.
  List<Track> discover(
    Iterable<Track> candidates, {
    int count = 30,
    Random? random,
  }) {
    final rng = random ?? Random();
    final picks = <(Track, double)>[];
    for (final track in _unique(candidates)) {
      if (_lastPlayed.containsKey(track.id) || track.playCount > 0) continue;
      picks.add((track, score(track) + rng.nextDouble()));
    }
    picks.sort((a, b) => b.$2.compareTo(a.$2));
    return _spread([for (final p in picks.take(count)) p.$1]);
  }

  /// Reorders [tracks] so the same artist rarely plays twice in a row.
  static List<Track> _spread(List<Track> tracks) {
    final rest = [...tracks];
    final result = <Track>[];
    String? lastArtist;
    while (rest.isNotEmpty) {
      var at = rest.indexWhere((t) => t.artistLine != lastArtist);
      if (at < 0) at = 0;
      final next = rest.removeAt(at);
      lastArtist = next.artistLine;
      result.add(next);
    }
    return result;
  }
}
