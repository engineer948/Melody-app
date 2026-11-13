import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/data/db/app_database.dart';
import 'package:melody/data/repositories/catalog_cache.dart';
import 'package:melody/data/repositories/library_repository.dart';
import 'package:melody/domain/repositories/music_source.dart';

import '../helpers/fakes.dart';

void main() {
  late AppDatabase db;
  late FakeMusicSource source;
  late LibraryRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    source = FakeMusicSource();
    repository = LibraryRepository(
      source: source,
      accountId: 'acc',
      cache: CatalogCache(db),
    );
  });
  tearDown(() => db.close());

  const query = AlbumQuery();

  test('first load comes from the source and fills the cache', () async {
    final emitted = await repository.albums(query).toList();
    expect(emitted, hasLength(1));
    expect(emitted.single.fromCache, isFalse);
    expect(emitted.single.value.map((a) => a.id), ['a1', 'a2']);
  });

  test('later loads show the cache first, then fresh data', () async {
    await repository.albums(query).drain<void>();
    source.albumItems = [makeAlbum('a3')];

    final emitted = await repository.albums(query).toList();
    expect(emitted, hasLength(2));
    expect(emitted[0].fromCache, isTrue);
    expect(emitted[0].value.map((a) => a.id), ['a1', 'a2']);
    expect(emitted[1].fromCache, isFalse);
    expect(emitted[1].value.map((a) => a.id), ['a3']);

    // Items that disappeared from the source leave the cached listing too.
    source.failure = const NetworkFailure();
    final offline = await repository.albums(query).toList();
    expect(offline.first.value.map((a) => a.id), ['a3']);
  });

  test('offline with a cache keeps the cached copy and says why', () async {
    await repository.albums(query).drain<void>();
    source.failure = const NetworkFailure();

    final emitted = await repository.albums(query).toList();
    expect(emitted.last.fromCache, isTrue);
    expect(emitted.last.refreshFailure, isA<NetworkFailure>());
    expect(emitted.last.value, hasLength(2));
  });

  test('offline without a cache fails', () async {
    source.failure = const TimeoutFailure();
    await expectLater(
      repository.albums(query).toList(),
      throwsA(isA<TimeoutFailure>()),
    );
  });

  test('offline without a cache falls back to downloaded songs', () async {
    final downloaded = [
      makeTrack(
        't2',
        albumId: 'alb',
      ).copyWith(albumTitle: 'Gülümse', albumArtist: 'Sezen', trackNumber: 2),
      makeTrack(
        't1',
        albumId: 'alb',
      ).copyWith(albumTitle: 'Gülümse', albumArtist: 'Sezen', trackNumber: 1),
    ];
    final offline = LibraryRepository(
      source: source,
      accountId: 'acc',
      cache: CatalogCache(db),
      downloaded: () => downloaded,
    );
    source.failure = const NetworkFailure();

    final albums = await offline.albums(query).last;
    expect(albums.value.single.title, 'Gülümse');
    expect(albums.value.single.artwork?.itemId, 'alb');
    expect(albums.refreshFailure, isA<NetworkFailure>());

    final detail = await offline.album('alb').last;
    expect(detail.value.tracks.map((t) => t.id), ['t1', 't2']);
    expect(detail.value.album.title, 'Gülümse');

    final songs = await offline.tracks(const TrackQuery(albumId: 'alb')).last;
    expect(songs.value, hasLength(2));
    await expectLater(
      offline.album('other').toList(),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('listings with different filters do not share a cache', () async {
    await repository.albums(query).drain<void>();
    source.failure = const NetworkFailure();
    await expectLater(
      repository.albums(const AlbumQuery(genreId: 'g1')).toList(),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('further pages are appended to the cached listing', () async {
    source.albumItems = [for (var i = 0; i < 5; i++) makeAlbum('a$i')];
    await repository.albums(query.page(0, 2)).drain<void>();
    final more = await repository.moreAlbums(query.page(2, 2));
    expect(more.valueOrNull?.map((a) => a.id), ['a2', 'a3']);

    source.failure = const NetworkFailure();
    final offline = await repository.albums(query.page(0, 2)).toList();
    expect(offline.last.value.map((a) => a.id), ['a0', 'a1', 'a2', 'a3']);
  });

  test('album pages are cached as a whole', () async {
    await repository.album('a1').drain<void>();
    source.failure = const NetworkFailure();
    final emitted = await repository.album('a1').toList();
    expect(emitted.last.value.album.id, 'a1');
    expect(emitted.last.value.tracks, hasLength(2));
    expect(emitted.last.refreshFailure, isNotNull);
  });

  test('search falls back to the cache only when offline', () async {
    await repository.albums(query).drain<void>();
    await repository.tracks(const TrackQuery()).drain<void>();

    final online = await repository.search('gül');
    expect(online.valueOrNull?.fromCache, isFalse);

    source.failure = const NetworkFailure();
    final offline = (await repository.search('GÜL')).valueOrNull;
    expect(offline?.fromCache, isTrue);
    expect(offline?.value.albums.single.title, 'Gülümse');
    expect(offline?.value.tracks, isEmpty);

    source.failure = const ServerFailure(statusCode: 500);
    expect(
      (await repository.search('gül')).failureOrNull,
      isA<ServerFailure>(),
    );
  });

  test('favouriting an album updates the cached page', () async {
    await repository.album('a1').drain<void>();
    expect((await repository.setAlbumFavorite('a1', value: true)).isOk, isTrue);
    expect(source.favoriteCalls, [('a1', true)]);

    source.failure = const NetworkFailure();
    final cached = await repository.album('a1').first;
    expect(cached.value.album.isFavorite, isTrue);

    final failed = await repository.setAlbumFavorite('a1', value: false);
    expect(failed.failureOrNull, isA<NetworkFailure>());
    expect((await repository.album('a1').first).value.album.isFavorite, isTrue);
  });
}
