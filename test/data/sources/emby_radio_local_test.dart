import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/config/feature_flags.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/data/sources/emby/emby.dart';
import 'package:melody/data/sources/local/local_source.dart';
import 'package:melody/data/sources/radio/radio_source.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fakes.dart';

class _FakeMedia implements DeviceMedia {
  bool allowed = false;
  bool grant = true;
  int scans = 0;
  List<Map<String, Object?>> rows = [];

  @override
  Future<bool> hasPermission() async => allowed;

  @override
  Future<bool> requestPermission() async => allowed = grant;

  @override
  Future<List<Map<String, Object?>>> scan() async {
    scans++;
    return rows;
  }
}

void main() {
  group('Emby', () {
    test('uses its own header, type and no Quick Connect', () async {
      final adapter = FakeHttpAdapter(
        (_) => (
          status: 200,
          body: {'ServerName': 'Emby', 'Version': '4.8', 'Id': 'e1'},
        ),
      );
      final c = EmbyConnector(identity: testIdentity, adapter: adapter);
      final server = (await c.probe('https://emby.example.com')).valueOrNull!;
      expect(server.type, SourceType.emby);
      expect(adapter.last.headers.containsKey(Emby.authHeader), isTrue);
      expect((await c.quickConnectAvailable(server)).valueOrNull, isFalse);
    });

    test('has no lyrics endpoint', () async {
      final s = EmbyMusicSource(
        api: Emby.api(baseUrl: Uri.parse('https://e'), identity: testIdentity),
        userId: 'u1',
      );
      expect(s.capabilities.lyrics, isFalse);
      expect((await s.lyrics(makeTrack('t1'))).valueOrNull, isNull);
      expect(s.requestHeaders.keys, [Emby.authHeader]);
    });
  });

  group('Radio', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    const station = {
      'stationuuid': 'uuid-1',
      'name': ' Radyo Melodi ',
      'url': 'http://old',
      'url_resolved': 'https://stream.example.com/live',
      'favicon': 'https://example.com/logo.png',
      'tags': 'pop, turkish,',
      'country': 'Türkiye',
      'codec': 'MP3',
    };

    test('stations map to playable tracks', () {
      final t = RadioSource.station(station)!;
      expect(t.title, 'Radyo Melodi');
      expect(t.genres, ['pop', 'turkish']);
      expect(t.container, 'mp3');
      final source = RadioSource(prefs: prefs);
      expect(source.streamUri(t).toString(), 'https://stream.example.com/live');
      expect(
        source.artworkUri(t.artwork).toString(),
        'https://example.com/logo.png',
      );
      expect(RadioSource.station({'name': 'x'}), isNull);
    });

    test('lists by tag, counts clicks and keeps favourites', () async {
      final adapter = FakeHttpAdapter((_) => (status: 200, body: [station]));
      final source = RadioSource(prefs: prefs, adapter: adapter);
      final list = (await source.tracks(const TrackQuery(genreId: 'pop')))
          .valueOrNull!;
      expect(adapter.last.uri.queryParameters['tag'], 'pop');
      expect(list.single.isFavorite, isFalse);

      await source.setFavorite(list.single.id, value: true);
      expect(
        (await source.favorites()).valueOrNull!.single.title,
        'Radyo Melodi',
      );
      final again = (await source.tracks(const TrackQuery())).valueOrNull!;
      expect(again.single.isFavorite, isTrue);

      await source.reportPlayback(
        PlaybackReport(
          kind: PlaybackEventKind.start,
          trackId: list.single.id,
          position: Duration.zero,
          sessionId: 's',
        ),
      );
      expect(adapter.last.uri.path, '/json/url/uuid-1');
    });

    test('custom stations play their own address', () async {
      final source = RadioSource(prefs: prefs);
      final t = await source.addCustomStation(
        'Ev',
        Uri.parse('http://10.0.0.2/live'),
      );
      expect(source.streamUri(t).toString(), 'http://10.0.0.2/live');
      expect((await source.favorites()).valueOrNull, [t]);
    });
  });

  group('Device files', () {
    final rows = [
      {
        'id': 1,
        'title': 'B',
        'artist': 'Sezen',
        'artistId': '9',
        'album': 'Gülümse',
        'albumId': '5',
        'duration': 180000,
        'track': 2002,
        'year': 1991,
        'mime': 'audio/flac',
      },
      {
        'id': 2,
        'title': 'A',
        'artist': 'Sezen',
        'artistId': '9',
        'album': 'Gülümse',
        'albumId': '5',
        'duration': 200000,
        'track': 1001,
        'mime': 'audio/mpeg',
      },
      {
        'id': 3,
        'title': 'C',
        'artist': '<unknown>',
        'album': 'Diğer',
        'albumId': '6',
      },
    ];

    test('groups files into albums and artists', () async {
      final media = _FakeMedia()
        ..allowed = true
        ..rows = rows;
      final s = LocalSource(media: media);
      final albums = (await s.albums(const AlbumQuery())).valueOrNull!;
      expect(albums.map((a) => a.title), ['Diğer', 'Gülümse']);
      final detail = (await s.album('5')).valueOrNull!;
      expect(detail.tracks.map((t) => t.title), ['A', 'B']);
      expect(detail.tracks.last.discNumber, 2);
      expect(detail.album.duration, const Duration(seconds: 380));
      expect((await s.artists()).valueOrNull!.single.name, 'Sezen');
      expect((await s.search('gül')).valueOrNull!.albums.single.id, '5');
      expect(
        s.streamUri(detail.tracks.first).toString(),
        'content://media/external/audio/media/2',
      );
      expect(media.scans, 1);
    });

    test('needs permission, asked only when adding the source', () async {
      final media = _FakeMedia()..grant = false;
      expect(
        (await LocalSource(media: media).tracks(const TrackQuery()))
            .failureOrNull,
        isA<UnauthorizedFailure>(),
      );
      final connector = LocalConnector(media: media);
      final device = (await connector.probe('')).valueOrNull!;
      expect(
        (await connector.signIn(
          device,
          username: '',
          password: '',
        )).failureOrNull,
        isA<UnauthorizedFailure>(),
      );
      media.grant = true;
      final session = (await connector.signIn(
        device,
        username: '',
        password: '',
      )).valueOrNull!;
      expect(session.account.type, SourceType.local);
    });
  });

  test('a station track has no album link', () {
    expect(const Track(id: 'custom|x', title: 'x').albumId, isNull);
  });
}
