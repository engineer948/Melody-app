import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/device/client_identity.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/data/db/app_database.dart';
import 'package:melody/data/repositories/account_store.dart';
import 'package:melody/data/repositories/catalog_cache.dart';
import 'package:melody/data/repositories/library_repository.dart';
import 'package:melody/data/repositories/source_factory.dart';
import 'package:melody/data/repositories/token_store.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_music_source.dart';
import 'package:melody/data/sources/radio/radio_source.dart';
import 'package:melody/data/sources/subsonic/subsonic_music_source.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_controller.g.dart';

/// Saved accounts and which one is in use.
@immutable
class SessionState {
  /// Creates a [SessionState].
  const SessionState({
    this.accounts = const [],
    this.tokens = const {},
    this.activeId,
  });

  /// All saved accounts.
  final List<ServerAccount> accounts;

  /// Access tokens by account id; missing means "sign in again".
  final Map<String, String> tokens;

  /// Id of the account in use.
  final String? activeId;

  /// The account in use, if any.
  ServerAccount? get active {
    for (final account in accounts) {
      if (account.id == activeId) return account;
    }
    return null;
  }

  /// Token of the active account.
  String? get activeToken => tokens[activeId];

  /// Whether the active account has to sign in again.
  bool get activeExpired => active != null && activeToken == null;
}

/// The local database.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

/// Where access tokens are kept.
@Riverpod(keepAlive: true)
TokenStore tokenStore(Ref ref) => const SecureTokenStore();

/// Persistence of accounts.
@Riverpod(keepAlive: true)
AccountStore accountStore(Ref ref) =>
    AccountStore(ref.watch(appDatabaseProvider), ref.watch(tokenStoreProvider));

/// Offline copy of the library.
@Riverpod(keepAlive: true)
CatalogCache catalogCache(Ref ref) =>
    CatalogCache(ref.watch(appDatabaseProvider));

/// Accounts read from disk before the first frame.
///
/// Overridden in the root `ProviderScope`.
@Riverpod(keepAlive: true)
List<StoredAccount> sessionBootstrap(Ref ref) => const [];

/// Owns the list of accounts and the active one.
@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  /// Preference key of the active account id.
  static const activeKey = 'session.activeAccount';

  @override
  SessionState build() {
    final stored = ref.watch(sessionBootstrapProvider);
    final accounts = [for (final s in stored) s.account];
    final saved = ref.watch(preferencesProvider).getString(activeKey);
    final activeId = accounts.any((a) => a.id == saved)
        ? saved
        : accounts.firstOrNull?.id;
    return SessionState(
      accounts: accounts,
      tokens: {
        for (final s in stored)
          if (s.token != null) s.account.id: s.token!,
      },
      activeId: activeId,
    );
  }

  AccountStore get _store => ref.read(accountStoreProvider);

  Future<void> _setActive(String? id) async {
    final prefs = ref.read(preferencesProvider);
    if (id == null) {
      await prefs.remove(activeKey);
    } else {
      await prefs.setString(activeKey, id);
    }
  }

  /// Adds (or refreshes) the account of [session] and makes it active.
  Future<void> signedIn(AuthSession session) async {
    final existing = state.accounts
        .where((a) => a.id == session.account.id)
        .firstOrNull;
    final account = session.account.copyWith(libraryId: existing?.libraryId);
    state = SessionState(
      accounts: [
        for (final a in state.accounts)
          if (a.id == account.id) account else a,
        if (existing == null) account,
      ],
      tokens: {...state.tokens, account.id: session.accessToken},
      activeId: account.id,
    );
    await _store.save(account, token: session.accessToken);
    await _setActive(account.id);
  }

  /// Makes [accountId] the active account.
  Future<void> switchTo(String accountId) async {
    if (!state.accounts.any((a) => a.id == accountId)) return;
    state = SessionState(
      accounts: state.accounts,
      tokens: state.tokens,
      activeId: accountId,
    );
    await _setActive(accountId);
  }

  /// Marks the token of [accountId] as rejected by the server.
  Future<void> expire(String accountId) async {
    if (!state.tokens.containsKey(accountId)) return;
    state = SessionState(
      accounts: state.accounts,
      tokens: {...state.tokens}..remove(accountId),
      activeId: state.activeId,
    );
    await _store.clearToken(accountId);
  }

  /// Restricts [accountId] to one library; `null` shows all of them.
  Future<void> setLibrary(String accountId, String? libraryId) async {
    final current = state.accounts.where((a) => a.id == accountId).firstOrNull;
    if (current == null || current.libraryId == libraryId) return;
    final account = current.copyWith(libraryId: libraryId);
    state = SessionState(
      accounts: [
        for (final a in state.accounts)
          if (a.id == accountId) account else a,
      ],
      tokens: state.tokens,
      activeId: state.activeId,
    );
    await _store.save(account);
    await ref.read(catalogCacheProvider).clearAccount(accountId);
  }

  /// Removes [accountId] together with its token and cache.
  Future<void> signOut(String accountId) async {
    final remaining = [
      for (final a in state.accounts)
        if (a.id != accountId) a,
    ];
    final activeId = state.activeId == accountId
        ? remaining.firstOrNull?.id
        : state.activeId;
    state = SessionState(
      accounts: remaining,
      tokens: {...state.tokens}..remove(accountId),
      activeId: activeId,
    );
    await _store.remove(accountId);
    await ref.read(catalogCacheProvider).clearAccount(accountId);
    await _setActive(activeId);
  }
}

/// The source of the active account; `null` when signed out.
@Riverpod(keepAlive: true)
MusicSource? activeSource(Ref ref) {
  final (account, token) = ref.watch(
    sessionControllerProvider.select((s) => (s.active, s.activeToken)),
  );
  if (account == null || token == null) return null;
  final source = createMusicSource(
    account: account,
    token: token,
    identity: ref.watch(clientIdentityProvider),
    prefs: ref.watch(preferencesProvider),
    onUnauthorized: () =>
        ref.read(sessionControllerProvider.notifier).expire(account.id),
  );
  switch (source) {
    case JellyfinMusicSource():
      ref.onDispose(source.close);
    case SubsonicMusicSource():
      ref.onDispose(source.close);
    case RadioSource():
      ref.onDispose(source.close);
  }
  return source;
}

/// Library of the active account; `null` when signed out.
@Riverpod(keepAlive: true)
LibraryRepository? libraryRepository(Ref ref) {
  final source = ref.watch(activeSourceProvider);
  final accountId = ref.watch(
    sessionControllerProvider.select((s) => s.activeId),
  );
  if (source == null || accountId == null) return null;
  return LibraryRepository(
    source: source,
    accountId: accountId,
    cache: ref.watch(catalogCacheProvider),
  );
}
