import 'package:melody/core/errors/result.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/models/server.dart';
import 'package:meta/meta.dart';

/// Optional features of a [MusicSource]; the UI hides what is unsupported.
@immutable
class SourceCapabilities {
  /// Creates a capability set.
  const SourceCapabilities({
    this.favorites = false,
    this.playlists = false,
    this.editablePlaylists = false,
    this.lyrics = false,
    this.instantMix = false,
    this.transcoding = false,
    this.playbackReporting = false,
    this.genres = false,
    this.multipleLibraries = false,
  });

  /// Items can be marked as favourite.
  final bool favorites;

  /// Playlists can be listed.
  final bool playlists;

  /// Playlists can be created and changed.
  final bool editablePlaylists;

  /// Lyrics can be fetched.
  final bool lyrics;

  /// Similar tracks can be requested.
  final bool instantMix;

  /// The source can re-encode streams.
  final bool transcoding;

  /// Playback can be reported back.
  final bool playbackReporting;

  /// Genres can be browsed.
  final bool genres;

  /// The source may hold several music libraries.
  final bool multipleLibraries;
}

/// Order of an album listing.
enum AlbumSort {
  /// Alphabetical by title.
  name,

  /// Alphabetical by album artist.
  artist,

  /// Newest release first.
  year,

  /// Most recently added first.
  dateAdded,

  /// Shuffled by the source.
  random,
}

/// Order of a track listing.
enum TrackSort {
  /// Alphabetical by title.
  name,

  /// Disc and track number, for album pages.
  albumOrder,

  /// Most recently added first.
  dateAdded,

  /// Most played first.
  mostPlayed,

  /// Most recently played first.
  recentlyPlayed,

  /// Order defined by the container, e.g. a playlist.
  natural,
}

/// Filter and paging of an album listing.
@immutable
class AlbumQuery {
  /// Creates an [AlbumQuery].
  const AlbumQuery({
    this.sort = AlbumSort.name,
    this.artistId,
    this.genreId,
    this.offset = 0,
    this.limit = 60,
  });

  /// Requested order.
  final AlbumSort sort;

  /// Restricts to albums of this album artist.
  final String? artistId;

  /// Restricts to albums of this genre.
  final String? genreId;

  /// Index of the first album.
  final int offset;

  /// Maximum number of albums.
  final int limit;

  /// Copy with different paging.
  AlbumQuery page(int offset, int limit) => AlbumQuery(
    sort: sort,
    artistId: artistId,
    genreId: genreId,
    offset: offset,
    limit: limit,
  );

  /// Stable identifier of the listing, ignoring paging.
  String get cacheKey =>
      'albums:${sort.name}:${artistId ?? ''}:${genreId ?? ''}';

  @override
  bool operator ==(Object other) =>
      other is AlbumQuery &&
      other.sort == sort &&
      other.artistId == artistId &&
      other.genreId == genreId &&
      other.offset == offset &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(sort, artistId, genreId, offset, limit);
}

/// Filter and paging of a track listing.
@immutable
class TrackQuery {
  /// Creates a [TrackQuery].
  const TrackQuery({
    this.sort = TrackSort.name,
    this.albumId,
    this.artistId,
    this.genreId,
    this.playlistId,
    this.favoritesOnly = false,
    this.offset = 0,
    this.limit = 100,
  });

  /// Requested order.
  final TrackSort sort;

  /// Restricts to tracks of this album.
  final String? albumId;

  /// Restricts to tracks of this artist.
  final String? artistId;

  /// Restricts to tracks of this genre.
  final String? genreId;

  /// Restricts to tracks of this playlist.
  final String? playlistId;

  /// Restricts to favourites.
  final bool favoritesOnly;

  /// Index of the first track.
  final int offset;

  /// Maximum number of tracks.
  final int limit;

  /// Copy with different paging.
  TrackQuery page(int offset, int limit) => TrackQuery(
    sort: sort,
    albumId: albumId,
    artistId: artistId,
    genreId: genreId,
    playlistId: playlistId,
    favoritesOnly: favoritesOnly,
    offset: offset,
    limit: limit,
  );

  /// Stable identifier of the listing, ignoring paging.
  String get cacheKey =>
      'tracks:${sort.name}:${albumId ?? ''}:${artistId ?? ''}:'
      '${genreId ?? ''}:${playlistId ?? ''}:$favoritesOnly';

  @override
  bool operator ==(Object other) =>
      other is TrackQuery &&
      other.sort == sort &&
      other.albumId == albumId &&
      other.artistId == artistId &&
      other.genreId == genreId &&
      other.playlistId == playlistId &&
      other.favoritesOnly == favoritesOnly &&
      other.offset == offset &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(
    sort,
    albumId,
    artistId,
    genreId,
    playlistId,
    favoritesOnly,
    offset,
    limit,
  );
}

/// Audio format a stream may be converted to.
enum StreamFormat {
  /// Keep the original file whenever possible.
  original,

  /// Opus in Ogg.
  opus,

  /// AAC.
  aac,

  /// MP3.
  mp3,
}

/// Quality wanted for a stream.
@immutable
class StreamOptions {
  /// Creates [StreamOptions].
  const StreamOptions({
    this.maxBitrateKbps,
    this.format = StreamFormat.original,
  });

  /// Upper bitrate limit; `null` keeps the original quality.
  final int? maxBitrateKbps;

  /// Wanted format.
  final StreamFormat format;

  /// Whether the stream is the untouched original file (cacheable).
  bool get isOriginal =>
      maxBitrateKbps == null && format == StreamFormat.original;

  @override
  bool operator ==(Object other) =>
      other is StreamOptions &&
      other.maxBitrateKbps == maxBitrateKbps &&
      other.format == format;

  @override
  int get hashCode => Object.hash(maxBitrateKbps, format);
}

/// Kind of playback report.
enum PlaybackEventKind {
  /// A track started.
  start,

  /// Periodic or pause/resume update.
  progress,

  /// A track ended or was left.
  stopped,
}

/// One playback report sent back to the source.
@immutable
class PlaybackReport {
  /// Creates a report.
  const PlaybackReport({
    required this.kind,
    required this.trackId,
    required this.position,
    required this.sessionId,
    this.isPaused = false,
  });

  /// Restores a report saved while offline.
  factory PlaybackReport.fromJson(Map<String, dynamic> json) => PlaybackReport(
    kind: PlaybackEventKind.values.byName(json['kind'] as String),
    trackId: json['trackId'] as String,
    position: Duration(milliseconds: json['positionMs'] as int),
    sessionId: json['sessionId'] as String,
    isPaused: json['isPaused'] as bool? ?? false,
  );

  /// What happened.
  final PlaybackEventKind kind;

  /// Track concerned.
  final String trackId;

  /// Position inside the track.
  final Duration position;

  /// Identifies one play of one track across its reports.
  final String sessionId;

  /// Whether playback is paused.
  final bool isPaused;

  /// Serialises the report for the offline queue.
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'trackId': trackId,
    'positionMs': position.inMilliseconds,
    'sessionId': sessionId,
    'isPaused': isPaused,
  };
}

/// A music backend. The UI and the player only ever talk to this interface.
abstract interface class MusicSource {
  /// What this source can do.
  SourceCapabilities get capabilities;

  /// Music libraries available to the signed-in user.
  Future<Result<List<MusicLibrary>>> libraries();

  /// Lists albums.
  Future<Result<List<Album>>> albums(AlbumQuery query);

  /// Loads one album with its tracks.
  Future<Result<AlbumDetail>> album(String id);

  /// Lists album artists.
  Future<Result<List<Artist>>> artists({int offset = 0, int limit = 100});

  /// Loads one artist with albums and popular tracks.
  Future<Result<ArtistDetail>> artist(String id);

  /// Lists tracks.
  Future<Result<List<Track>>> tracks(TrackQuery query);

  /// Searches artists, albums, tracks and playlists.
  Future<Result<SearchResult>> search(String query, {int limit = 20});

  /// Lists playlists.
  Future<Result<List<Playlist>>> playlists();

  /// Creates a playlist containing [trackIds].
  Future<Result<Playlist>> createPlaylist(String name, List<String> trackIds);

  /// Appends [trackIds] to a playlist.
  Future<Result<void>> addToPlaylist(String playlistId, List<String> trackIds);

  /// Removes entries (`Track.playlistItemId`) from a playlist.
  Future<Result<void>> removeFromPlaylist(
    String playlistId,
    List<String> entryIds,
  );

  /// Moves the entry [entryId] of a playlist to [newIndex].
  Future<Result<void>> movePlaylistItem(
    String playlistId,
    String entryId,
    int newIndex,
  );

  /// Renames a playlist.
  Future<Result<void>> renamePlaylist(String playlistId, String name);

  /// Deletes a playlist.
  Future<Result<void>> deletePlaylist(String playlistId);

  /// Lists genres.
  Future<Result<List<Genre>>> genres();

  /// Marks or unmarks an item as favourite.
  Future<Result<void>> setFavorite(String id, {required bool value});

  /// Lists favourite tracks.
  Future<Result<List<Track>>> favorites({int offset = 0, int limit = 100});

  /// Picks random tracks, optionally of one genre.
  Future<Result<List<Track>>> randomTracks({int count = 50, String? genreId});

  /// Tracks similar to [trackId] ("instant mix").
  Future<Result<List<Track>>> similarTracks(String trackId, {int limit = 50});

  /// Lyrics of [track], or `null` when there are none.
  Future<Result<Lyrics?>> lyrics(Track track);

  /// Address the player streams [track] from.
  Uri streamUri(Track track, [StreamOptions options = const StreamOptions()]);

  /// Address a complete file of [track] can be downloaded from.
  Uri downloadUri(Track track, [StreamOptions options = const StreamOptions()]);

  /// Address of a cover image scaled to roughly [size] pixels.
  Uri? artworkUri(Artwork? artwork, {int size = 300});

  /// Headers needed to fetch artwork and streams.
  Map<String, String> get requestHeaders;

  /// Tells the source what is being played (play counts, "recently played").
  Future<Result<void>> reportPlayback(PlaybackReport report);
}
