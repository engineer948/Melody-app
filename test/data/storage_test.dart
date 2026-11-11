import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/data/db/app_database.dart';
import 'package:melody/data/repositories/account_store.dart';
import 'package:melody/data/repositories/catalog_cache.dart';
import 'package:melody/data/repositories/token_store.dart';
import 'package:melody/domain/models/media.dart';

import '../helpers/fakes.dart';

void main() {
  late AppDatabase db;
  late CatalogCache cache;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    cache = CatalogCache(db);
  });
  tearDown(() => db.close());

  group('CatalogCache', () {
    test('lists keep their order and can be extended', () async {
      final first = [makeAlbum('b'), makeAlbum('a')];
      await cache.writeList('acc', 'albums', CacheKind.album, first);
      expect(await cache.readList('acc', 'albums', CacheKind.album), first);

      await cache.writeList('acc', 'albums', CacheKind.album, [
        makeAlbum('c'),
        makeAlbum('a'),
      ], append: true);
      expect(
        (await cache.readList(
          'acc',
          'albums',
          CacheKind.album,
        )).map((a) => a.id),
        ['b', 'a', 'c'],
      );
    });

    test('rewriting a list replaces it and refreshes its items', () async {
      await cache.writeList('acc', 'albums', CacheKind.album, [
        makeAlbum('a', title: 'Old'),
        makeAlbum('b'),
      ]);
      await cache.writeList('acc', 'albums', CacheKind.album, [
        makeAlbum('a', title: 'New'),
      ]);
      final albums = await cache.readList('acc', 'albums', CacheKind.album);
      expect(albums.single.title, 'New');
    });

    test('accounts and kinds are kept apart', () async {
      await cache.writeList('acc1', 'k', CacheKind.album, [makeAlbum('x')]);
      await cache.writeList('acc1', 'k2', CacheKind.track, [makeTrack('x')]);
      expect(await cache.readList('acc2', 'k', CacheKind.album), isEmpty);
      expect(await cache.readList('acc1', 'missing', CacheKind.album), isEmpty);
      expect(
        await cache.readItem('acc1', CacheKind.album, 'x'),
        makeAlbum('x'),
      );
      expect(
        await cache.readItem('acc1', CacheKind.track, 'x'),
        makeTrack('x'),
      );
      expect(await cache.readItem('acc1', CacheKind.artist, 'x'), isNull);
    });

    test('handles lists longer than the SQLite variable limit', () async {
      final many = [for (var i = 0; i < 1200; i++) makeTrack('t$i')];
      await cache.writeList('acc', 'tracks', CacheKind.track, many);
      final read = await cache.readList('acc', 'tracks', CacheKind.track);
      expect(read, hasLength(1200));
      expect(read.last.id, 't1199');
    });

    test(
      'searches names without case and treats wildcards literally',
      () async {
        await cache.writeList('acc', 'k', CacheKind.album, [
          makeAlbum('1', title: 'Gülümse'),
          makeAlbum('2', title: '100% Hit'),
          makeAlbum('3', title: 'Deli'),
        ]);
        Future<List<String>> find(String q) async => [
          for (final a in await cache.search('acc', CacheKind.album, q))
            a.title,
        ];
        expect(await find('gül'), ['Gülümse']);
        expect(await find('DELI'), ['Deli']);
        expect(await find('%'), ['100% Hit']);
        expect(await find('zzz'), isEmpty);
        expect(await cache.search('other', CacheKind.album, 'deli'), isEmpty);
      },
    );

    test('stores details and updates them in place', () async {
      final detail = AlbumDetail(
        album: makeAlbum('a'),
        tracks: [makeTrack('t1')],
      );
      await cache.writeItem('acc', CacheKind.albumDetail, detail);
      await cache.updateItem(
        'acc',
        CacheKind.albumDetail,
        'a',
        (d) => d.copyWith(album: d.album.copyWith(isFavorite: true)),
      );
      final read = await cache.readItem('acc', CacheKind.albumDetail, 'a');
      expect(read?.album.isFavorite, isTrue);
      expect(read?.tracks, detail.tracks);
    });

    test('clearing an account leaves the others alone', () async {
      await cache.writeList('acc1', 'k', CacheKind.album, [makeAlbum('x')]);
      await cache.writeList('acc2', 'k', CacheKind.album, [makeAlbum('y')]);
      await cache.clearAccount('acc1');
      expect(await cache.readList('acc1', 'k', CacheKind.album), isEmpty);
      expect(await cache.readList('acc2', 'k', CacheKind.album), hasLength(1));
    });

    test('unreadable rows count as a miss', () async {
      await db
          .into(db.cachedItems)
          .insert(
            CachedItemsCompanion.insert(
              accountId: 'acc',
              kind: 'album',
              itemId: 'bad',
              name: 'bad',
              payload: '{"nope":',
              updatedAt: DateTime.now(),
            ),
          );
      expect(await cache.readItem('acc', CacheKind.album, 'bad'), isNull);
      expect(await cache.search('acc', CacheKind.album, 'bad'), isEmpty);
    });
  });

  group('AccountStore', () {
    test('saves accounts in the database and tokens separately', () async {
      final tokens = MemoryTokenStore();
      final store = AccountStore(db, tokens);
      await store.save(testAccount, token: 'tok');
      await store.save(testAccount.copyWith(libraryId: 'lib1'));

      final loaded = await store.loadAll();
      expect(loaded.single.account.libraryId, 'lib1');
      expect(loaded.single.token, 'tok');

      final rows = await db.select(db.accounts).get();
      expect(rows.single.payload, isNot(contains('tok')));
    });

    test('clearing a token keeps the account', () async {
      final store = AccountStore(db, MemoryTokenStore());
      await store.save(testAccount, token: 'tok');
      await store.clearToken(testAccount.id);
      final loaded = await store.loadAll();
      expect(loaded.single.account, testAccount);
      expect(loaded.single.token, isNull);
    });

    test('removing an account forgets its token', () async {
      final tokens = MemoryTokenStore();
      final store = AccountStore(db, tokens);
      await store.save(testAccount, token: 'tok');
      await store.remove(testAccount.id);
      expect(await store.loadAll(), isEmpty);
      expect(await tokens.read(testAccount.id), isNull);
    });
  });
}
