import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/core/utils/parallel.dart';
import 'package:melody/data/repositories/catalog_cache.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:meta/meta.dart';

/// A value that may come from the cache while the source is refreshed.
@immutable
class Loaded<T> {
  /// Creates a [Loaded].
  const Loaded(this.value, {this.fromCache = false, this.refreshFailure});

  /// The data to show.
  final T value;

  /// Whether [value] is the cached copy.
  final bool fromCache;

  /// Why refreshing failed, when the cached copy is still shown.
  final Failure? refreshFailure;
}

/// Library of one account: cache first, then the source.
class LibraryRepository {
  /// Creates the repository of [accountId].
  LibraryRepository({
    required this.source,
    required this.accountId,
    required this._cache,
    List<Track> Function()? downloaded,
  }) : _downloaded = downloaded ?? _none;

  static List<Track> _none() => const [];

  /// Downloaded tracks: what the library shows when the server cannot be
  /// reached and nothing was cached (albums never opened online).
  final List<Track> Function() _downloaded;

  /// The backend.
  final MusicSource source;

  /// Account whose cache is used.
  final String accountId;

  final CatalogCache _cache;

  Stream<Loaded<T>> _swr<T>({
    required Future<T?> Function() cached,
    required Future<Result<T>> Function() remote,
    required Future<void> Function(T value) save,
    T? Function()? offline,
  }) async* {
    T? stale;
    try {
      stale = await cached();
    } on Object {
      stale = null;
    }
    if (stale != null) yield Loaded(stale, fromCache: true);
    final fresh = await remote();
    switch (fresh) {
      case Ok(:final value):
        try {
          await save(value);
        } on Object {
          // A broken cache must never hide fresh data.
        }
        yield Loaded(value);
      case Err(:final failure):
        stale ??= offline?.call();
        if (stale == null) throw failure;
        yield Loaded(stale, fromCache: true, refreshFailure: failure);
    }
  }

  Stream<Loaded<List<T>>> _list<T>(
    String key,
    CacheKind<T> kind,
    Future<Result<List<T>>> Function() remote, {
    List<T> Function()? offline,
  }) => _swr(
    cached: () async {
      final items = await _cache.readList(accountId, key, kind);
      return items.isEmpty ? null : items;
    },
    remote: remote,
    save: (items) => _cache.writeList(accountId, key, kind, items),
    offline: offline == null
        ? null
        : () {
            final items = offline();
            return items.isEmpty ? null : items;
          },
  );

  /// Albums of the downloaded tracks, newest download first.
  List<Album> _downloadedAlbums() {
    final albums = <String, Album>{};
    for (final t in _downloaded()) {
      final id = t.albumId;
      if (id == null || albums.containsKey(id)) continue;
      albums[id] = Album(
        id: id,
        title: t.albumTitle ?? '',
        artistName: t.albumArtist ?? t.artistLine,
        year: t.year,
        artwork: Artwork(itemId: id),
      );
    }
    return albums.values.toList();
  }

  List<Track> _downloadedTracks(TrackQuery query) => [
    for (final t in _downloaded())
      if ((query.albumId == null || t.albumId == query.albumId) &&
          (query.artistId == null ||
              t.artists.any((a) => a.id == query.artistId)) &&
          (!query.favoritesOnly || t.isFavorite) &&
          query.playlistId == null)
        t,
  ];

  Future<Result<List<T>>> _more<T>(
    String key,
    CacheKind<T> kind,
    Future<Result<List<T>>> Function() remote,
  ) async {
    final result = await remote();
    if (result case Ok(:final value)) {
      try {
        await _cache.writeList(accountId, key, kind, value, append: true);
      } on Object {
        // Ignored: paging works without the cache.
      }
    }
    return result;
  }

  /// First page of an album listing.
  Stream<Loaded<List<Album>>> albums(AlbumQuery query) => _list(
    query.cacheKey,
    CacheKind.album,
    () => source.albums(query),
    offline: _downloadedAlbums,
  );

  /// A later page of an album listing.
  Future<Result<List<Album>>> moreAlbums(AlbumQuery query) =>
      _more(query.cacheKey, CacheKind.album, () => source.albums(query));

  /// First page of the artist listing.
  Stream<Loaded<List<Artist>>> artists({int limit = 100}) =>
      _list('artists', CacheKind.artist, () => source.artists(limit: limit));

  /// A later page of the artist listing.
  Future<Result<List<Artist>>> moreArtists(int offset, {int limit = 100}) =>
      _more(
        'artists',
        CacheKind.artist,
        () => source.artists(offset: offset, limit: limit),
      );

  /// First page of a track listing.
  Stream<Loaded<List<Track>>> tracks(TrackQuery query) => _list(
    query.cacheKey,
    CacheKind.track,
    () => source.tracks(query),
    offline: () => _downloadedTracks(query),
  );

  /// A later page of a track listing.
  Future<Result<List<Track>>> moreTracks(TrackQuery query) =>
      _more(query.cacheKey, CacheKind.track, () => source.tracks(query));

  /// All playlists.
  Stream<Loaded<List<Playlist>>> playlists() =>
      _list('playlists', CacheKind.playlist, source.playlists);

  /// All genres.
  Stream<Loaded<List<Genre>>> genres() =>
      _list('genres', CacheKind.genre, source.genres);

  /// An album with its tracks.
  Stream<Loaded<AlbumDetail>> album(String id) => _swr(
    cached: () => _cache.readItem(accountId, CacheKind.albumDetail, id),
    remote: () => source.album(id),
    save: (d) => _cache.writeItem(accountId, CacheKind.albumDetail, d),
    offline: () {
      final tracks =
          [
            for (final t in _downloaded())
              if (t.albumId == id) t,
          ]..sort(
            (a, b) => ((a.discNumber ?? 1) * 1000 + (a.trackNumber ?? 0))
                .compareTo((b.discNumber ?? 1) * 1000 + (b.trackNumber ?? 0)),
          );
      if (tracks.isEmpty) return null;
      final first = tracks.first;
      return AlbumDetail(
        album: Album(
          id: id,
          title: first.albumTitle ?? '',
          artistName: first.albumArtist ?? first.artistLine,
          year: first.year,
          trackCount: tracks.length,
          artwork: Artwork(itemId: id),
        ),
        tracks: tracks,
      );
    },
  );

  /// An artist with albums and popular tracks.
  Stream<Loaded<ArtistDetail>> artist(String id) => _swr(
    cached: () => _cache.readItem(accountId, CacheKind.artistDetail, id),
    remote: () => source.artist(id),
    save: (d) => _cache.writeItem(accountId, CacheKind.artistDetail, d),
  );

  /// Searches the source; falls back to the cache when it is unreachable.
  Future<Result<Loaded<SearchResult>>> search(
    String query, {
    int limit = 20,
  }) async {
    final remote = await source.search(query, limit: limit);
    switch (remote) {
      case Ok(:final value):
        return Ok(Loaded(value));
      case Err(:final failure):
        if (failure is! NetworkFailure && failure is! TimeoutFailure) {
          return Err(failure);
        }
        try {
          final (artists, albums, tracks, playlists) = await waitFour(
            _cache.search(accountId, CacheKind.artist, query, limit: limit),
            _cache.search(accountId, CacheKind.album, query, limit: limit),
            _cache.search(accountId, CacheKind.track, query, limit: limit),
            _cache.search(accountId, CacheKind.playlist, query, limit: limit),
          );
          return Ok(
            Loaded(
              SearchResult(
                artists: artists,
                albums: albums,
                tracks: tracks,
                playlists: playlists,
              ),
              fromCache: true,
              refreshFailure: failure,
            ),
          );
        } on Object {
          return Err(failure);
        }
    }
  }

  /// Marks or unmarks an album as favourite, updating the cache.
  Future<Result<void>> setAlbumFavorite(
    String albumId, {
    required bool value,
  }) async {
    final result = await source.setFavorite(albumId, value: value);
    if (result.isOk) {
      try {
        await _cache.updateItem(
          accountId,
          CacheKind.albumDetail,
          albumId,
          (d) => d.copyWith(album: d.album.copyWith(isFavorite: value)),
        );
      } on Object {
        // The next refresh corrects the cache.
      }
    }
    return result;
  }
}
