import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_api.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_music_source.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/repositories/music_source.dart';

import '../../helpers/fakes.dart';
import '../../helpers/fixtures.dart';

void main() {
  late FakeHttpAdapter adapter;
  var unauthorized = 0;

  JellyfinMusicSource source(
    FakeResponse Function(RequestOptions) handler, {
    String? libraryId,
  }) {
    adapter = FakeHttpAdapter(handler);
    return JellyfinMusicSource(
      api: JellyfinApi(
        baseUrl: Uri.parse('https://music.example.com/jf'),
        identity: testIdentity,
        token: 'tok-123',
        adapter: adapter,
        retries: 0,
        onUnauthorized: () => unauthorized++,
      ),
      userId: 'u1',
      libraryId: libraryId,
    );
  }

  FakeResponse page(List<Map<String, dynamic>> items) =>
      (status: 200, body: {'Items': items, 'TotalRecordCount': items.length});

  setUp(() => unauthorized = 0);

  test('sends the MediaBrowser authorization header', () async {
    final s = source((_) => page([]));
    await s.albums(const AlbumQuery());
    expect(
      adapter.last.headers['Authorization'],
      'MediaBrowser Client="Melody", Device="Test Phone", '
      'DeviceId="device-1", Version="1.2.3", Token="tok-123"',
    );
    expect(s.requestHeaders['Authorization'], contains('Token="tok-123"'));
  });

  test('lists albums with sorting, paging and the library filter', () async {
    final s = source(
      (_) => page([fixture('jellyfin/album.json')]),
      libraryId: 'lib1',
    );
    final result = await s.albums(
      const AlbumQuery(sort: AlbumSort.dateAdded, offset: 60, limit: 30),
    );
    expect(result.valueOrNull?.single.title, 'Gülümse');
    final request = adapter.last;
    expect(request.uri.path, '/jf/Items');
    expect(request.queryParameters, {
      'userId': 'u1',
      'Recursive': 'true',
      'Fields': 'DateCreated,Genres,ChildCount,NormalizationGain',
      'EnableImageTypes': 'Primary',
      'EnableTotalRecordCount': 'false',
      'IncludeItemTypes': 'MusicAlbum',
      'ParentId': 'lib1',
      'SortBy': 'DateCreated,SortName',
      'SortOrder': 'Descending',
      'StartIndex': '60',
      'Limit': '30',
    });
  });

  test('loads an album together with its tracks in disc order', () async {
    final s = source(
      (request) => request.queryParameters.containsKey('Ids')
          ? page([fixture('jellyfin/album.json')])
          : page([fixture('jellyfin/track.json')]),
    );
    final detail = (await s.album('a1')).valueOrNull;
    expect(detail?.album.id, 'a1');
    expect(detail?.tracks.single.title, 'Hadi Bakalım');
    final tracks = adapter.requests.firstWhere(
      (r) => r.queryParameters['IncludeItemTypes'] == 'Audio',
    );
    expect(tracks.queryParameters['ParentId'], 'a1');
    expect(
      tracks.queryParameters['SortBy'],
      'ParentIndexNumber,IndexNumber,SortName',
    );
  });

  test('a missing album is a NotFoundFailure', () async {
    final s = source((_) => page([]));
    expect((await s.album('nope')).failureOrNull, isA<NotFoundFailure>());
  });

  test('favourites and playlists use their own endpoints', () async {
    final s = source((_) => page([fixture('jellyfin/track.json')]));
    await s.favorites();
    expect(adapter.last.queryParameters['Filters'], 'IsFavorite');

    await s.tracks(const TrackQuery(playlistId: 'p1', offset: 5));
    expect(adapter.last.uri.path, '/jf/Playlists/p1/Items');
    expect(adapter.last.queryParameters['StartIndex'], '5');

    await s.tracks(const TrackQuery(sort: TrackSort.recentlyPlayed));
    expect(adapter.last.queryParameters['Filters'], 'IsPlayed');
    expect(adapter.last.queryParameters['SortOrder'], 'Descending');
  });

  test('only music views count as libraries', () async {
    final s = source(
      (_) => (status: 200, body: fixture('jellyfin/views.json')),
    );
    final libraries = (await s.libraries()).valueOrNull;
    expect(libraries?.map((l) => l.name), ['Müzik', 'Canlı Kayıtlar']);
    expect(adapter.last.uri.path, '/jf/Users/u1/Views');
  });

  test('search queries artists, albums, tracks and playlists', () async {
    final s = source(
      (request) => switch (request.queryParameters['IncludeItemTypes']) {
        'MusicAlbum' => page([fixture('jellyfin/album.json')]),
        'Audio' => page([fixture('jellyfin/track.json')]),
        'Playlist' => page([
          {'Id': 'p1', 'Name': 'Sezen mix', 'ChildCount': 4},
        ]),
        _ => page([fixture('jellyfin/artist.json')]),
      },
    );
    final result = (await s.search('sezen', limit: 5)).valueOrNull;
    expect(result?.artists.single.name, 'Sezen Aksu');
    expect(result?.albums.single.id, 'a1');
    expect(result?.tracks.single.id, 't1');
    expect(result?.playlists.single.trackCount, 4);
    expect(adapter.requests, hasLength(4));
    for (final request in adapter.requests) {
      expect(request.queryParameters['SearchTerm'], 'sezen');
      expect(request.queryParameters['Limit'], '5');
    }
  });

  test('favourites are set with POST and cleared with DELETE', () async {
    final s = source((_) => (status: 200, body: {'IsFavorite': true}));
    expect((await s.setFavorite('a1', value: true)).isOk, isTrue);
    expect(adapter.last.method, 'POST');
    expect(adapter.last.uri.path, '/jf/Users/u1/FavoriteItems/a1');
    await s.setFavorite('a1', value: false);
    expect(adapter.last.method, 'DELETE');
  });

  test('HTTP errors become failures and 401 reports the session', () async {
    var s = source((_) => (status: 401, body: null));
    expect(
      (await s.albums(const AlbumQuery())).failureOrNull,
      isA<UnauthorizedFailure>(),
    );
    expect(unauthorized, 1);

    s = source((_) => (status: 503, body: null));
    final failure = (await s.genres()).failureOrNull;
    expect(failure, isA<ServerFailure>());
    expect((failure! as ServerFailure).statusCode, 503);

    s = source(connectionError);
    expect((await s.playlists()).failureOrNull, isA<NetworkFailure>());
    expect(unauthorized, 1);
  });

  test('a malformed body is a ParsingFailure', () async {
    final s = source((_) => (status: 200, body: {'Items': 'oops'}));
    expect(
      (await s.albums(const AlbumQuery())).failureOrNull,
      isA<ParsingFailure>(),
    );
  });

  test('builds artwork and stream addresses', () {
    final s = source((_) => page([]));
    expect(s.artworkUri(null), isNull);
    final art = s.artworkUri(
      const Artwork(itemId: 'a1', tag: 'tagA'),
      size: 320,
    );
    expect(art?.path, '/jf/Items/a1/Images/Primary');
    expect(art?.queryParameters, {
      'fillWidth': '320',
      'fillHeight': '320',
      'quality': '90',
      'tag': 'tagA',
    });

    final stream = s.streamUri(
      makeTrack('t1'),
      const StreamOptions(maxBitrateKbps: 320),
    );
    expect(stream.path, '/jf/Audio/t1/universal');
    expect(stream.queryParameters['MaxStreamingBitrate'], '320000');
    expect(stream.queryParameters['api_key'], 'tok-123');
    expect(stream.queryParameters['UserId'], 'u1');
    expect(
      s.streamUri(makeTrack('t1')).queryParameters,
      isNot(contains('MaxStreamingBitrate')),
    );
  });

  test('playback is reported to the session endpoints', () async {
    final s = source((_) => (status: 204, body: null));
    for (final kind in PlaybackEventKind.values) {
      final result = await s.reportPlayback(
        PlaybackReport(
          kind: kind,
          trackId: 't1',
          position: const Duration(seconds: 2),
          sessionId: 'sess',
          isPaused: kind == PlaybackEventKind.progress,
        ),
      );
      expect(result.isOk, isTrue);
    }
    expect(adapter.requests.map((r) => r.uri.path), [
      '/jf/Sessions/Playing',
      '/jf/Sessions/Playing/Progress',
      '/jf/Sessions/Playing/Stopped',
    ]);
    final body = adapter.requests[1].data as Map<String, Object?>;
    expect(body['ItemId'], 't1');
    expect(body['PositionTicks'], 20000000);
    expect(body['PlaySessionId'], 'sess');
    expect(body['IsPaused'], isTrue);
    expect(s.capabilities.playbackReporting, isTrue);
  });

  test('playlists can be created, edited and deleted', () async {
    final s = source((request) => (status: 200, body: {'Id': 'pl9'}));
    final created = await s.createPlaylist('Yol', ['t1', 't2']);
    expect(created.valueOrNull?.id, 'pl9');
    expect(adapter.last.uri.path, '/jf/Playlists');
    expect(adapter.last.data, {
      'Name': 'Yol',
      'Ids': ['t1', 't2'],
      'UserId': 'u1',
      'MediaType': 'Audio',
    });

    await s.addToPlaylist('pl9', ['t3', 't4']);
    expect(adapter.last.uri.path, '/jf/Playlists/pl9/Items');
    expect(adapter.last.queryParameters, {'ids': 't3,t4', 'userId': 'u1'});

    await s.removeFromPlaylist('pl9', ['e1', 'e2']);
    expect(adapter.last.method, 'DELETE');
    expect(adapter.last.queryParameters, {'entryIds': 'e1,e2'});

    await s.movePlaylistItem('pl9', 'e3', 0);
    expect(adapter.last.uri.path, '/jf/Playlists/pl9/Items/e3/Move/0');

    await s.renamePlaylist('pl9', 'Yeni');
    expect(adapter.last.uri.path, '/jf/Playlists/pl9');
    expect(adapter.last.data, {'Name': 'Yeni'});

    await s.deletePlaylist('pl9');
    expect(adapter.last.method, 'DELETE');
    expect(adapter.last.uri.path, '/jf/Items/pl9');
    expect(s.capabilities.editablePlaylists, isTrue);
  });

  test('playlist entries keep their entry id', () async {
    final s = source(
      (_) => page([
        {...fixture('jellyfin/track.json'), 'PlaylistItemId': 'entry-1'},
      ]),
    );
    final tracks = await s.tracks(const TrackQuery(playlistId: 'p1'));
    expect(tracks.valueOrNull?.single.playlistItemId, 'entry-1');
  });

  test('lyrics come from the server, missing ones are null', () async {
    var s = source(
      (_) => (
        status: 200,
        body: {
          'Lyrics': [
            {'Text': 'Bir', 'Start': 0},
            {'Text': 'İki', 'Start': 25000000},
          ],
        },
      ),
    );
    final lyrics = (await s.lyrics(makeTrack('t1'))).valueOrNull;
    expect(adapter.last.uri.path, '/jf/Audio/t1/Lyrics');
    expect(lyrics?.synced, isTrue);
    expect(lyrics?.lines.last.start, const Duration(milliseconds: 2500));

    s = source(
      (_) => (
        status: 200,
        body: {
          'Lyrics': [
            {'Text': 'Düz metin'},
          ],
        },
      ),
    );
    expect((await s.lyrics(makeTrack('t1'))).valueOrNull?.synced, isFalse);

    s = source((_) => (status: 404, body: null));
    final missing = await s.lyrics(makeTrack('t1'));
    expect(missing.isOk, isTrue);
    expect(missing.valueOrNull, isNull);
  });

  test('stream formats ask the server for the right container', () {
    final s = source((_) => page([]));
    Map<String, String> query(StreamFormat f, [int? kbps]) => s
        .streamUri(
          makeTrack('t1'),
          StreamOptions(format: f, maxBitrateKbps: kbps),
        )
        .queryParameters;
    expect(query(StreamFormat.mp3)['Container'], 'mp3');
    expect(query(StreamFormat.mp3)['TranscodingProtocol'], 'http');
    expect(query(StreamFormat.opus)['AudioCodec'], 'opus');
    expect(query(StreamFormat.aac, 128)['MaxStreamingBitrate'], '128000');
    expect(query(StreamFormat.original)['TranscodingProtocol'], 'hls');
    expect(
      const StreamOptions().isOriginal &&
          !const StreamOptions(maxBitrateKbps: 1).isOriginal,
      isTrue,
    );
  });

  test('profile picture: read, upload as base64 PNG, remove', () async {
    final s = source(
      (r) => r.path.endsWith('Users/Me')
          ? (status: 200, body: {'Id': 'u1', 'PrimaryImageTag': 'abc'})
          : (status: 204, body: null),
    );
    final uri = await s.avatar();
    expect(uri!.path, '/jf/Users/u1/Images/Primary');
    expect(uri.queryParameters['tag'], 'abc');

    await s.setAvatar([1, 2, 3]);
    final upload = adapter.last;
    expect(upload.method, 'POST');
    expect(upload.path, 'UserImage');
    expect(upload.queryParameters['userId'], 'u1');
    expect(upload.contentType, 'image/png');
    expect(upload.data, 'AQID');

    await s.removeAvatar();
    expect(adapter.last.method, 'DELETE');
    expect(adapter.last.path, 'UserImage');
  });
}
