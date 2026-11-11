import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/core/network/failure_mapper.dart';
import 'package:melody/core/utils/parallel.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_api.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_dtos.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_mapper.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/domain/repositories/music_source.dart';

/// [MusicSource] backed by a Jellyfin server.
class JellyfinMusicSource implements MusicSource {
  /// Creates a source for [userId], optionally limited to [libraryId].
  JellyfinMusicSource({
    required this._api,
    required this.userId,
    this.libraryId,
  });

  final JellyfinApi _api;

  /// Signed-in user.
  final String userId;

  /// Library every listing is restricted to; `null` means all of them.
  final String? libraryId;

  static const _itemFields = 'DateCreated,Genres,ChildCount,NormalizationGain';

  @override
  SourceCapabilities get capabilities => const SourceCapabilities(
    favorites: true,
    playlists: true,
    editablePlaylists: true,
    lyrics: true,
    instantMix: true,
    transcoding: true,
    genres: true,
    multipleLibraries: true,
    playbackReporting: true,
  );

  @override
  Map<String, String> get requestHeaders => {
    'Authorization': _api.authorizationHeader,
  };

  Future<Result<T>> _guard<T>(Future<T> Function() body) =>
      Result.guard(body, onError: mapNetworkError);

  Future<ItemsResultDto> _items(Map<String, Object?> query) async =>
      ItemsResultDto.fromJson(
        await _api.getObject('Items', {
          'userId': userId,
          'Recursive': true,
          'Fields': _itemFields,
          'EnableImageTypes': 'Primary',
          'EnableTotalRecordCount': false,
          ...query,
        }),
      );

  static (String, String) _albumOrder(AlbumSort sort) => switch (sort) {
    AlbumSort.name => ('SortName', 'Ascending'),
    AlbumSort.artist => ('AlbumArtist,SortName', 'Ascending'),
    AlbumSort.year => ('ProductionYear,SortName', 'Descending'),
    AlbumSort.dateAdded => ('DateCreated,SortName', 'Descending'),
    AlbumSort.random => ('Random', 'Ascending'),
  };

  static (String, String) _trackOrder(TrackSort sort) => switch (sort) {
    TrackSort.name || TrackSort.natural => ('SortName', 'Ascending'),
    TrackSort.albumOrder => (
      'ParentIndexNumber,IndexNumber,SortName',
      'Ascending',
    ),
    TrackSort.dateAdded => ('DateCreated,SortName', 'Descending'),
    TrackSort.mostPlayed => ('PlayCount,SortName', 'Descending'),
    TrackSort.recentlyPlayed => ('DatePlayed,SortName', 'Descending'),
  };

  Future<List<Album>> _albums(AlbumQuery query) async {
    final (sortBy, sortOrder) = _albumOrder(query.sort);
    final page = await _items({
      'IncludeItemTypes': 'MusicAlbum',
      'ParentId': libraryId,
      'AlbumArtistIds': query.artistId,
      'GenreIds': query.genreId,
      'SortBy': sortBy,
      'SortOrder': sortOrder,
      'StartIndex': query.offset,
      'Limit': query.limit,
    });
    return JellyfinMapper.items(page, JellyfinMapper.album);
  }

  Future<List<Track>> _tracks(TrackQuery query) async {
    final playlistId = query.playlistId;
    if (playlistId != null) {
      final json = await _api.getObject('Playlists/$playlistId/Items', {
        'userId': userId,
        'Fields': _itemFields,
        'StartIndex': query.offset,
        'Limit': query.limit,
      });
      return JellyfinMapper.items(
        ItemsResultDto.fromJson(json),
        JellyfinMapper.track,
      );
    }
    final (sortBy, sortOrder) = _trackOrder(query.sort);
    final played =
        query.sort == TrackSort.mostPlayed ||
        query.sort == TrackSort.recentlyPlayed;
    final filters = [
      if (query.favoritesOnly) 'IsFavorite',
      if (played) 'IsPlayed',
    ];
    final page = await _items({
      'IncludeItemTypes': 'Audio',
      'ParentId': query.albumId ?? libraryId,
      'ArtistIds': query.artistId,
      'GenreIds': query.genreId,
      'Filters': filters.isEmpty ? null : filters.join(','),
      'SortBy': sortBy,
      'SortOrder': sortOrder,
      'StartIndex': query.offset,
      'Limit': query.limit,
    });
    return JellyfinMapper.items(page, JellyfinMapper.track);
  }

  Future<BaseItemDto> _item(String id, {String? fields}) async {
    final page = await _items({
      'Ids': id,
      'Recursive': null,
      'Fields': fields ?? _itemFields,
    });
    final items = page.items;
    if (items == null || items.isEmpty) throw const NotFoundFailure();
    return items.first;
  }

  @override
  Future<Result<List<MusicLibrary>>> libraries() => _guard(() async {
    final json = await _api.getObject('Users/$userId/Views');
    final views = ItemsResultDto.fromJson(json).items ?? const [];
    return [
      for (final view in views)
        if (view.id != null && view.collectionType?.toLowerCase() == 'music')
          JellyfinMapper.library(view),
    ];
  });

  @override
  Future<Result<List<Album>>> albums(AlbumQuery query) =>
      _guard(() => _albums(query));

  @override
  Future<Result<AlbumDetail>> album(String id) => _guard(() async {
    final (item, tracks) = await waitBoth(
      _item(id),
      _tracks(TrackQuery(sort: TrackSort.albumOrder, albumId: id, limit: 1000)),
    );
    return AlbumDetail(album: JellyfinMapper.album(item), tracks: tracks);
  });

  @override
  Future<Result<List<Artist>>> artists({int offset = 0, int limit = 100}) =>
      _guard(() async {
        final json = await _api.getObject('Artists/AlbumArtists', {
          'userId': userId,
          'ParentId': libraryId,
          'SortBy': 'SortName',
          'SortOrder': 'Ascending',
          'EnableImageTypes': 'Primary',
          'EnableTotalRecordCount': false,
          'StartIndex': offset,
          'Limit': limit,
        });
        return JellyfinMapper.items(
          ItemsResultDto.fromJson(json),
          JellyfinMapper.artist,
        );
      });

  @override
  Future<Result<ArtistDetail>> artist(String id) => _guard(() async {
    final (item, albums, top) = await waitThree(
      _item(id, fields: 'Overview'),
      _albums(AlbumQuery(sort: AlbumSort.year, artistId: id, limit: 200)),
      _tracks(TrackQuery(sort: TrackSort.mostPlayed, artistId: id, limit: 10)),
    );
    return ArtistDetail(
      artist: JellyfinMapper.artist(item),
      albums: albums,
      topTracks: top,
    );
  });

  @override
  Future<Result<List<Track>>> tracks(TrackQuery query) =>
      _guard(() => _tracks(query));

  @override
  Future<Result<SearchResult>> search(String query, {int limit = 20}) =>
      _guard(() async {
        Future<ItemsResultDto> find(String types) => _items({
          'SearchTerm': query,
          'IncludeItemTypes': types,
          'ParentId': types == 'Playlist' ? null : libraryId,
          'Limit': limit,
        });
        final artistsJson = _api.getObject('Artists', {
          'userId': userId,
          'SearchTerm': query,
          'ParentId': libraryId,
          'EnableImageTypes': 'Primary',
          'EnableTotalRecordCount': false,
          'Limit': limit,
        });
        final (artists, albums, tracks, playlists) = await waitFour(
          artistsJson,
          find('MusicAlbum'),
          find('Audio'),
          find('Playlist'),
        );
        return SearchResult(
          artists: JellyfinMapper.items(
            ItemsResultDto.fromJson(artists),
            JellyfinMapper.artist,
          ),
          albums: JellyfinMapper.items(albums, JellyfinMapper.album),
          tracks: JellyfinMapper.items(tracks, JellyfinMapper.track),
          playlists: JellyfinMapper.items(playlists, JellyfinMapper.playlist),
        );
      });

  @override
  Future<Result<List<Playlist>>> playlists() => _guard(() async {
    final page = await _items({
      'IncludeItemTypes': 'Playlist',
      'SortBy': 'SortName',
      'SortOrder': 'Ascending',
    });
    return JellyfinMapper.items(page, JellyfinMapper.playlist);
  });

  @override
  Future<Result<List<Genre>>> genres() => _guard(() async {
    final json = await _api.getObject('MusicGenres', {
      'userId': userId,
      'ParentId': libraryId,
      'SortBy': 'SortName',
      'SortOrder': 'Ascending',
      'EnableImageTypes': 'Primary',
      'EnableTotalRecordCount': false,
    });
    return JellyfinMapper.items(
      ItemsResultDto.fromJson(json),
      JellyfinMapper.genre,
    );
  });

  @override
  Future<Result<void>> setFavorite(String id, {required bool value}) =>
      _guard(() async {
        final path = 'Users/$userId/FavoriteItems/$id';
        if (value) {
          await _api.post(path);
        } else {
          await _api.delete(path);
        }
      });

  @override
  Future<Result<List<Track>>> favorites({int offset = 0, int limit = 100}) =>
      tracks(TrackQuery(favoritesOnly: true, offset: offset, limit: limit));

  @override
  Future<Result<List<Track>>> randomTracks({int count = 50, String? genreId}) =>
      _guard(() async {
        final page = await _items({
          'IncludeItemTypes': 'Audio',
          'ParentId': libraryId,
          'GenreIds': genreId,
          'SortBy': 'Random',
          'Limit': count,
        });
        return JellyfinMapper.items(page, JellyfinMapper.track);
      });

  @override
  Future<Result<List<Track>>> similarTracks(String trackId, {int limit = 50}) =>
      _guard(() async {
        final json = await _api.getObject('Items/$trackId/InstantMix', {
          'userId': userId,
          'Fields': _itemFields,
          'Limit': limit,
        });
        return JellyfinMapper.items(
          ItemsResultDto.fromJson(json),
          JellyfinMapper.track,
        );
      });

  @override
  Future<Result<Playlist>> createPlaylist(String name, List<String> trackIds) =>
      _guard(() async {
        final json = await _api.post(
          'Playlists',
          body: {
            'Name': name,
            'Ids': trackIds,
            'UserId': userId,
            'MediaType': 'Audio',
          },
        );
        final id = json['Id'];
        if (id is! String) throw const ParsingFailure();
        return Playlist(id: id, name: name, trackCount: trackIds.length);
      });

  @override
  Future<Result<void>> addToPlaylist(
    String playlistId,
    List<String> trackIds,
  ) => _guard(
    () => _api.post(
      'Playlists/$playlistId/Items',
      query: {'ids': trackIds.join(','), 'userId': userId},
    ),
  );

  @override
  Future<Result<void>> removeFromPlaylist(
    String playlistId,
    List<String> entryIds,
  ) => _guard(
    () => _api.delete('Playlists/$playlistId/Items', {
      'entryIds': entryIds.join(','),
    }),
  );

  @override
  Future<Result<void>> movePlaylistItem(
    String playlistId,
    String entryId,
    int newIndex,
  ) => _guard(
    () => _api.post('Playlists/$playlistId/Items/$entryId/Move/$newIndex'),
  );

  @override
  Future<Result<void>> renamePlaylist(String playlistId, String name) =>
      _guard(() => _api.post('Playlists/$playlistId', body: {'Name': name}));

  @override
  Future<Result<void>> deletePlaylist(String playlistId) =>
      _guard(() => _api.delete('Items/$playlistId'));

  @override
  Future<Result<Lyrics?>> lyrics(Track track) => _guard(() async {
    final Map<String, dynamic> json;
    try {
      json = await _api.getObject('Audio/${track.id}/Lyrics');
    } on Object catch (error) {
      if (mapNetworkError(error) is NotFoundFailure) return null;
      rethrow;
    }
    final raw = json['Lyrics'];
    if (raw is! List) return null;
    final lines = <LyricLine>[
      for (final line in raw.whereType<Map<String, dynamic>>())
        LyricLine(
          text: (line['Text'] as String? ?? '').trim(),
          start: switch (line['Start']) {
            final int ticks => JellyfinMapper.duration(ticks) ?? Duration.zero,
            _ => null,
          },
        ),
    ];
    final synced = lines.isNotEmpty && lines.every((l) => l.start != null);
    final lyrics = Lyrics(lines: lines, synced: synced);
    return lyrics.isEmpty ? null : lyrics;
  });

  @override
  Future<Result<void>> reportPlayback(PlaybackReport report) =>
      _guard(() async {
        final ticks =
            report.position.inMicroseconds * JellyfinMapper.ticksPerMicrosecond;
        final body = {
          'ItemId': report.trackId,
          'PositionTicks': ticks,
          'PlaySessionId': report.sessionId,
          'IsPaused': report.isPaused,
          'CanSeek': true,
          'PlayMethod': 'DirectStream',
        };
        final path = switch (report.kind) {
          PlaybackEventKind.start => 'Sessions/Playing',
          PlaybackEventKind.progress => 'Sessions/Playing/Progress',
          PlaybackEventKind.stopped => 'Sessions/Playing/Stopped',
        };
        await _api.post(path, body: body);
      });

  @override
  Uri streamUri(Track track, [StreamOptions options = const StreamOptions()]) {
    final maxBitrate = options.maxBitrateKbps;
    // Containers played as they are; anything else is converted.
    final (container, codec, transcodeTo, protocol) = switch (options.format) {
      StreamFormat.original => (
        'opus,webm|opus,mp3,aac,m4a|aac,m4b|aac,flac,wav,ogg',
        'aac',
        'ts',
        'hls',
      ),
      StreamFormat.opus => ('ogg|opus,opus,webm|opus', 'opus', 'ogg', 'http'),
      StreamFormat.aac => ('aac,m4a|aac', 'aac', 'aac', 'http'),
      StreamFormat.mp3 => ('mp3', 'mp3', 'mp3', 'http'),
    };
    return _api.resolve('Audio/${track.id}/universal', {
      'UserId': userId,
      'DeviceId': _api.identity.deviceId,
      'Container': container,
      'TranscodingContainer': transcodeTo,
      'TranscodingProtocol': protocol,
      'AudioCodec': codec,
      if (maxBitrate != null) 'MaxStreamingBitrate': '${maxBitrate * 1000}',
      'api_key': ?_api.token,
    });
  }

  @override
  Uri? artworkUri(Artwork? artwork, {int size = 300}) {
    if (artwork == null) return null;
    return _api.resolve('Items/${artwork.itemId}/Images/Primary', {
      'fillWidth': '$size',
      'fillHeight': '$size',
      'quality': '90',
      'tag': ?artwork.tag,
    });
  }

  /// Releases the underlying connections.
  void close() => _api.close();
}
