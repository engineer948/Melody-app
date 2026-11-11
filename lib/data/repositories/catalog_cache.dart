import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:melody/data/db/app_database.dart';
import 'package:melody/domain/models/media.dart';

// Generic descriptor, not an enumeration.
// ignore_for_file: use_enums

/// Describes how one model type is stored in the cache.
class CacheKind<T> {
  const CacheKind._(
    this.name, {
    required this.idOf,
    required this.nameOf,
    required this.toJson,
    required this.fromJson,
  });

  /// Discriminator stored in the database.
  final String name;

  /// Extracts the item id.
  final String Function(T item) idOf;

  /// Extracts the searchable name.
  final String Function(T item) nameOf;

  /// Serialises the item.
  final Map<String, dynamic> Function(T item) toJson;

  /// Restores the item.
  final T Function(Map<String, dynamic> json) fromJson;

  static String _albumId(Album a) => a.id;
  static String _albumName(Album a) => a.title;
  static Map<String, dynamic> _albumJson(Album a) => a.toJson();
  static String _artistId(Artist a) => a.id;
  static String _artistName(Artist a) => a.name;
  static Map<String, dynamic> _artistJson(Artist a) => a.toJson();
  static String _trackId(Track t) => t.id;
  static String _trackName(Track t) => t.title;
  static Map<String, dynamic> _trackJson(Track t) => t.toJson();
  static String _playlistId(Playlist p) => p.id;
  static String _playlistName(Playlist p) => p.name;
  static Map<String, dynamic> _playlistJson(Playlist p) => p.toJson();
  static String _genreId(Genre g) => g.id;
  static String _genreName(Genre g) => g.name;
  static Map<String, dynamic> _genreJson(Genre g) => g.toJson();
  static String _albumDetailId(AlbumDetail d) => d.album.id;
  static String _albumDetailName(AlbumDetail d) => d.album.title;
  static Map<String, dynamic> _albumDetailJson(AlbumDetail d) => d.toJson();
  static String _lyricsId(TrackLyrics l) => l.trackId;
  static String _lyricsName(TrackLyrics l) => '';
  static Map<String, dynamic> _lyricsJson(TrackLyrics l) => l.toJson();
  static String _artistDetailId(ArtistDetail d) => d.artist.id;
  static String _artistDetailName(ArtistDetail d) => d.artist.name;
  static Map<String, dynamic> _artistDetailJson(ArtistDetail d) => d.toJson();

  /// Albums.
  static const album = CacheKind<Album>._(
    'album',
    idOf: _albumId,
    nameOf: _albumName,
    toJson: _albumJson,
    fromJson: Album.fromJson,
  );

  /// Artists.
  static const artist = CacheKind<Artist>._(
    'artist',
    idOf: _artistId,
    nameOf: _artistName,
    toJson: _artistJson,
    fromJson: Artist.fromJson,
  );

  /// Tracks.
  static const track = CacheKind<Track>._(
    'track',
    idOf: _trackId,
    nameOf: _trackName,
    toJson: _trackJson,
    fromJson: Track.fromJson,
  );

  /// Playlists.
  static const playlist = CacheKind<Playlist>._(
    'playlist',
    idOf: _playlistId,
    nameOf: _playlistName,
    toJson: _playlistJson,
    fromJson: Playlist.fromJson,
  );

  /// Genres.
  static const genre = CacheKind<Genre>._(
    'genre',
    idOf: _genreId,
    nameOf: _genreName,
    toJson: _genreJson,
    fromJson: Genre.fromJson,
  );

  /// Album pages.
  static const albumDetail = CacheKind<AlbumDetail>._(
    'albumDetail',
    idOf: _albumDetailId,
    nameOf: _albumDetailName,
    toJson: _albumDetailJson,
    fromJson: AlbumDetail.fromJson,
  );

  /// Lyrics, keyed by track id.
  static const lyrics = CacheKind<TrackLyrics>._(
    'lyrics',
    idOf: _lyricsId,
    nameOf: _lyricsName,
    toJson: _lyricsJson,
    fromJson: TrackLyrics.fromJson,
  );

  /// Artist pages.
  static const artistDetail = CacheKind<ArtistDetail>._(
    'artistDetail',
    idOf: _artistDetailId,
    nameOf: _artistDetailName,
    toJson: _artistDetailJson,
    fromJson: ArtistDetail.fromJson,
  );
}

/// Offline copy of the library, kept separately for every account.
class CatalogCache {
  /// Creates a cache on top of [_db].
  CatalogCache(this._db);

  final AppDatabase _db;

  T? _decode<T>(CacheKind<T> kind, String payload) {
    try {
      return kind.fromJson(jsonDecode(payload) as Map<String, dynamic>);
    } on Object {
      return null; // Written by an incompatible version; treat as a miss.
    }
  }

  Future<void> _upsert<T>(String accountId, CacheKind<T> kind, List<T> items) {
    final now = DateTime.now();
    return _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.cachedItems, [
        for (final item in items)
          CachedItemsCompanion.insert(
            accountId: accountId,
            kind: kind.name,
            itemId: kind.idOf(item),
            name: kind.nameOf(item).toLowerCase(),
            payload: jsonEncode(kind.toJson(item)),
            updatedAt: now,
          ),
      ]);
    });
  }

  Future<List<String>> _listIds(String accountId, String key) async {
    final row =
        await (_db.select(_db.cachedLists)..where(
              (t) => t.accountId.equals(accountId) & t.listKey.equals(key),
            ))
            .getSingleOrNull();
    if (row == null) return const [];
    return (jsonDecode(row.itemIds) as List<dynamic>).cast<String>();
  }

  /// Stores one item.
  Future<void> writeItem<T>(String accountId, CacheKind<T> kind, T item) =>
      _upsert(accountId, kind, [item]);

  /// Reads one item, or `null` when it was never cached.
  Future<T?> readItem<T>(String accountId, CacheKind<T> kind, String id) async {
    final row =
        await (_db.select(_db.cachedItems)..where(
              (t) =>
                  t.accountId.equals(accountId) &
                  t.kind.equals(kind.name) &
                  t.itemId.equals(id),
            ))
            .getSingleOrNull();
    return row == null ? null : _decode(kind, row.payload);
  }

  /// Stores the listing [key] in the order of [items].
  ///
  /// With [append] the items are added after what is already stored.
  Future<void> writeList<T>(
    String accountId,
    String key,
    CacheKind<T> kind,
    List<T> items, {
    bool append = false,
  }) => _db.transaction(() async {
    await _upsert(accountId, kind, items);
    final ids = <String>{
      if (append) ...await _listIds(accountId, key),
      ...items.map(kind.idOf),
    }.toList();
    await _db
        .into(_db.cachedLists)
        .insertOnConflictUpdate(
          CachedListsCompanion.insert(
            accountId: accountId,
            listKey: key,
            itemIds: jsonEncode(ids),
            updatedAt: DateTime.now(),
          ),
        );
  });

  /// Reads the listing [key] in its stored order.
  Future<List<T>> readList<T>(
    String accountId,
    String key,
    CacheKind<T> kind,
  ) async {
    final ids = await _listIds(accountId, key);
    if (ids.isEmpty) return const [];
    final byId = <String, T>{};
    // SQLite limits the number of bound variables per statement.
    for (var start = 0; start < ids.length; start += 500) {
      final chunk = ids.skip(start).take(500).toList();
      final rows =
          await (_db.select(_db.cachedItems)..where(
                (t) =>
                    t.accountId.equals(accountId) &
                    t.kind.equals(kind.name) &
                    t.itemId.isIn(chunk),
              ))
              .get();
      for (final row in rows) {
        final item = _decode(kind, row.payload);
        if (item != null) byId[row.itemId] = item;
      }
    }
    return [for (final id in ids) ?byId[id]];
  }

  /// Finds cached items whose name contains [query].
  Future<List<T>> search<T>(
    String accountId,
    CacheKind<T> kind,
    String query, {
    int limit = 20,
  }) async {
    final escaped = query.toLowerCase().replaceAllMapped(
      RegExp(r'[\\%_]'),
      (m) => '\\${m[0]}',
    );
    final rows =
        await (_db.select(_db.cachedItems)
              ..where(
                (t) =>
                    t.accountId.equals(accountId) &
                    t.kind.equals(kind.name) &
                    t.name.like('%$escaped%', escapeChar: r'\'),
              )
              ..orderBy([(t) => OrderingTerm(expression: t.name)])
              ..limit(limit))
            .get();
    return [for (final row in rows) ?_decode(kind, row.payload)];
  }

  /// Applies [change] to a cached item, if present.
  Future<void> updateItem<T>(
    String accountId,
    CacheKind<T> kind,
    String id,
    T Function(T item) change,
  ) async {
    final item = await readItem(accountId, kind, id);
    if (item != null) await writeItem(accountId, kind, change(item));
  }

  /// Deletes everything cached for [accountId].
  Future<void> clearAccount(String accountId) => _db.transaction(() async {
    await (_db.delete(
      _db.cachedItems,
    )..where((t) => t.accountId.equals(accountId))).go();
    await (_db.delete(
      _db.cachedLists,
    )..where((t) => t.accountId.equals(accountId))).go();
  });
}
