// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The local database.

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// The local database.

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// The local database.
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'59cce38d45eeaba199eddd097d8e149d66f9f3e1';

/// Where access tokens are kept.

@ProviderFor(tokenStore)
final tokenStoreProvider = TokenStoreProvider._();

/// Where access tokens are kept.

final class TokenStoreProvider
    extends $FunctionalProvider<TokenStore, TokenStore, TokenStore>
    with $Provider<TokenStore> {
  /// Where access tokens are kept.
  TokenStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tokenStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tokenStoreHash();

  @$internal
  @override
  $ProviderElement<TokenStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TokenStore create(Ref ref) {
    return tokenStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TokenStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TokenStore>(value),
    );
  }
}

String _$tokenStoreHash() => r'6234bcccd71a4222b2c7988be51ef7417f8dc34e';

/// Persistence of accounts.

@ProviderFor(accountStore)
final accountStoreProvider = AccountStoreProvider._();

/// Persistence of accounts.

final class AccountStoreProvider
    extends $FunctionalProvider<AccountStore, AccountStore, AccountStore>
    with $Provider<AccountStore> {
  /// Persistence of accounts.
  AccountStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountStoreHash();

  @$internal
  @override
  $ProviderElement<AccountStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AccountStore create(Ref ref) {
    return accountStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountStore>(value),
    );
  }
}

String _$accountStoreHash() => r'5b895a51cce2bdfdd9bf6b75b0fbb562f9d5dd13';

/// Offline copy of the library.

@ProviderFor(catalogCache)
final catalogCacheProvider = CatalogCacheProvider._();

/// Offline copy of the library.

final class CatalogCacheProvider
    extends $FunctionalProvider<CatalogCache, CatalogCache, CatalogCache>
    with $Provider<CatalogCache> {
  /// Offline copy of the library.
  CatalogCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogCacheHash();

  @$internal
  @override
  $ProviderElement<CatalogCache> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CatalogCache create(Ref ref) {
    return catalogCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CatalogCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CatalogCache>(value),
    );
  }
}

String _$catalogCacheHash() => r'35dc047759d89fbc46a2322db25ce056f4e595a4';

/// Accounts read from disk before the first frame.
///
/// Overridden in the root `ProviderScope`.

@ProviderFor(sessionBootstrap)
final sessionBootstrapProvider = SessionBootstrapProvider._();

/// Accounts read from disk before the first frame.
///
/// Overridden in the root `ProviderScope`.

final class SessionBootstrapProvider
    extends
        $FunctionalProvider<
          List<StoredAccount>,
          List<StoredAccount>,
          List<StoredAccount>
        >
    with $Provider<List<StoredAccount>> {
  /// Accounts read from disk before the first frame.
  ///
  /// Overridden in the root `ProviderScope`.
  SessionBootstrapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionBootstrapProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionBootstrapHash();

  @$internal
  @override
  $ProviderElement<List<StoredAccount>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<StoredAccount> create(Ref ref) {
    return sessionBootstrap(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<StoredAccount> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<StoredAccount>>(value),
    );
  }
}

String _$sessionBootstrapHash() => r'167341589098d2e2c9ac8116a41aba924a1a745e';

/// Owns the list of accounts and the active one.

@ProviderFor(SessionController)
final sessionControllerProvider = SessionControllerProvider._();

/// Owns the list of accounts and the active one.
final class SessionControllerProvider
    extends $NotifierProvider<SessionController, SessionState> {
  /// Owns the list of accounts and the active one.
  SessionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionControllerHash();

  @$internal
  @override
  SessionController create() => SessionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionState>(value),
    );
  }
}

String _$sessionControllerHash() => r'3591ef4358302d27972181fef9c1b7e8abd7a32c';

/// Owns the list of accounts and the active one.

abstract class _$SessionController extends $Notifier<SessionState> {
  SessionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SessionState, SessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SessionState, SessionState>,
              SessionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The source of the active account; `null` when signed out.

@ProviderFor(activeSource)
final activeSourceProvider = ActiveSourceProvider._();

/// The source of the active account; `null` when signed out.

final class ActiveSourceProvider
    extends $FunctionalProvider<MusicSource?, MusicSource?, MusicSource?>
    with $Provider<MusicSource?> {
  /// The source of the active account; `null` when signed out.
  ActiveSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeSourceHash();

  @$internal
  @override
  $ProviderElement<MusicSource?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MusicSource? create(Ref ref) {
    return activeSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MusicSource? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MusicSource?>(value),
    );
  }
}

String _$activeSourceHash() => r'0a7fa87f950534453b9c3ff34292662c312e53e3';

/// Library of the active account; `null` when signed out.

@ProviderFor(libraryRepository)
final libraryRepositoryProvider = LibraryRepositoryProvider._();

/// Library of the active account; `null` when signed out.

final class LibraryRepositoryProvider
    extends
        $FunctionalProvider<
          LibraryRepository?,
          LibraryRepository?,
          LibraryRepository?
        >
    with $Provider<LibraryRepository?> {
  /// Library of the active account; `null` when signed out.
  LibraryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryRepositoryHash();

  @$internal
  @override
  $ProviderElement<LibraryRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LibraryRepository? create(Ref ref) {
    return libraryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LibraryRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LibraryRepository?>(value),
    );
  }
}

String _$libraryRepositoryHash() => r'b7d0f5d0985f889770328e42cd6a7bc08d2a3733';
