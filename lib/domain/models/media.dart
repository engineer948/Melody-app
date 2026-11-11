import 'package:freezed_annotation/freezed_annotation.dart';

part 'media.freezed.dart';
part 'media.g.dart';

/// Pointer to a cover image stored on a source.
@freezed
abstract class Artwork with _$Artwork {
  /// Creates an [Artwork].
  const factory Artwork({
    required String itemId,
    String? tag,
    String? blurHash,
  }) = _Artwork;

  /// Restores an [Artwork] from the cache.
  factory Artwork.fromJson(Map<String, dynamic> json) =>
      _$ArtworkFromJson(json);
}

/// Lightweight reference to another item, e.g. a track's artist.
@freezed
abstract class NamedRef with _$NamedRef {
  /// Creates a [NamedRef].
  const factory NamedRef({required String id, required String name}) =
      _NamedRef;

  /// Restores a [NamedRef] from the cache.
  factory NamedRef.fromJson(Map<String, dynamic> json) =>
      _$NamedRefFromJson(json);
}

/// A playable song.
@freezed
abstract class Track with _$Track {
  /// Creates a [Track].
  const factory Track({
    required String id,
    required String title,
    @Default(<NamedRef>[]) List<NamedRef> artists,
    String? albumId,
    String? albumTitle,
    String? albumArtist,
    Duration? duration,
    int? trackNumber,
    int? discNumber,
    int? year,
    Artwork? artwork,
    String? container,
    @Default(false) bool isFavorite,
    @Default(0) int playCount,

    /// ReplayGain-style track gain in dB, when the source knows it.
    double? trackGainDb,

    /// Gain of the whole album in dB, when known.
    double? albumGainDb,

    /// Id of this entry inside a playlist (needed to remove or move it).
    String? playlistItemId,
  }) = _Track;

  const Track._();

  /// Restores a [Track] from the cache.
  factory Track.fromJson(Map<String, dynamic> json) => _$TrackFromJson(json);

  /// Artist names joined for display; falls back to the album artist.
  String get artistLine => artists.isEmpty
      ? (albumArtist ?? '')
      : artists.map((a) => a.name).join(', ');
}

/// A release grouping several tracks.
@freezed
abstract class Album with _$Album {
  /// Creates an [Album].
  const factory Album({
    required String id,
    required String title,
    @Default(<NamedRef>[]) List<NamedRef> artists,
    String? artistName,
    int? year,
    int? trackCount,
    Duration? duration,
    Artwork? artwork,
    DateTime? dateAdded,
    @Default(<String>[]) List<String> genres,
    @Default(false) bool isFavorite,

    /// Album gain in dB, when the source knows it.
    double? gainDb,
  }) = _Album;

  const Album._();

  /// Restores an [Album] from the cache.
  factory Album.fromJson(Map<String, dynamic> json) => _$AlbumFromJson(json);

  /// Artist name for display.
  String get artistLine => artistName ?? artists.map((a) => a.name).join(', ');
}

/// A performer or band.
@freezed
abstract class Artist with _$Artist {
  /// Creates an [Artist].
  const factory Artist({
    required String id,
    required String name,
    Artwork? artwork,
    String? overview,
    @Default(false) bool isFavorite,
  }) = _Artist;

  /// Restores an [Artist] from the cache.
  factory Artist.fromJson(Map<String, dynamic> json) => _$ArtistFromJson(json);
}

/// Everything shown on an artist's page.
@freezed
abstract class ArtistDetail with _$ArtistDetail {
  /// Creates an [ArtistDetail].
  const factory ArtistDetail({
    required Artist artist,
    @Default(<Album>[]) List<Album> albums,
    @Default(<Track>[]) List<Track> topTracks,
  }) = _ArtistDetail;

  /// Restores an [ArtistDetail] from the cache.
  factory ArtistDetail.fromJson(Map<String, dynamic> json) =>
      _$ArtistDetailFromJson(json);
}

/// An album together with its tracks.
@freezed
abstract class AlbumDetail with _$AlbumDetail {
  /// Creates an [AlbumDetail].
  const factory AlbumDetail({
    required Album album,
    @Default(<Track>[]) List<Track> tracks,
  }) = _AlbumDetail;

  /// Restores an [AlbumDetail] from the cache.
  factory AlbumDetail.fromJson(Map<String, dynamic> json) =>
      _$AlbumDetailFromJson(json);
}

/// Playlist together with its tracks, for the playlist page.
typedef PlaylistTracks = ({Playlist playlist, List<Track> tracks});

/// A user-curated list of tracks.
@freezed
abstract class Playlist with _$Playlist {
  /// Creates a [Playlist].
  const factory Playlist({
    required String id,
    required String name,
    int? trackCount,
    Duration? duration,
    Artwork? artwork,
  }) = _Playlist;

  /// Restores a [Playlist] from the cache.
  factory Playlist.fromJson(Map<String, dynamic> json) =>
      _$PlaylistFromJson(json);
}

/// A musical genre.
@freezed
abstract class Genre with _$Genre {
  /// Creates a [Genre].
  const factory Genre({
    required String id,
    required String name,
    Artwork? artwork,
  }) = _Genre;

  /// Restores a [Genre] from the cache.
  factory Genre.fromJson(Map<String, dynamic> json) => _$GenreFromJson(json);
}

/// Grouped results of a search.
@freezed
abstract class SearchResult with _$SearchResult {
  /// Creates a [SearchResult].
  const factory SearchResult({
    @Default(<Artist>[]) List<Artist> artists,
    @Default(<Album>[]) List<Album> albums,
    @Default(<Track>[]) List<Track> tracks,
    @Default(<Playlist>[]) List<Playlist> playlists,
  }) = _SearchResult;

  const SearchResult._();

  /// Whether nothing matched.
  bool get isEmpty =>
      artists.isEmpty && albums.isEmpty && tracks.isEmpty && playlists.isEmpty;
}

/// One line of song text; [start] is `null` for unsynchronised lyrics.
@freezed
abstract class LyricLine with _$LyricLine {
  /// Creates a [LyricLine].
  const factory LyricLine({required String text, Duration? start}) = _LyricLine;

  /// Restores a [LyricLine] from the cache.
  factory LyricLine.fromJson(Map<String, dynamic> json) =>
      _$LyricLineFromJson(json);
}

/// Where lyrics came from.
enum LyricsOrigin {
  /// The music server.
  server,

  /// The public LRCLIB database.
  lrclib,
}

/// Cached lyrics of one track.
@freezed
abstract class TrackLyrics with _$TrackLyrics {
  /// Creates a cache entry.
  const factory TrackLyrics({required String trackId, required Lyrics lyrics}) =
      _TrackLyrics;

  /// Restores an entry from the cache.
  factory TrackLyrics.fromJson(Map<String, dynamic> json) =>
      _$TrackLyricsFromJson(json);
}

/// Lyrics of a track.
@freezed
abstract class Lyrics with _$Lyrics {
  /// Creates [Lyrics].
  const factory Lyrics({
    @Default(<LyricLine>[]) List<LyricLine> lines,
    @Default(false) bool synced,
    @Default(LyricsOrigin.server) LyricsOrigin origin,
  }) = _Lyrics;

  const Lyrics._();

  /// Restores [Lyrics] from the cache.
  factory Lyrics.fromJson(Map<String, dynamic> json) => _$LyricsFromJson(json);

  /// Whether there is nothing to show.
  bool get isEmpty => lines.every((l) => l.text.trim().isEmpty);

  /// Index of the line sung at [position], or -1 before the first one.
  int lineAt(Duration position) {
    if (!synced) return -1;
    var result = -1;
    for (var i = 0; i < lines.length; i++) {
      final start = lines[i].start;
      if (start == null || start > position) break;
      result = i;
    }
    return result;
  }
}
