import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/config/feature_flags.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/data/sources/subsonic/subsonic_api.dart';
import 'package:melody/data/sources/subsonic/subsonic_connector.dart';
import 'package:melody/data/sources/subsonic/subsonic_music_source.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/repositories/music_source.dart';

import '../../helpers/fakes.dart';

Map<String, Object?> ok(Map<String, Object?> body) => {
  'subsonic-response': {
    'status': 'ok',
    'version': '1.16.1',
    'type': 'navidrome',
    'serverVersion': '0.53.0',
    ...body,
  },
};

Map<String, Object?> failed(int code) => {
  'subsonic-response': {
    'status': 'failed',
    'error': {'code': code, 'message': 'nope'},
  },
};

const Map<String, Object?> song = {
  'id': 's1',
  'title': 'Firuze',
  'artist': 'Sezen',
  'artistId': 'ar1',
  'album': 'Gülümse',
  'albumId': 'al1',
  'duration': 245,
  'track': 3,
  'discNumber': 1,
  'year': 1991,
  'coverArt': 'al-al1',
  'suffix': 'flac',
  'starred': '2024-01-01T00:00:00Z',
  'playCount': 7,
  'genre': 'Pop',
  'replayGain': {'trackGain': -6.5, 'albumGain': -7.0},
};

void main() {
  final base = Uri.parse('https://music.example.com');
  const credentials = SubsonicCredentials(
    user: 'ayla',
    token: 't0k',
    salt: 's4lt',
  );
  late FakeHttpAdapter adapter;

  SubsonicMusicSource source(FakeResponse Function(RequestOptions) handler) {
    adapter = FakeHttpAdapter(handler);
    return SubsonicMusicSource(
      api: SubsonicApi(
        baseUrl: base,
        credentials: credentials,
        adapter: adapter,
      ),
    );
  }

  test('credentials are a salted md5 token, never the password', () {
    final c = SubsonicCredentials.fromPassword(
      'ayla',
      'secret',
      random: Random(1),
    );
    expect(c.token, md5.convert(utf8.encode('secret${c.salt}')).toString());
    expect(c.encode(), isNot(contains('secret')));
    final back = SubsonicCredentials.decode('ayla', c.encode());
    expect((back.token, back.salt), (c.token, c.salt));
  });

  test('every request carries the auth parameters and asks for JSON', () async {
    final s = source(
      (_) => (
        status: 200,
        body: ok({
          'albumList2': {'album': <Object?>[]},
        }),
      ),
    );
    await s.albums(const AlbumQuery(sort: AlbumSort.dateAdded, limit: 5));
    final q = adapter.last.uri.queryParameters;
    expect(adapter.last.uri.path, '/rest/getAlbumList2');
    expect(q['u'], 'ayla');
    expect(q['t'], 't0k');
    expect(q['s'], 's4lt');
    expect(q['f'], 'json');
    expect(q['type'], 'newest');
    expect(q['size'], '5');
  });

  test('maps songs with gain, favourite and cover', () async {
    final s = source(
      (_) => (
        status: 200,
        body: ok({
          'album': {
            'id': 'al1',
            'name': 'Gülümse',
            'song': [song],
          },
        }),
      ),
    );
    final detail = (await s.album('al1')).valueOrNull!;
    final t = detail.tracks.single;
    expect(t.title, 'Firuze');
    expect(t.artistLine, 'Sezen');
    expect(t.duration, const Duration(seconds: 245));
    expect(t.isFavorite, isTrue);
    expect(t.trackGainDb, -6.5);
    expect(t.genres, ['Pop']);
    expect(
      s.artworkUri(t.artwork, size: 320)?.queryParameters,
      containsPair('id', 'al-al1'),
    );
    expect(s.streamUri(t).path, '/rest/stream');
    expect(
      s
          .streamUri(
            t,
            const StreamOptions(maxBitrateKbps: 128, format: StreamFormat.opus),
          )
          .queryParameters,
      allOf(containsPair('maxBitRate', '128'), containsPair('format', 'opus')),
    );
  });

  test('server errors become failures', () async {
    final s = source((_) => (status: 200, body: failed(70)));
    expect((await s.album('x')).failureOrNull, isA<NotFoundFailure>());
    final s2 = source((_) => (status: 200, body: failed(40)));
    expect((await s2.playlists()).failureOrNull, isA<UnauthorizedFailure>());
  });

  test('playlist entries are removed by position', () async {
    final s = source(
      (_) => (
        status: 200,
        body: ok({
          'playlist': {
            'id': 'p1',
            'entry': [song, song],
          },
        }),
      ),
    );
    final tracks = (await s.tracks(const TrackQuery(playlistId: 'p1')))
        .valueOrNull!;
    expect(tracks.map((t) => t.playlistItemId), ['0', '1']);
    await s.removeFromPlaylist('p1', ['1']);
    expect(adapter.last.uri.queryParametersAll['songIndexToRemove'], ['1']);
  });

  test('synced OpenSubsonic lyrics are used', () async {
    final s = source(
      (_) => (
        status: 200,
        body: ok({
          'lyricsList': {
            'structuredLyrics': [
              {
                'synced': true,
                'line': [
                  {'start': 1000, 'value': 'Bir'},
                  {'start': 2500, 'value': 'İki'},
                ],
              },
            ],
          },
        }),
      ),
    );
    final lyrics = (await s.lyrics(SubsonicMapperTestTrack.firuze))
        .valueOrNull!;
    expect(lyrics.synced, isTrue);
    expect(lyrics.lines.last.start, const Duration(milliseconds: 2500));
  });

  test('a scrobble is sent only after a real listen', () async {
    final s = source((_) => (status: 200, body: ok({})));
    await s.reportPlayback(
      const PlaybackReport(
        kind: PlaybackEventKind.stopped,
        trackId: 's1',
        position: Duration(seconds: 10),
        sessionId: 'x',
      ),
    );
    expect(adapter.requests, isEmpty);
    await s.reportPlayback(
      const PlaybackReport(
        kind: PlaybackEventKind.stopped,
        trackId: 's1',
        position: Duration(minutes: 2),
        sessionId: 'x',
      ),
    );
    expect(adapter.last.uri.queryParameters['submission'], 'true');
  });

  group('connector', () {
    test('a ping, even refused, proves the address', () async {
      adapter = FakeHttpAdapter(
        (r) => r.uri.port == 4533 && r.uri.scheme == 'http'
            ? (status: 200, body: failed(10))
            : connectionError(r),
      );
      final server = (await SubsonicConnector(
        adapter: adapter,
      ).probe('nas.local')).valueOrNull!;
      expect(server.baseUrl.toString(), 'http://nas.local:4533');
      expect(server.type, SourceType.subsonic);
    });

    test('signs in and keeps only the token', () async {
      adapter = FakeHttpAdapter((_) => (status: 200, body: ok({})));
      final c = SubsonicConnector(adapter: adapter, random: Random(2));
      final probe = (await c.probe('https://music.example.com')).valueOrNull!;
      final session = (await c.signIn(
        probe,
        username: 'ayla',
        password: 'secret',
      )).valueOrNull!;
      expect(session.account.type, SourceType.subsonic);
      expect(session.accessToken, isNot(contains('secret')));
      expect(adapter.last.uri.queryParameters['p'], isNull);
    });

    test('wrong password is reported', () async {
      adapter = FakeHttpAdapter((_) => (status: 200, body: failed(40)));
      final c = SubsonicConnector(adapter: adapter);
      final probe = (await c.probe('https://music.example.com')).valueOrNull!;
      final result = await c.signIn(probe, username: 'a', password: 'b');
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });
  });
}

/// A track for lyric lookups.
abstract final class SubsonicMapperTestTrack {
  static final Track firuze = makeTrack('s1', title: 'Firuze');
}
