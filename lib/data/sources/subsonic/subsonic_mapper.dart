import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/network/failure_mapper.dart';
import 'package:melody/data/sources/subsonic/subsonic_api.dart';
import 'package:melody/domain/models/media.dart';

/// Converts errors of the Subsonic client into failures.
Failure mapSubsonicError(Object error) =>
    error is SubsonicError ? error.failure : mapNetworkError(error);

/// Turns Subsonic JSON into domain models.
abstract final class SubsonicMapper {
  static String? _s(Object? v) => v == null ? null : '$v';
  static int? _i(Object? v) =>
      v is num ? v.toInt() : int.tryParse('${v ?? ''}');
  static double? _d(Object? v) => v is num ? v.toDouble() : null;

  /// A `List` field that servers may send as a single object.
  static List<Map<String, dynamic>> list(Object? value) => switch (value) {
    final List<dynamic> l => l.whereType<Map<String, dynamic>>().toList(),
    final Map<String, dynamic> m => [m],
    _ => const [],
  };

  static Artwork? _art(Object? coverArt) =>
      coverArt == null ? null : Artwork(itemId: '$coverArt');

  static List<NamedRef> _artists(Map<String, dynamic> json) {
    final many = list(json['artists']);
    if (many.isNotEmpty) {
      return [
        for (final a in many)
          if (a['id'] != null && a['name'] != null)
            NamedRef(id: '${a['id']}', name: '${a['name']}'),
      ];
    }
    final name = _s(json['artist']);
    if (name == null) return const [];
    return [NamedRef(id: _s(json['artistId']) ?? '', name: name)];
  }

  /// Maps a `child` (song).
  static Track track(Map<String, dynamic> json) {
    final gain = json['replayGain'];
    final seconds = _i(json['duration']);
    final genres = list(json['genres']);
    return Track(
      id: '${json['id']}',
      title: _s(json['title']) ?? '',
      artists: _artists(json),
      albumId: _s(json['albumId']),
      albumTitle: _s(json['album']),
      albumArtist: _s(json['displayAlbumArtist']) ?? _s(json['artist']),
      duration: seconds == null ? null : Duration(seconds: seconds),
      trackNumber: _i(json['track']),
      discNumber: _i(json['discNumber']),
      year: _i(json['year']),
      artwork: _art(json['coverArt']),
      container: _s(json['suffix']),
      isFavorite: json['starred'] != null,
      playCount: _i(json['playCount']) ?? 0,
      genres: genres.isNotEmpty
          ? [for (final g in genres) '${g['name']}']
          : [?_s(json['genre'])],
      trackGainDb: gain is Map ? _d(gain['trackGain']) : null,
      albumGainDb: gain is Map ? _d(gain['albumGain']) : null,
    );
  }

  /// Maps an `album` (ID3).
  static Album album(Map<String, dynamic> json) {
    final seconds = _i(json['duration']);
    return Album(
      id: '${json['id']}',
      title: _s(json['name']) ?? _s(json['title']) ?? '',
      artists: _artists(json),
      artistName: _s(json['artist']),
      year: _i(json['year']),
      trackCount: _i(json['songCount']),
      duration: seconds == null ? null : Duration(seconds: seconds),
      artwork: _art(json['coverArt']),
      dateAdded: DateTime.tryParse(_s(json['created']) ?? ''),
      genres: [?_s(json['genre'])],
      isFavorite: json['starred'] != null,
    );
  }

  /// Maps an `artist` (ID3).
  static Artist artist(Map<String, dynamic> json, {String? biography}) =>
      Artist(
        id: '${json['id']}',
        name: _s(json['name']) ?? '',
        artwork: _art(json['coverArt']),
        overview: biography,
        isFavorite: json['starred'] != null,
      );

  /// Maps a playlist.
  static Playlist playlist(Map<String, dynamic> json) {
    final seconds = _i(json['duration']);
    return Playlist(
      id: '${json['id']}',
      name: _s(json['name']) ?? '',
      trackCount: _i(json['songCount']),
      duration: seconds == null ? null : Duration(seconds: seconds),
      artwork: _art(json['coverArt']),
    );
  }

  /// Maps OpenSubsonic `structuredLyrics`, preferring synced lyrics.
  static Lyrics? structuredLyrics(Map<String, dynamic> json) {
    final all = list(
      list(json['lyricsList']).firstOrNull?['structuredLyrics'] ??
          json['structuredLyrics'],
    );
    if (all.isEmpty) return null;
    final chosen =
        all.where((l) => l['synced'] == true).firstOrNull ?? all.first;
    final synced = chosen['synced'] == true;
    final offset = _i(chosen['offset']) ?? 0;
    final lines = [
      for (final line in list(chosen['line']))
        LyricLine(
          text: _s(line['value']) ?? '',
          start: synced && _i(line['start']) != null
              ? Duration(milliseconds: _i(line['start'])! + offset)
              : null,
        ),
    ];
    final lyrics = Lyrics(lines: lines, synced: synced);
    return lyrics.isEmpty ? null : lyrics;
  }
}
