import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/data/sources/lrclib/lrclib_client.dart';
import 'package:melody/domain/models/media.dart';

import '../helpers/fakes.dart';

void main() {
  final track = makeTrack('t1', title: 'Firuze').copyWith(
    albumTitle: 'Firuze',
    artists: const [NamedRef(id: 'a', name: 'Sezen Aksu')],
  );

  test('sends only title, artist, album and duration', () async {
    final adapter = FakeHttpAdapter(
      (_) => (
        status: 200,
        body: {'syncedLyrics': '[00:01.00]Firuze', 'plainLyrics': 'Firuze'},
      ),
    );
    final lyrics = (await LrclibClient(adapter: adapter).lookup(track))
        .valueOrNull;
    expect(lyrics?.synced, isTrue);
    expect(lyrics?.origin, LyricsOrigin.lrclib);
    final request = adapter.last;
    expect(request.uri.host, 'lrclib.net');
    expect(request.queryParameters, {
      'track_name': 'Firuze',
      'artist_name': 'Sezen Aksu',
      'album_name': 'Firuze',
      'duration': 185,
    });
    expect(request.headers['User-Agent'], startsWith('Melody'));
    expect(request.headers.containsKey('Authorization'), isFalse);
  });

  test('falls back to plain lyrics; 404 and instrumental mean none', () async {
    var client = LrclibClient(
      adapter: FakeHttpAdapter(
        (_) => (status: 200, body: {'plainLyrics': 'Satır'}),
      ),
    );
    expect((await client.lookup(track)).valueOrNull?.synced, isFalse);

    client = LrclibClient(
      adapter: FakeHttpAdapter((_) => (status: 404, body: null)),
    );
    final missing = await client.lookup(track);
    expect(missing.isOk, isTrue);
    expect(missing.valueOrNull, isNull);

    client = LrclibClient(
      adapter: FakeHttpAdapter(
        (_) => (status: 200, body: {'instrumental': true}),
      ),
    );
    expect((await client.lookup(track)).valueOrNull, isNull);

    client = LrclibClient(adapter: FakeHttpAdapter(connectionError));
    expect((await client.lookup(track)).failureOrNull, isA<NetworkFailure>());
  });
}
