import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:melody/core/config/feature_flags.dart';
import 'package:melody/core/device/client_identity.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/data/downloads/download_transport.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/domain/repositories/server_connector.dart';

/// Identity used by tests.
const testIdentity = ClientIdentity(
  deviceId: 'device-1',
  deviceName: 'Test Phone',
  version: '1.2.3',
);

/// Server used by tests.
final testServer = ServerInfo(
  baseUrl: Uri.parse('https://music.example.com'),
  name: 'Home Server',
  id: 'srv1',
  version: '10.10.3',
);

/// Account used by tests.
final testAccount = ServerAccount(
  id: 'jellyfin:srv1:u1',
  type: SourceType.jellyfin,
  baseUrl: Uri.parse('https://music.example.com'),
  serverName: 'Home Server',
  serverId: 'srv1',
  userId: 'u1',
  userName: 'ayla',
);

/// One canned HTTP answer.
typedef FakeResponse = ({int status, Object? body});

/// Dio transport answering from a handler instead of the network.
class FakeHttpAdapter implements HttpClientAdapter {
  /// Creates the adapter.
  FakeHttpAdapter(this.handler);

  /// Produces the answer for a request; throw to simulate a dead network.
  final FakeResponse Function(RequestOptions request) handler;

  /// Every request seen, in order.
  final requests = <RequestOptions>[];

  /// The most recent request.
  RequestOptions get last => requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = handler(options);
    return ResponseBody.fromString(
      response.body == null ? '' : jsonEncode(response.body),
      response.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Throws the error Dio reports when no connection can be made.
Never connectionError(RequestOptions request) => throw DioException(
  requestOptions: request,
  type: DioExceptionType.connectionError,
);

/// Builds an album for tests.
Album makeAlbum(String id, {String? title, String artist = 'Sezen'}) => Album(
  id: id,
  title: title ?? 'Album $id',
  artistName: artist,
  artists: [NamedRef(id: 'artist-$artist', name: artist)],
  year: 2001,
);

/// Builds a track for tests.
Track makeTrack(
  String id, {
  String? title,
  String albumId = 'a1',
  int disc = 1,
}) => Track(
  id: id,
  title: title ?? 'Track $id',
  albumId: albumId,
  albumArtist: 'Sezen',
  discNumber: disc,
  trackNumber: 1,
  duration: const Duration(minutes: 3, seconds: 5),
);

/// In-memory [MusicSource] with a small library.
class FakeMusicSource implements MusicSource {
  /// Creates the source.
  FakeMusicSource({List<Album>? albums, List<Track>? tracks})
    : albumItems =
          albums ??
          [makeAlbum('a1', title: 'Gülümse'), makeAlbum('a2', title: 'Deli')],
      trackItems =
          tracks ??
          [makeTrack('t1', title: 'Firuze'), makeTrack('t2', title: 'Hadi')];

  /// Albums served by [albums].
  List<Album> albumItems;

  /// Tracks served by [tracks].
  List<Track> trackItems;

  /// When set, every call fails with it.
  Failure? failure;

  /// Search queries received.
  final searches = <String>[];

  /// Album queries received.
  final albumQueries = <AlbumQuery>[];

  /// Favourite changes received.
  final favoriteCalls = <(String, bool)>[];

  /// Playback reports received.
  final reports = <PlaybackReport>[];

  Result<T> _answer<T>(T value) => failure == null ? Ok(value) : Err(failure!);

  @override
  SourceCapabilities get capabilities => const SourceCapabilities(
    favorites: true,
    playlists: true,
    editablePlaylists: true,
    lyrics: true,
    genres: true,
    multipleLibraries: true,
    playbackReporting: true,
  );

  @override
  Future<Result<void>> reportPlayback(PlaybackReport report) async {
    if (failure == null) reports.add(report);
    return _answer(null);
  }

  @override
  Map<String, String> get requestHeaders => const {};

  @override
  Future<Result<List<MusicLibrary>>> libraries() async => _answer(const [
    MusicLibrary(id: 'lib1', name: 'Music'),
    MusicLibrary(id: 'lib2', name: 'Audiobooks'),
  ]);

  @override
  Future<Result<List<Album>>> albums(AlbumQuery query) async {
    albumQueries.add(query);
    return _answer(albumItems.skip(query.offset).take(query.limit).toList());
  }

  @override
  Future<Result<AlbumDetail>> album(String id) async => failure != null
      ? Err(failure!)
      : _answer(
          AlbumDetail(
            album: albumItems.firstWhere((a) => a.id == id),
            tracks: [
              makeTrack('t1', title: 'Firuze', albumId: id),
              makeTrack('t2', title: 'Hadi', albumId: id, disc: 2),
            ],
          ),
        );

  @override
  Future<Result<List<Artist>>> artists({
    int offset = 0,
    int limit = 100,
  }) async => _answer(const [Artist(id: 'ar1', name: 'Sezen')]);

  @override
  Future<Result<ArtistDetail>> artist(String id) async => _answer(
    ArtistDetail(
      artist: const Artist(id: 'ar1', name: 'Sezen', overview: 'Bio text'),
      albums: albumItems,
      topTracks: trackItems,
    ),
  );

  @override
  Future<Result<List<Track>>> tracks(TrackQuery query) async => _answer(
    (query.playlistId == null
            ? trackItems
            : [
                for (final (entry, track)
                    in playlistEntries[query.playlistId] ??
                        const <(String, Track)>[])
                  track.copyWith(playlistItemId: entry),
              ])
        .where((t) => !query.favoritesOnly || t.isFavorite)
        .skip(query.offset)
        .take(query.limit)
        .toList(),
  );

  @override
  Future<Result<SearchResult>> search(String query, {int limit = 20}) async {
    searches.add(query);
    final q = query.toLowerCase();
    return _answer(
      SearchResult(
        albums: [
          for (final a in albumItems)
            if (a.title.toLowerCase().contains(q)) a,
        ],
        tracks: [
          for (final t in trackItems)
            if (t.title.toLowerCase().contains(q)) t,
        ],
      ),
    );
  }

  @override
  Future<Result<List<Playlist>>> playlists() async => _answer([
    for (final e in playlistNames.entries)
      Playlist(
        id: e.key,
        name: e.value,
        trackCount: playlistEntries[e.key]?.length,
      ),
  ]);

  @override
  Future<Result<List<Genre>>> genres() async =>
      _answer(const [Genre(id: 'g1', name: 'Pop')]);

  @override
  Future<Result<void>> setFavorite(String id, {required bool value}) async {
    favoriteCalls.add((id, value));
    if (failure == null) {
      albumItems = [
        for (final a in albumItems)
          if (a.id == id) a.copyWith(isFavorite: value) else a,
      ];
    }
    return _answer(null);
  }

  @override
  Future<Result<List<Track>>> favorites({
    int offset = 0,
    int limit = 100,
  }) async => _answer(const []);

  @override
  Future<Result<List<Track>>> randomTracks({
    int count = 50,
    String? genreId,
  }) async => _answer(trackItems);

  @override
  Future<Result<List<Track>>> similarTracks(
    String trackId, {
    int limit = 50,
  }) async => _answer(trackItems);

  /// Playlists by id; each entry is (entry id, track).
  final playlistEntries = <String, List<(String, Track)>>{'p1': []};

  /// Playlist names by id.
  final playlistNames = <String, String>{'p1': 'Yol şarkıları'};

  /// Lyrics by track id.
  final lyricsByTrack = <String, Lyrics>{};

  int _entry = 0;

  Track _byId(String id) =>
      trackItems.firstWhere((t) => t.id == id, orElse: () => makeTrack(id));

  @override
  Future<Result<Playlist>> createPlaylist(
    String name,
    List<String> trackIds,
  ) async {
    final id = 'p${playlistNames.length + 1}';
    playlistNames[id] = name;
    playlistEntries[id] = [
      for (final t in trackIds) ('e${_entry++}', _byId(t)),
    ];
    return _answer(Playlist(id: id, name: name, trackCount: trackIds.length));
  }

  @override
  Future<Result<void>> addToPlaylist(
    String playlistId,
    List<String> trackIds,
  ) async {
    playlistEntries[playlistId]!.addAll([
      for (final t in trackIds) ('e${_entry++}', _byId(t)),
    ]);
    return _answer(null);
  }

  @override
  Future<Result<void>> removeFromPlaylist(
    String playlistId,
    List<String> entryIds,
  ) async {
    playlistEntries[playlistId]!.removeWhere((e) => entryIds.contains(e.$1));
    return _answer(null);
  }

  @override
  Future<Result<void>> movePlaylistItem(
    String playlistId,
    String entryId,
    int newIndex,
  ) async {
    final list = playlistEntries[playlistId]!;
    final entry = list.firstWhere((e) => e.$1 == entryId);
    list
      ..remove(entry)
      ..insert(newIndex, entry);
    return _answer(null);
  }

  @override
  Future<Result<void>> renamePlaylist(String playlistId, String name) async {
    playlistNames[playlistId] = name;
    return _answer(null);
  }

  @override
  Future<Result<void>> deletePlaylist(String playlistId) async {
    playlistNames.remove(playlistId);
    playlistEntries.remove(playlistId);
    return _answer(null);
  }

  @override
  Future<Result<Lyrics?>> lyrics(Track track) async =>
      _answer(lyricsByTrack[track.id]);

  @override
  Uri streamUri(Track track, [StreamOptions options = const StreamOptions()]) =>
      Uri.parse('https://music.example.com/stream/${track.id}').replace(
        queryParameters: {
          if (options.maxBitrateKbps != null)
            'kbps': '${options.maxBitrateKbps}',
          if (options.format != StreamFormat.original)
            'format': options.format.name,
        },
      );

  @override
  Uri downloadUri(
    Track track, [
    StreamOptions options = const StreamOptions(),
  ]) => Uri.parse('https://music.example.com/download/${track.id}');

  @override
  Uri? artworkUri(Artwork? artwork, {int size = 300}) => null;
}

/// Scripted [ServerConnector].
class FakeConnector implements ServerConnector {
  /// Servers "found" on the network.
  List<ServerInfo> discovered = [];

  /// Answer of [probe].
  Result<ServerInfo> probeResult = Ok(testServer);

  /// Password [signIn] accepts.
  String password = 'secret';

  /// Whether Quick Connect is offered.
  bool quickConnect = false;

  /// Whether the Quick Connect request counts as approved.
  bool quickConnectIsApproved = false;

  /// Addresses passed to [probe].
  final probed = <String>[];

  AuthSession get _session =>
      AuthSession(account: testAccount, accessToken: 'token-1');

  @override
  Stream<ServerInfo> discover() => Stream.fromIterable(discovered);

  @override
  Future<Result<ServerInfo>> probe(String address) async {
    probed.add(address);
    return probeResult;
  }

  @override
  Future<Result<List<PublicUser>>> publicUsers(ServerInfo server) async =>
      const Ok([PublicUser(id: 'u1', name: 'ayla')]);

  @override
  Future<Result<AuthSession>> signIn(
    ServerInfo server, {
    required String username,
    required String password,
  }) async => password == this.password
      ? Ok(_session)
      : const Err(UnauthorizedFailure());

  @override
  Future<Result<bool>> quickConnectAvailable(ServerInfo server) async =>
      Ok(quickConnect);

  @override
  Future<Result<QuickConnectRequest>> quickConnectStart(
    ServerInfo server,
  ) async => const Ok(QuickConnectRequest(code: '123456', secret: 's3cret'));

  @override
  Future<Result<bool>> quickConnectApproved(
    ServerInfo server,
    QuickConnectRequest request,
  ) async => Ok(quickConnectIsApproved);

  @override
  Future<Result<AuthSession>> quickConnectSignIn(
    ServerInfo server,
    QuickConnectRequest request,
  ) async => Ok(_session);
}

/// [DownloadTransport] writing canned bytes instead of using the network.
class FakeDownloadTransport implements DownloadTransport {
  /// Bytes "served" for every address.
  List<int> body = List.filled(1000, 7);

  /// Addresses that fail.
  final failing = <String>{};

  /// When set, transfers wait here until it completes (or are cancelled).
  Completer<void>? gate;

  /// Addresses requested, in order.
  final requests = <Uri>[];

  @override
  Future<void> fetch(
    Uri uri,
    File target, {
    required DownloadHandle handle,
    Map<String, String> headers = const {},
    void Function(int bytes, int total)? onProgress,
  }) async {
    requests.add(uri);
    final wait = gate;
    if (wait != null) {
      await Future.any([wait.future, handle.whenCancelled]);
    }
    if (handle.isCancelled) throw const DownloadCancelled();
    if (failing.contains('$uri')) throw const SocketException('offline');
    final offset = target.existsSync() ? target.lengthSync() : 0;
    await target.writeAsBytes(
      body.sublist(offset.clamp(0, body.length)),
      mode: FileMode.append,
    );
    onProgress?.call(body.length, body.length);
  }
}
