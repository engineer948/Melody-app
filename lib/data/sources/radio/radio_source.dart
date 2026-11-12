import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:melody/core/config/feature_flags.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/core/network/failure_mapper.dart';
import 'package:melody/core/network/http_client.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/domain/repositories/server_connector.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Default Radio Browser mirror.
final Uri radioBrowserBase = Uri.parse('https://de1.api.radio-browser.info');

/// Internet radio from the public Radio Browser directory, plus stations
/// added by hand. Stations are `Track`s: the id is `<uuid>|<stream url>`
/// (or `custom|<url>`), so a saved queue can be played again later.
/// Tags are the genres; favourites are kept on the device.
class RadioSource implements MusicSource {
  /// Creates the source; the preferences store saved stations.
  RadioSource({required this._prefs, Uri? baseUrl, HttpClientAdapter? adapter})
    : _dio = createHttpClient(
        baseUrl: baseUrl ?? radioBrowserBase,
        adapter: adapter,
      );

  final SharedPreferences _prefs;
  final Dio _dio;

  /// Preference key of saved stations (favourites and custom ones).
  static const favoritesKey = 'radio.favorites';

  @override
  SourceCapabilities get capabilities => const SourceCapabilities(
    favorites: true,
    genres: true,
    instantMix: true,
    playbackReporting: true,
  );

  @override
  Map<String, String> get requestHeaders => const {};

  Future<Result<T>> _guard<T>(Future<T> Function() body) =>
      Result.guard(body, onError: mapNetworkError);

  Future<List<Track>> _stations(String path, Map<String, Object?> query) async {
    final response = await _dio.get<List<dynamic>>(
      'json/$path',
      queryParameters: {
        'hidebroken': 'true',
        for (final e in query.entries)
          if (e.value != null) e.key: '${e.value}',
      },
    );
    final favorites = _favoriteIds;
    return [
      for (final raw in response.data ?? const <dynamic>[])
        if (raw is Map<String, dynamic>)
          if (station(raw) case final t?)
            t.copyWith(isFavorite: favorites.contains(t.id)),
    ];
  }

  /// Maps one Radio Browser station; `null` without a stream address.
  static Track? station(Map<String, dynamic> json) {
    final url = (json['url_resolved'] as String?)?.trim().isNotEmpty ?? false
        ? json['url_resolved'] as String
        : json['url'] as String?;
    final uuid = json['stationuuid'] as String?;
    if (url == null || url.isEmpty || uuid == null) return null;
    final tags = '${json['tags'] ?? ''}'
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final favicon = '${json['favicon'] ?? ''}'.trim();
    final country = '${json['country'] ?? ''}'.trim();
    return Track(
      id: '$uuid|$url',
      title: '${json['name'] ?? ''}'.trim(),
      artists: [
        if (tags.isNotEmpty) NamedRef(id: '', name: tags.take(2).join(', ')),
      ],
      albumTitle: country.isEmpty ? null : country,
      albumArtist: country.isEmpty ? null : country,
      artwork: favicon.startsWith('http') ? Artwork(itemId: favicon) : null,
      container: (json['codec'] as String?)?.toLowerCase(),
      genres: tags,
    );
  }

  /// Stream address and Radio Browser id of a station id.
  static ({String? uuid, Uri url}) parseId(String id) {
    final at = id.indexOf('|');
    final uuid = id.substring(0, at);
    return (
      uuid: uuid == 'custom' ? null : uuid,
      url: Uri.parse(id.substring(at + 1)),
    );
  }

  // ---- Saved stations ------------------------------------------------------

  List<Track> get _saved => [
    for (final raw in _prefs.getStringList(favoritesKey) ?? const <String>[])
      Track.fromJson(jsonDecode(raw) as Map<String, dynamic>),
  ];

  Set<String> get _favoriteIds => {for (final t in _saved) t.id};

  Future<void> _save(List<Track> tracks) => _prefs.setStringList(favoritesKey, [
    for (final t in tracks) jsonEncode(t.copyWith(isFavorite: true).toJson()),
  ]);

  /// Adds a station by its stream address; it is kept with the favourites.
  Future<Track> addCustomStation(String name, Uri url) async {
    final track = Track(id: 'custom|$url', title: name, isFavorite: true);
    await _save([..._saved.where((t) => t.id != track.id), track]);
    return track;
  }

  // ---- MusicSource ----------------------------------------------------

  @override
  Future<Result<List<MusicLibrary>>> libraries() async => const Ok([]);

  @override
  Future<Result<List<Album>>> albums(AlbumQuery query) async => const Ok([]);

  @override
  Future<Result<AlbumDetail>> album(String id) async =>
      const Err(UnsupportedFailure());

  @override
  Future<Result<List<Artist>>> artists({
    int offset = 0,
    int limit = 100,
  }) async => const Ok([]);

  @override
  Future<Result<ArtistDetail>> artist(String id) async =>
      const Err(UnsupportedFailure());

  @override
  Future<Result<List<Track>>> tracks(TrackQuery query) => _guard(() async {
    if (query.favoritesOnly) {
      return _saved.skip(query.offset).take(query.limit).toList();
    }
    final order = switch (query.sort) {
      TrackSort.mostPlayed => 'clickcount',
      TrackSort.recentlyPlayed => 'clicktimestamp',
      TrackSort.dateAdded => 'changetimestamp',
      TrackSort.name => 'name',
      _ => 'votes',
    };
    return await _stations('stations/search', {
      'tag': query.genreId,
      'tagExact': query.genreId == null ? null : 'true',
      'order': order,
      'reverse': order == 'name' ? 'false' : 'true',
      'offset': query.offset,
      'limit': query.limit,
    });
  });

  @override
  Future<Result<SearchResult>> search(String query, {int limit = 20}) => _guard(
    () async => SearchResult(
      tracks: await _stations('stations/search', {
        'name': query,
        'order': 'votes',
        'reverse': 'true',
        'limit': limit,
      }),
    ),
  );

  @override
  Future<Result<List<Genre>>> genres() => _guard(() async {
    final response = await _dio.get<List<dynamic>>(
      'json/tags',
      queryParameters: {
        'order': 'stationcount',
        'reverse': 'true',
        'hidebroken': 'true',
        'limit': '100',
      },
    );
    return [
      for (final raw in response.data ?? const <dynamic>[])
        if (raw is Map && raw['name'] is String)
          Genre(id: raw['name'] as String, name: raw['name'] as String),
    ];
  });

  @override
  Future<Result<void>> setFavorite(String id, {required bool value}) =>
      _guard(() async {
        final saved = _saved.where((t) => t.id != id).toList();
        if (value) {
          final parsed = parseId(id);
          final found = parsed.uuid == null
              ? <Track>[]
              : await _stations('stations/byuuid', {'uuids': parsed.uuid});
          saved.add(found.firstOrNull ?? Track(id: id, title: parsed.url.host));
        }
        await _save(saved);
      });

  @override
  Future<Result<List<Track>>> favorites({
    int offset = 0,
    int limit = 100,
  }) async => Ok(_saved.skip(offset).take(limit).toList());

  @override
  Future<Result<List<Track>>> randomTracks({int count = 50, String? genreId}) =>
      _guard(
        () async => await _stations('stations/search', {
          'tag': genreId,
          'order': 'random',
          'limit': count,
        }),
      );

  /// Stations sharing the first tag of [trackId], when it is known.
  @override
  Future<Result<List<Track>>> similarTracks(String trackId, {int limit = 50}) =>
      _guard(() async {
        final uuid = parseId(trackId).uuid;
        if (uuid == null) return const <Track>[];
        final found = await _stations('stations/byuuid', {'uuids': uuid});
        final tag = found.firstOrNull?.genres.firstOrNull;
        if (tag == null) return const <Track>[];
        return await _stations('stations/search', {
          'tag': tag,
          'order': 'random',
          'limit': limit,
        });
      });

  @override
  Future<Result<List<Playlist>>> playlists() async => const Ok([]);

  @override
  Future<Result<Playlist>> createPlaylist(
    String name,
    List<String> ids,
  ) async => const Err(UnsupportedFailure());

  @override
  Future<Result<void>> addToPlaylist(
    String playlistId,
    List<String> ids,
  ) async => const Err(UnsupportedFailure());

  @override
  Future<Result<void>> removeFromPlaylist(
    String playlistId,
    List<String> ids,
  ) async => const Err(UnsupportedFailure());

  @override
  Future<Result<void>> movePlaylistItem(String p, String e, int i) async =>
      const Err(UnsupportedFailure());

  @override
  Future<Result<void>> renamePlaylist(String playlistId, String name) async =>
      const Err(UnsupportedFailure());

  @override
  Future<Result<void>> deletePlaylist(String playlistId) async =>
      const Err(UnsupportedFailure());

  @override
  Future<Result<Lyrics?>> lyrics(Track track) async => const Ok(null);

  @override
  Uri streamUri(Track track, [StreamOptions options = const StreamOptions()]) =>
      parseId(track.id).url;

  @override
  Uri downloadUri(
    Track track, [
    StreamOptions options = const StreamOptions(),
  ]) => parseId(track.id).url;

  @override
  Uri? artworkUri(Artwork? artwork, {int size = 300}) =>
      artwork == null ? null : Uri.tryParse(artwork.itemId);

  /// Counts a listen in the directory, as its rules ask clients to do.
  @override
  Future<Result<void>> reportPlayback(PlaybackReport report) =>
      _guard(() async {
        final uuid = parseId(report.trackId).uuid;
        if (report.kind != PlaybackEventKind.start || uuid == null) return;
        await _dio.get<Object?>('json/url/$uuid');
      });

  /// Releases the underlying connections.
  void close() => _dio.close();
}

/// "Signs in" to the radio directory: there is no account.
class RadioConnector implements ServerConnector {
  /// Creates the connector.
  const RadioConnector();

  static final _server = ServerInfo(
    baseUrl: radioBrowserBase,
    name: 'Radio Browser',
    type: SourceType.radio,
  );

  @override
  Stream<ServerInfo> discover() => const Stream.empty();

  @override
  Future<Result<ServerInfo>> probe(String address) async => Ok(_server);

  @override
  Future<Result<List<PublicUser>>> publicUsers(ServerInfo server) async =>
      const Ok([]);

  @override
  Future<Result<AuthSession>> signIn(
    ServerInfo server, {
    required String username,
    required String password,
  }) async => Ok(
    AuthSession(
      accessToken: 'none',
      account: ServerAccount(
        id: '${SourceType.radio.name}:radio-browser',
        type: SourceType.radio,
        baseUrl: server.baseUrl,
        serverName: server.name,
        userId: 'local',
        userName: '',
      ),
    ),
  );

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
