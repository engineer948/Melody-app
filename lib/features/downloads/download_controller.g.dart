// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Resolves the folder downloads are kept in; overridden in tests.

@ProviderFor(downloadDirectory)
final downloadDirectoryProvider = DownloadDirectoryProvider._();

/// Resolves the folder downloads are kept in; overridden in tests.

final class DownloadDirectoryProvider
    extends
        $FunctionalProvider<
          Future<Directory> Function(),
          Future<Directory> Function(),
          Future<Directory> Function()
        >
    with $Provider<Future<Directory> Function()> {
  /// Resolves the folder downloads are kept in; overridden in tests.
  DownloadDirectoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadDirectoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadDirectoryHash();

  @$internal
  @override
  $ProviderElement<Future<Directory> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<Directory> Function() create(Ref ref) {
    return downloadDirectory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<Directory> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<Directory> Function()>(value),
    );
  }
}

String _$downloadDirectoryHash() => r'c5794ebef8d5d3c77e67d4580b18d9bd7df2ef49';

/// Fetches the files; overridden in tests.

@ProviderFor(downloadTransport)
final downloadTransportProvider = DownloadTransportProvider._();

/// Fetches the files; overridden in tests.

final class DownloadTransportProvider
    extends
        $FunctionalProvider<
          DownloadTransport,
          DownloadTransport,
          DownloadTransport
        >
    with $Provider<DownloadTransport> {
  /// Fetches the files; overridden in tests.
  DownloadTransportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadTransportProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadTransportHash();

  @$internal
  @override
  $ProviderElement<DownloadTransport> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DownloadTransport create(Ref ref) {
    return downloadTransport(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DownloadTransport value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DownloadTransport>(value),
    );
  }
}

String _$downloadTransportHash() => r'60afb166bd9fce56622fc01357f028bcd0ff7b90';

/// The persisted list of downloads.

@ProviderFor(downloadStore)
final downloadStoreProvider = DownloadStoreProvider._();

/// The persisted list of downloads.

final class DownloadStoreProvider
    extends $FunctionalProvider<DownloadStore, DownloadStore, DownloadStore>
    with $Provider<DownloadStore> {
  /// The persisted list of downloads.
  DownloadStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadStoreHash();

  @$internal
  @override
  $ProviderElement<DownloadStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DownloadStore create(Ref ref) {
    return downloadStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DownloadStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DownloadStore>(value),
    );
  }
}

String _$downloadStoreHash() => r'22bf0b06c8708aa94a1a2cc90c6e88bdecb4437b';

/// Downloads of the active account by track id, in the order requested.
///
/// Files are fetched a few at a time, can be paused and resumed, and wait
/// for Wi-Fi when asked to. Work happens while the app is alive.

@ProviderFor(DownloadController)
final downloadControllerProvider = DownloadControllerProvider._();

/// Downloads of the active account by track id, in the order requested.
///
/// Files are fetched a few at a time, can be paused and resumed, and wait
/// for Wi-Fi when asked to. Work happens while the app is alive.
final class DownloadControllerProvider
    extends $NotifierProvider<DownloadController, Map<String, DownloadItem>> {
  /// Downloads of the active account by track id, in the order requested.
  ///
  /// Files are fetched a few at a time, can be paused and resumed, and wait
  /// for Wi-Fi when asked to. Work happens while the app is alive.
  DownloadControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadControllerHash();

  @$internal
  @override
  DownloadController create() => DownloadController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, DownloadItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, DownloadItem>>(value),
    );
  }
}

String _$downloadControllerHash() =>
    r'b83c2c0de704b77351adf0a4d60631417f282d8e';

/// Downloads of the active account by track id, in the order requested.
///
/// Files are fetched a few at a time, can be paused and resumed, and wait
/// for Wi-Fi when asked to. Work happens while the app is alive.

abstract class _$DownloadController
    extends $Notifier<Map<String, DownloadItem>> {
  Map<String, DownloadItem> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<Map<String, DownloadItem>, Map<String, DownloadItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, DownloadItem>, Map<String, DownloadItem>>,
              Map<String, DownloadItem>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
