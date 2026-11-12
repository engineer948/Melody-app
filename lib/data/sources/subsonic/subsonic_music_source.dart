import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/data/sources/subsonic/subsonic_api.dart';
import 'package:melody/data/sources/subsonic/subsonic_mapper.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/domain/repositories/music_source.dart';

/// [MusicSource] backed by a Subsonic / OpenSubsonic server (Navidrome,
/// Airsonic, Gonic, ...). Genres are identified by their name.
class SubsonicMusicSource implements MusicSource {
  /// Creates a source, optionally limited to the music folder [libraryId].
  SubsonicMusicSource({required this._api, this.libraryId});

  final SubsonicApi _api;

  /// Music folder every listing is restricted to; `null` means all.
  final String? libraryId;

  static const List<Map<String, dynamic>> Function(Object?) _m =
      SubsonicMapper.list;

  @override
  SourceCapabilities get capabilities => const SourceCapabilities(
    favorites: true,
    playlists: true,
    editablePlaylists: true,
    lyrics: true,
    instantMix: true,
    transcoding: true,
    playbackReporting: true,
    genres: true,
    multipleLibraries: true,
  );

  @override
  Map<String, String> get requestHeaders => const {};

  Future<Result<T>> _guard<T>(Future<T> Function() body) =>
      Result.guard(body, onError: mapSubsonicError);

  Future<Map<String, dynamic>> _get(
    String method, [
    Map<String, Object?> query = const {},
  ]) => _api.get(method, query);

  Map<String, Object?> get _folder => {'musicFolderId': libraryId};

  @override
  Future<Result<List<MusicLibrary>>> libraries() => _guard(() async {
    final json = await _get('getMusicFolders');
    return [
      for (final f in _m((json['musicFolders'] as Map?)?['musicFolder']))
        MusicLibrary(id: '${f['id']}', name: '${f['name'] ?? f['id']}'),
    ];
  });

  @override
  Future<Result<List<Album>>> albums(AlbumQuery query) => _guard(() async {
    if (query.artistId case final artistId?) {
      final json = await _get('getArtist', {'id': artistId});
      final all = [
        for (final a in _m((json['artist'] as Map?)?['album']))
          SubsonicMapper.album(a),
      ];
      return all.skip(query.offset).take(query.limit).toList();
    }
    final type = query.genreId != null
        ? 'byGenre'
        : switch (query.sort) {
            AlbumSort.name => 'alphabeticalByName',
            AlbumSort.artist => 'alphabeticalByArtist',
            AlbumSort.year => 'byYear',
            AlbumSort.dateAdded => 'newest',
            AlbumSort.random => 'random',
          };
    final json = await _get('getAlbumList2', {
      'type': type,
      'size': query.limit,
      'offset': query.offset,
      'genre': query.genreId,
      if (type == 'byYear') ...{'fromYear': 3000, 'toYear': 0},
      ..._folder,
    });
    return [
      for (final a in _m((json['albumList2'] as Map?)?['album']))
        SubsonicMapper.album(a),
    ];
  });

  @override
  Future<Result<AlbumDetail>> album(String id) => _guard(() async {
    final json = (await _get('getAlbum', {'id': id}))['album'];
    if (json is! Map<String, dynamic>) throw const NotFoundFailure();
    return AlbumDetail(
      album: SubsonicMapper.album(json),
      tracks: [for (final s in _m(json['song'])) SubsonicMapper.track(s)],
    );
  });

  @override
  Future<Result<List<Artist>>> artists({int offset = 0, int limit = 100}) =>
      _guard(() async {
        final json = await _get('getArtists', _folder);
        final all = [
          for (final index in _m((json['artists'] as Map?)?['index']))
            for (final a in _m(index['artist'])) SubsonicMapper.artist(a),
        ];
        return all.skip(offset).take(limit).toList();
      });

  @override
  Future<Result<ArtistDetail>> artist(String id) => _guard(() async {
    final json = (await _get('getArtist', {'id': id}))['artist'];
    if (json is! Map<String, dynamic>) throw const NotFoundFailure();
    String? bio;
    var top = <Track>[];
    try {
      final info = (await _get('getArtistInfo2', {'id': id}))['artistInfo2'];
      if (info is Map) bio = (info['biography'] as String?)?.trim();
      final songs = await _get('getTopSongs', {
        'artist': json['name'],
        'count': 10,
      });
      top = [
        for (final s in _m((songs['topSongs'] as Map?)?['song']))
          SubsonicMapper.track(s),
      ];
    } on SubsonicError {
      // Optional extras; plain Subsonic servers may not have them.
    }
    return ArtistDetail(
      artist: SubsonicMapper.artist(
        json,
        biography: bio == null || bio.isEmpty ? null : bio,
      ),
      albums: [for (final a in _m(json['album'])) SubsonicMapper.album(a)],
      topTracks: top,
    );
  });

  @override
  Future<Result<List<Track>>> tracks(TrackQuery query) => _guard(() async {
    List<Track> page(List<Track> all) =>
        all.skip(query.offset).take(query.limit).toList();
    if (query.albumId case final id?) {
      final json = (await _get('getAlbum', {'id': id}))['album'] as Map?;
      return page([for (final s in _m(json?['song'])) SubsonicMapper.track(s)]);
    }
    if (query.playlistId case final id?) {
      final json = (await _get('getPlaylist', {'id': id}))['playlist'] as Map?;
      final entries = _m(json?['entry']);
      // Subsonic removes playlist entries by position.
      return page([
        for (var i = 0; i < entries.length; i++)
          SubsonicMapper.track(entries[i]).copyWith(playlistItemId: '$i'),
      ]);
    }
    if (query.favoritesOnly) return page(await _starred());
    if (query.genreId case final genre?) {
      final json = await _get('getSongsByGenre', {
        'genre': genre,
        'count': query.limit,
        'offset': query.offset,
        ..._folder,
      });
      return [
        for (final s in _m((json['songsByGenre'] as Map?)?['song']))
          SubsonicMapper.track(s),
      ];
    }
    if (query.artistId case final id?) {
      final detail = (await artist(id)).valueOrNull;
      final albums = detail?.albums ?? const [];
      final songs = <Track>[];
      for (final a in albums) {
        songs.addAll((await album(a.id)).valueOrNull?.tracks ?? const []);
      }
      return page(songs);
    }
    // Plain listings: an empty search returns every song on OpenSubsonic.
    final json = await _get('search3', {
      'query': '',
      'songCount': query.limit,
      'songOffset': query.offset,
      'artistCount': 0,
      'albumCount': 0,
      ..._folder,
    });
    final songs = [
      for (final s in _m((json['searchResult3'] as Map?)?['song']))
        SubsonicMapper.track(s),
    ];
    return switch (query.sort) {
      TrackSort.mostPlayed =>
        songs..sort((a, b) => b.playCount.compareTo(a.playCount)),
      TrackSort.name => songs..sort((a, b) => a.title.compareTo(b.title)),
      _ => songs,
    };
  });

  Future<List<Track>> _starred() async {
    final json = await _get('getStarred2', _folder);
    return [
      for (final s in _m((json['starred2'] as Map?)?['song']))
        SubsonicMapper.track(s),
    ];
  }

  @override
  Future<Result<SearchResult>> search(String query, {int limit = 20}) =>
      _guard(() async {
        final json = await _get('search3', {
          'query': query,
          'artistCount': limit,
          'albumCount': limit,
          'songCount': limit,
          ..._folder,
        });
        final r = json['searchResult3'] as Map?;
        return SearchResult(
          artists: [for (final a in _m(r?['artist'])) SubsonicMapper.artist(a)],
          albums: [for (final a in _m(r?['album'])) SubsonicMapper.album(a)],
          tracks: [for (final s in _m(r?['song'])) SubsonicMapper.track(s)],
        );
      });

  @override
  Future<Result<List<Playlist>>> playlists() => _guard(() async {
    final json = await _get('getPlaylists');
    return [
      for (final p in _m((json['playlists'] as Map?)?['playlist']))
        SubsonicMapper.playlist(p),
    ];
  });

  @override
  Future<Result<Playlist>> createPlaylist(String name, List<String> trackIds) =>
      _guard(() async {
        final json = await _get('createPlaylist', {
          'name': name,
          'songId': trackIds,
        });
        final p = json['playlist'];
        return p is Map<String, dynamic>
            ? SubsonicMapper.playlist(p)
            : Playlist(id: '', name: name, trackCount: trackIds.length);
      });

  @override
  Future<Result<void>> addToPlaylist(
    String playlistId,
    List<String> trackIds,
  ) => _guard(
    () => _get('updatePlaylist', {
      'playlistId': playlistId,
      'songIdToAdd': trackIds,
    }),
  );

  @override
  Future<Result<void>> removeFromPlaylist(
    String playlistId,
    List<String> entryIds,
  ) => _guard(
    () => _get('updatePlaylist', {
      'playlistId': playlistId,
      'songIndexToRemove': entryIds,
    }),
  );

  /// Subsonic cannot move entries: the playlist is rewritten in the new
  /// order.
  @override
  Future<Result<void>> movePlaylistItem(
    String playlistId,
    String entryId,
    int newIndex,
  ) => _guard(() async {
    final json = (await _get('getPlaylist', {'id': playlistId}))['playlist'];
    final ids = [for (final e in _m((json as Map?)?['entry'])) '${e['id']}'];
    final from = int.parse(entryId);
    if (from < 0 || from >= ids.length) throw const NotFoundFailure();
    ids.insert(newIndex.clamp(0, ids.length - 1), ids.removeAt(from));
    await _get('createPlaylist', {'playlistId': playlistId, 'songId': ids});
  });

  @override
  Future<Result<void>> renamePlaylist(String playlistId, String name) => _guard(
    () => _get('updatePlaylist', {'playlistId': playlistId, 'name': name}),
  );

  @override
  Future<Result<void>> deletePlaylist(String playlistId) =>
      _guard(() => _get('deletePlaylist', {'id': playlistId}));

  @override
  Future<Result<List<Genre>>> genres() => _guard(() async {
    final json = await _get('getGenres');
    return [
      for (final g in _m((json['genres'] as Map?)?['genre']))
        if (g['value'] ?? g['name'] case final name?)
          Genre(id: '$name', name: '$name'),
    ];
  });

  @override
  Future<Result<void>> setFavorite(String id, {required bool value}) =>
      _guard(() => _get(value ? 'star' : 'unstar', {'id': id}));

  @override
  Future<Result<List<Track>>> favorites({int offset = 0, int limit = 100}) =>
      _guard(() async => (await _starred()).skip(offset).take(limit).toList());

  @override
  Future<Result<List<Track>>> randomTracks({int count = 50, String? genreId}) =>
      _guard(() async {
        final json = await _get('getRandomSongs', {
          'size': count,
          'genre': genreId,
          ..._folder,
        });
        return [
          for (final s in _m((json['randomSongs'] as Map?)?['song']))
            SubsonicMapper.track(s),
        ];
      });

  @override
  Future<Result<List<Track>>> similarTracks(String trackId, {int limit = 50}) =>
      _guard(() async {
        final json = await _get('getSimilarSongs', {
          'id': trackId,
          'count': limit,
        });
        return [
          for (final s in _m((json['similarSongs'] as Map?)?['song']))
            SubsonicMapper.track(s),
        ];
      });

  @override
  Future<Result<Lyrics?>> lyrics(Track track) => _guard(() async {
    try {
      final json = await _get('getLyricsBySongId', {'id': track.id});
      final found = SubsonicMapper.structuredLyrics(json);
      if (found != null) return found;
    } on SubsonicError {
      // Not an OpenSubsonic server; try the classic endpoint.
    }
    final json = await _get('getLyrics', {
      'artist': track.artistLine,
      'title': track.title,
    });
    final text = ((json['lyrics'] as Map?)?['value'] as String?)?.trim();
    if (text == null || text.isEmpty) return null;
    return Lyrics(
      lines: [for (final l in text.split('\n')) LyricLine(text: l)],
    );
  });

  Map<String, String> _quality(StreamOptions options) => {
    if (options.maxBitrateKbps case final kbps?) 'maxBitRate': '$kbps',
    if (options.format != StreamFormat.original) 'format': options.format.name,
  };

  @override
  Uri streamUri(Track track, [StreamOptions options = const StreamOptions()]) =>
      _api.resolve('stream', {'id': track.id, ..._quality(options)});

  @override
  Uri downloadUri(
    Track track, [
    StreamOptions options = const StreamOptions(),
  ]) => options.isOriginal
      ? _api.resolve('download', {'id': track.id})
      : _api.resolve('stream', {
          'id': track.id,
          'estimateContentLength': 'true',
          ..._quality(options),
        });

  @override
  Uri? artworkUri(Artwork? artwork, {int size = 300}) => artwork == null
      ? null
      : _api.resolve('getCoverArt', {'id': artwork.itemId, 'size': '$size'});

  /// Start: "now playing"; stop after a real listen: a scrobble.
  @override
  Future<Result<void>> reportPlayback(PlaybackReport report) =>
      _guard(() async {
        switch (report.kind) {
          case PlaybackEventKind.start:
            await _get('scrobble', {'id': report.trackId, 'submission': false});
          case PlaybackEventKind.stopped
              when report.position >= const Duration(seconds: 30):
            await _get('scrobble', {'id': report.trackId, 'submission': true});
          case PlaybackEventKind.stopped || PlaybackEventKind.progress:
            break;
        }
      });

  /// Releases the underlying connections.
  void close() => _api.close();
}
