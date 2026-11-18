import 'dart:math';

import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:meta/meta.dart';

/// Order (and choice) of the songs of a [SmartPlaylist].
enum SmartSort {
  /// Newest songs in the library first.
  recentlyAdded,

  /// Most played first.
  mostPlayed,

  /// Most recently played first.
  recentlyPlayed,

  /// A new random pick every time.
  random,

  /// Alphabetical by title.
  title;

  /// Whether only songs that were played at least once can match.
  bool get needsPlays => this == mostPlayed || this == recentlyPlayed;
}

/// A playlist defined by rules; its songs are picked again on every open.
///
/// Stored on the device only (servers have no common format for this).
@immutable
class SmartPlaylist {
  /// Creates a smart playlist.
  const SmartPlaylist({
    required this.id,
    required this.name,
    this.sort = SmartSort.recentlyAdded,
    this.favoritesOnly = false,
    this.unplayedOnly = false,
    this.genreId,
    this.genreName,
    this.yearFrom,
    this.yearTo,
    this.limit = 50,
  });

  /// Restores a playlist saved with [toJson].
  factory SmartPlaylist.fromJson(Map<String, dynamic> json) => SmartPlaylist(
    id: json['id'] as String,
    name: json['name'] as String,
    sort: SmartSort.values.asNameMap()[json['sort']] ?? SmartSort.recentlyAdded,
    favoritesOnly: json['favoritesOnly'] as bool? ?? false,
    unplayedOnly: json['unplayedOnly'] as bool? ?? false,
    genreId: json['genreId'] as String?,
    genreName: json['genreName'] as String?,
    yearFrom: json['yearFrom'] as int?,
    yearTo: json['yearTo'] as int?,
    limit: (json['limit'] as int? ?? 50).clamp(1, maxLimit),
  );

  /// Local identifier.
  final String id;

  /// Name shown in the library.
  final String name;

  /// Order and choice of the songs.
  final SmartSort sort;

  /// Only favourite songs.
  final bool favoritesOnly;

  /// Only songs never played (ignored for [SmartSort.needsPlays]).
  final bool unplayedOnly;

  /// Only songs of this genre.
  final String? genreId;

  /// Name of [genreId], for display.
  final String? genreName;

  /// Released in this year or later.
  final int? yearFrom;

  /// Released in this year or earlier.
  final int? yearTo;

  /// Maximum number of songs.
  final int limit;

  /// Choices for [limit].
  static const limitChoices = [25, 50, 100, 250, 500];

  /// Highest allowed [limit].
  static const maxLimit = 500;

  /// Songs looked at when rules have to be checked on the device.
  static const poolSize = 2000;

  /// Whether some rules are checked on the device, not by the server.
  bool get filtersLocally =>
      yearFrom != null || yearTo != null || (unplayedOnly && !sort.needsPlays);

  /// Whether [track] passes the rules the server cannot check.
  bool matches(Track track) {
    if (unplayedOnly && !sort.needsPlays && track.playCount > 0) return false;
    final from = yearFrom;
    final to = yearTo;
    if (from != null || to != null) {
      final year = track.year;
      if (year == null) return false;
      if (from != null && year < from) return false;
      if (to != null && year > to) return false;
    }
    return true;
  }

  /// Returns a copy with the given fields replaced; the `clear…` flags
  /// remove the genre or a year bound.
  SmartPlaylist copyWith({
    String? name,
    SmartSort? sort,
    bool? favoritesOnly,
    bool? unplayedOnly,
    String? genreId,
    String? genreName,
    int? yearFrom,
    int? yearTo,
    int? limit,
    bool clearGenre = false,
    bool clearYearFrom = false,
    bool clearYearTo = false,
  }) => SmartPlaylist(
    id: id,
    name: name ?? this.name,
    sort: sort ?? this.sort,
    favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    unplayedOnly: unplayedOnly ?? this.unplayedOnly,
    genreId: clearGenre ? null : genreId ?? this.genreId,
    genreName: clearGenre ? null : genreName ?? this.genreName,
    yearFrom: clearYearFrom ? null : yearFrom ?? this.yearFrom,
    yearTo: clearYearTo ? null : yearTo ?? this.yearTo,
    limit: limit ?? this.limit,
  );

  /// Serialises the playlist.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sort': sort.name,
    'favoritesOnly': favoritesOnly,
    'unplayedOnly': unplayedOnly,
    'genreId': ?genreId,
    'genreName': ?genreName,
    'yearFrom': ?yearFrom,
    'yearTo': ?yearTo,
    'limit': limit,
  };

  /// Picks the songs from [source].
  ///
  /// The server sorts and filters by favourite and genre; years and "never
  /// played" are checked here on a larger pool of songs.
  Future<Result<List<Track>>> resolve(MusicSource source, {Random? random}) =>
      Result.guard(() async {
        final local = filtersLocally;
        final wanted = local || sort == SmartSort.random ? poolSize : limit;
        final tracks = <Track>[];
        const page = 500;
        for (var offset = 0; offset < wanted; offset += page) {
          final size = min(page, wanted - offset);
          final result = await source.tracks(
            TrackQuery(
              sort: _serverSort,
              genreId: genreId,
              favoritesOnly: favoritesOnly,
              offset: offset,
              limit: size,
            ),
          );
          final batch = switch (result) {
            Ok(:final value) => value,
            Err(:final failure) => throw failure,
          };
          tracks.addAll(batch.where(matches));
          if (batch.length < size) break;
          if (!local && sort != SmartSort.random && tracks.length >= limit) {
            break;
          }
        }
        if (sort == SmartSort.random) tracks.shuffle(random);
        return tracks.take(limit).toList();
      }, onError: (e) => e is Failure ? e : UnknownFailure(cause: e));

  TrackSort get _serverSort => switch (sort) {
    SmartSort.recentlyAdded || SmartSort.random => TrackSort.dateAdded,
    SmartSort.mostPlayed => TrackSort.mostPlayed,
    SmartSort.recentlyPlayed => TrackSort.recentlyPlayed,
    SmartSort.title => TrackSort.name,
  };
}
