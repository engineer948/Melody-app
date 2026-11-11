import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/router/app_router.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/data/repositories/catalog_cache.dart';
import 'package:melody/data/repositories/token_store.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/library/library_providers.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  final other = testAccount.copyWith(id: 'jellyfin:srv1:u2', userName: 'deniz');

  test('starts signed out without saved accounts', () async {
    final container = await createContainer(signedIn: false);
    final session = container.read(sessionControllerProvider);
    expect(session.active, isNull);
    expect(container.read(activeSourceProvider), isNull);
    expect(container.read(libraryRepositoryProvider), isNull);
  });

  test('restores the saved active account', () async {
    final container = await createContainer(
      preferences: {SessionController.activeKey: testAccount.id},
    );
    final session = container.read(sessionControllerProvider);
    expect(session.active, testAccount);
    expect(session.activeExpired, isFalse);
    expect(
      container.read(libraryRepositoryProvider)?.accountId,
      testAccount.id,
    );
  });

  test('signing in stores the account and its token', () async {
    final tokens = MemoryTokenStore();
    final container = await createContainer(signedIn: false, tokens: tokens);
    final controller = container.read(sessionControllerProvider.notifier);

    await controller.signedIn(
      AuthSession(account: testAccount, accessToken: 'tok-a'),
    );
    await controller.signedIn(
      AuthSession(account: other, accessToken: 'tok-b'),
    );

    final session = container.read(sessionControllerProvider);
    expect(session.accounts, [testAccount, other]);
    expect(session.active, other);
    expect(await tokens.read(testAccount.id), 'tok-a');
    expect(await tokens.read(other.id), 'tok-b');

    final stored = await container.read(accountStoreProvider).loadAll();
    expect(stored.map((s) => s.account.id), [testAccount.id, other.id]);
  });

  test('signing in again keeps the library choice', () async {
    final container = await createContainer();
    final controller = container.read(sessionControllerProvider.notifier);
    await controller.setLibrary(testAccount.id, 'lib2');
    await controller.signedIn(
      AuthSession(account: testAccount, accessToken: 'new'),
    );
    final session = container.read(sessionControllerProvider);
    expect(session.accounts, hasLength(1));
    expect(session.active?.libraryId, 'lib2');
    expect(session.activeToken, 'new');
  });

  test('switching accounts changes the library in use', () async {
    final container = await createContainer();
    final controller = container.read(sessionControllerProvider.notifier);
    await controller.signedIn(AuthSession(account: other, accessToken: 't'));
    expect(container.read(libraryRepositoryProvider)?.accountId, other.id);

    await controller.switchTo(testAccount.id);
    expect(
      container.read(libraryRepositoryProvider)?.accountId,
      testAccount.id,
    );

    await controller.switchTo('unknown');
    expect(container.read(sessionControllerProvider).activeId, testAccount.id);
  });

  test('an expired token asks for a new sign-in', () async {
    final tokens = MemoryTokenStore({testAccount.id: 'token-1'});
    final container = await createContainer(tokens: tokens);
    await container
        .read(sessionControllerProvider.notifier)
        .expire(testAccount.id);

    final session = container.read(sessionControllerProvider);
    expect(session.active, testAccount);
    expect(session.activeExpired, isTrue);
    expect(await tokens.read(testAccount.id), isNull);
    expect(container.read(activeSourceProvider), isNull);
    expect(
      container.read(albumListProvider(const AlbumQuery())).failure,
      isA<UnauthorizedFailure>(),
    );
  });

  test('changing the library drops the cache of that account', () async {
    final container = await createContainer();
    final cache = container.read(catalogCacheProvider);
    await cache.writeList(testAccount.id, 'k', CacheKind.album, [
      makeAlbum('x'),
    ]);

    await container
        .read(sessionControllerProvider.notifier)
        .setLibrary(testAccount.id, 'lib1');
    expect(container.read(sessionControllerProvider).active?.libraryId, 'lib1');
    expect(await cache.readList(testAccount.id, 'k', CacheKind.album), isEmpty);
  });

  test('signing out removes account, token and cache', () async {
    final tokens = MemoryTokenStore({testAccount.id: 'token-1'});
    final container = await createContainer(tokens: tokens);
    final controller = container.read(sessionControllerProvider.notifier);
    await controller.signedIn(AuthSession(account: other, accessToken: 't'));
    final cache = container.read(catalogCacheProvider);
    await cache.writeList(other.id, 'k', CacheKind.album, [makeAlbum('x')]);

    await controller.signOut(other.id);
    var session = container.read(sessionControllerProvider);
    expect(session.accounts, [testAccount]);
    expect(session.active, testAccount);
    expect(await tokens.read(other.id), isNull);
    expect(await cache.readList(other.id, 'k', CacheKind.album), isEmpty);

    await controller.signOut(testAccount.id);
    session = container.read(sessionControllerProvider);
    expect(session.accounts, isEmpty);
    expect(session.active, isNull);
  });

  group('sessionRedirect', () {
    test('signed out users are sent to the connect screen', () {
      const session = SessionState();
      expect(sessionRedirect(session, AppRoutes.home), AppRoutes.connect);
      expect(sessionRedirect(session, AppRoutes.settings), AppRoutes.connect);
      expect(sessionRedirect(session, AppRoutes.connect), isNull);
      expect(sessionRedirect(session, AppRoutes.login), isNull);
    });

    test('signed in users go anywhere, including adding an account', () {
      final session = SessionState(
        accounts: [testAccount],
        tokens: {testAccount.id: 't'},
        activeId: testAccount.id,
      );
      expect(sessionRedirect(session, AppRoutes.home), isNull);
      expect(sessionRedirect(session, AppRoutes.connect), isNull);
    });

    test('an expired session leads to the sign-in screen of its server', () {
      final session = SessionState(
        accounts: [testAccount],
        activeId: testAccount.id,
      );
      final target = Uri.parse(sessionRedirect(session, AppRoutes.library)!);
      expect(target.path, AppRoutes.login);
      expect(target.queryParameters['url'], 'https://music.example.com');
      expect(target.queryParameters['user'], 'ayla');
      expect(target.queryParameters['expired'], '1');
      expect(sessionRedirect(session, AppRoutes.login), isNull);
    });
  });
}
