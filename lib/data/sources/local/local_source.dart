import 'dart:io';

import 'package:flutter/services.dart';
import 'package:melody/core/config/feature_flags.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/domain/repositories/server_connector.dart';

/// Reads audio files from the device's media index; faked in tests.
abstract interface class DeviceMedia {
  /// Whether the app may read audio files.
  Future<bool> hasPermission();

  /// Asks for permission to read audio files; returns whether it was given.
  Future<bool> requestPermission();

  /// Every audio file the system knows about, as plain maps.
  Future<List<Map<String, Object?>>> scan();
}

/// [DeviceMedia] over Android's MediaStore (`melody/local` channel).
class ChannelDeviceMedia implements DeviceMedia {
  /// Creates the channel client.
  const ChannelDeviceMedia();

  static const _channel = MethodChannel('melody/local');

  @override
  Future<bool> hasPermission() async =>
      Platform.isAndroid &&
      (await _channel.invokeMethod<bool>('hasPermission') ?? false);

  @override
  Future<bool> requestPermission() async =>
      Platform.isAndroid &&
      (await _channel.invokeMethod<bool>('requestPermission') ?? false);

  @override
  Future<List<Map<String, Object?>>> scan() async {
    final raw = await _channel.invokeListMethod<Map<Object?, Object?>>('scan');
    return [
      for (final Map<Object?, Object?> m in raw ?? const [])
        m.cast<String, Object?>(),
    ];
  }
}

/// Audio files on the device, grouped into albums and artists in memory.
///
/// Streams are `content://` addresses the player reads directly. Covers use
/// MediaStore's album art addresses. Playlists, favourites and lyrics are
/// not offered.
class LocalSource implements MusicSource {
  /// Creates the source.
  LocalSource({this.media = const ChannelDeviceMedia()});

  /// Where files come from.
  final DeviceMedia media;

  List<Track>? _tracks;

  @override
  SourceCapabilities get capabilities => const SourceCapabilities();

  @override
  Map<String, String> get requestHeaders => const {};

  static String? _s(Object? v) {
    final text = v?.toString().trim();
    return text == null || text.isEmpty || text == '<unknown>' ? null : text;
  }

  static int? _i(Object? v) => v is num ? v.toInt() : null;

  /// Maps one MediaStore row.
  static Track track(Map<String, Object?> row) {
    final number = _i(row['track']);
    final artist = _s(row['artist']);
    final albumId = _s(row['albumId']);
    return Track(
      id: '${row['id']}',
      title: _s(row['title']) ?? _s(row['displayName']) ?? '',
      artists: [
        if (artist != null)
          NamedRef(id: _s(row['artistId']) ?? artist, name: artist),
      ],
      albumId: albumId,
      albumTitle: _s(row['album']),
      albumArtist: _s(row['albumArtist']) ?? artist,
      duration: _i(row['duration']) == null
          ? null
          : Duration(milliseconds: _i(row['duration'])!),
      // MediaStore stores the disc in the thousands: 2005 = disc 2, track 5.
      trackNumber: number == null ? null : number % 1000,
      discNumber: number == null || number < 1000 ? null : number ~/ 1000,
      year: _i(row['year']),
      artwork: albumId == null ? null : Artwork(itemId: albumId),
      container: _s(row['mime'])?.split('/').last,
    );
  }

  Future<List<Track>> _all() async {
    final cached = _tracks;
    if (cached != null) return cached;
    if (!await media.hasPermission()) throw const UnauthorizedFailure();
    final rows = await media.scan();
    return _tracks = [for (final r in rows) track(r)]
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  /// Forgets the scan, so the next call reads the files again.
  void rescan() => _tracks = null;

  Future<Result<T>> _guard<T>(Future<T> Function() body) => Result.guard(
    body,
    onError: (e) => e is Failure ? e : UnknownFailure(cause: e),
  );

  List<Album> _albums(List<Track> tracks) {
    final byId = <String, List<Track>>{};
    for (final t in tracks) {
      if (t.albumId case final id?) byId.putIfAbsent(id, () => []).add(t);
    }
    return [
      for (final MapEntry(key: id, value: list) in byId.entries)
        Album(
          id: id,
          title: list.first.albumTitle ?? '',
          artistName: list.first.albumArtist,
          artists: list.first.artists,
          year: list.first.year,
          trackCount: list.length,
          duration: list.fold<Duration>(
            Duration.zero,
            (sum, t) => sum + (t.duration ?? Duration.zero),
          ),
          artwork: list.first.artwork,
        ),
    ]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  List<Track> _inOrder(List<Track> tracks) => [...tracks]
    ..sort((a, b) {
      final disc = (a.discNumber ?? 1).compareTo(b.discNumber ?? 1);
      return disc != 0
          ? disc
          : (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0);
    });

  @override
  Future<Result<List<MusicLibrary>>> libraries() async => const Ok([]);

  @override
  Future<Result<List<Album>>> albums(AlbumQuery query) => _guard(() async {
    var all = _albums(await _all());
    if (query.artistId case final id?) {
      all = all.where((a) => a.artists.any((r) => r.id == id)).toList();
    }
    switch (query.sort) {
      case AlbumSort.year:
        all.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
      case AlbumSort.artist:
        all.sort((a, b) => a.artistLine.compareTo(b.artistLine));
      case AlbumSort.random:
        all.shuffle();
      case AlbumSort.name || AlbumSort.dateAdded:
        break;
    }
    return all.skip(query.offset).take(query.limit).toList();
  });

  @override
  Future<Result<AlbumDetail>> album(String id) => _guard(() async {
    final tracks = (await _all()).where((t) => t.albumId == id).toList();
    if (tracks.isEmpty) throw const NotFoundFailure();
    return AlbumDetail(album: _albums(tracks).single, tracks: _inOrder(tracks));
  });

  List<Artist> _artists(List<Track> tracks) {
    final byId = <String, Artist>{};
    for (final t in tracks) {
      for (final a in t.artists) {
        byId.putIfAbsent(a.id, () => Artist(id: a.id, name: a.name));
      }
    }
    return byId.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Future<Result<List<Artist>>> artists({int offset = 0, int limit = 100}) =>
      _guard(
        () async => _artists(await _all()).skip(offset).take(limit).toList(),
      );

  @override
  Future<Result<ArtistDetail>> artist(String id) => _guard(() async {
    final tracks = (await _all())
        .where((t) => t.artists.any((a) => a.id == id))
        .toList();
    if (tracks.isEmpty) throw const NotFoundFailure();
    return ArtistDetail(
      artist: _artists(tracks).firstWhere((a) => a.id == id),
      albums: _albums(tracks),
      topTracks: tracks.take(10).toList(),
    );
  });

  @override
  Future<Result<List<Track>>> tracks(TrackQuery query) => _guard(() async {
    var all = await _all();
    if (query.albumId case final id?) {
      all = _inOrder(all.where((t) => t.albumId == id).toList());
    }
    if (query.artistId case final id?) {
      all = all.where((t) => t.artists.any((a) => a.id == id)).toList();
    }
    if (query.favoritesOnly || query.playlistId != null) all = const [];
    return all.skip(query.offset).take(query.limit).toList();
  });

  @override
  Future<Result<SearchResult>> search(String query, {int limit = 20}) =>
      _guard(() async {
        final q = query.toLowerCase();
        final all = await _all();
        bool hit(String? text) => text?.toLowerCase().contains(q) ?? false;
        return SearchResult(
          tracks: all.where((t) => hit(t.title)).take(limit).toList(),
          albums: _albums(all).where((a) => hit(a.title)).take(limit).toList(),
          artists: _artists(all).where((a) => hit(a.name)).take(limit).toList(),
        );
      });

  @override
  Future<Result<List<Track>>> randomTracks({int count = 50, String? genreId}) =>
      _guard(() async => ([...await _all()]..shuffle()).take(count).toList());

  @override
  Future<Result<List<Track>>> similarTracks(String trackId, {int limit = 50}) =>
      randomTracks(count: limit);

  @override
  Future<Result<List<Playlist>>> playlists() async => const Ok([]);

  @override
  Future<Result<Playlist>> createPlaylist(
    String name,
    List<String> ids,
  ) async => const Err(UnsupportedFailure());

  @override
  Future<Result<void>> addToPlaylist(String p, List<String> ids) async =>
      const Err(UnsupportedFailure());

  @override
  Future<Result<void>> removeFromPlaylist(String p, List<String> ids) async =>
      const Err(UnsupportedFailure());

  @override
  Future<Result<void>> movePlaylistItem(String p, String e, int i) async =>
      const Err(UnsupportedFailure());

  @override
  Future<Result<void>> renamePlaylist(String p, String name) async =>
      const Err(UnsupportedFailure());

  @override
  Future<Result<void>> deletePlaylist(String p) async =>
      const Err(UnsupportedFailure());

  @override
  Future<Result<List<Genre>>> genres() async => const Ok([]);

  @override
  Future<Result<void>> setFavorite(String id, {required bool value}) async =>
      const Err(UnsupportedFailure());

  @override
  Future<Result<List<Track>>> favorites({
    int offset = 0,
    int limit = 100,
  }) async => const Ok([]);

  @override
  Future<Result<Lyrics?>> lyrics(Track track) async => const Ok(null);

  @override
  Uri streamUri(Track track, [StreamOptions options = const StreamOptions()]) =>
      Uri.parse('content://media/external/audio/media/${track.id}');

  @override
  Uri downloadUri(
    Track track, [
    StreamOptions options = const StreamOptions(),
  ]) => streamUri(track);

  @override
  Uri? artworkUri(Artwork? artwork, {int size = 300}) => artwork == null
      ? null
      : Uri.parse('content://media/external/audio/albumart/${artwork.itemId}');

  @override
  Future<Result<void>> reportPlayback(PlaybackReport report) async =>
      const Ok(null);
}

/// "Signs in" to the device: asks for permission to read audio files.
class LocalConnector implements ServerConnector {
  /// Creates the connector.
  const LocalConnector({this.media = const ChannelDeviceMedia()});

  /// Where the permission is asked.
  final DeviceMedia media;

  static final _device = ServerInfo(
    baseUrl: Uri.parse('content://media'),
    name: 'device',
    type: SourceType.local,
  );

  @override
  Stream<ServerInfo> discover() => const Stream.empty();

  @override
  Future<Result<ServerInfo>> probe(String address) async => Ok(_device);

  @override
  Future<Result<List<PublicUser>>> publicUsers(ServerInfo server) async =>
      const Ok([]);

  /// Only asks for the permission; there is no user or password.
  @override
  Future<Result<AuthSession>> signIn(
    ServerInfo server, {
    required String username,
    required String password,
  }) async {
    try {
      final granted =
          await media.hasPermission() || await media.requestPermission();
      if (!granted) return const Err(UnauthorizedFailure());
    } on Object catch (error) {
      return Err(UnknownFailure(cause: error));
    }
    return Ok(
      AuthSession(
        accessToken: 'device',
        account: ServerAccount(
          id: '${SourceType.local.name}:device',
          type: SourceType.local,
          baseUrl: server.baseUrl,
          serverName: server.name,
          userId: 'local',
          userName: '',
        ),
      ),
    );
  }

  @override
  Future<Result<bool>> quickConnectAvailable(ServerInfo server) async =>
      const Ok(false);

  @override
  Future<Result<QuickConnectRequest>> quickConnectStart(ServerInfo s) async =>
      const Err(UnsupportedFailure());

  @override
  Future<Result<bool>> quickConnectApproved(
    ServerInfo s,
    QuickConnectRequest r,
  ) async => const Err(UnsupportedFailure());

  @override
  Future<Result<AuthSession>> quickConnectSignIn(
    ServerInfo s,
    QuickConnectRequest r,
  ) async => const Err(UnsupportedFailure());
}
