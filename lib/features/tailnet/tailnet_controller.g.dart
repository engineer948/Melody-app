// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tailnet_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Read before the first frame; overridden in `main`.

@ProviderFor(tailnetBootstrap)
final tailnetBootstrapProvider = TailnetBootstrapProvider._();

/// Read before the first frame; overridden in `main`.

final class TailnetBootstrapProvider
    extends
        $FunctionalProvider<
          TailnetBootstrap,
          TailnetBootstrap,
          TailnetBootstrap
        >
    with $Provider<TailnetBootstrap> {
  /// Read before the first frame; overridden in `main`.
  TailnetBootstrapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tailnetBootstrapProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tailnetBootstrapHash();

  @$internal
  @override
  $ProviderElement<TailnetBootstrap> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TailnetBootstrap create(Ref ref) {
    return tailnetBootstrap(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TailnetBootstrap value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TailnetBootstrap>(value),
    );
  }
}

String _$tailnetBootstrapHash() => r'5168039454e08c0a24c620340ad88319fa8472c2';

/// The platform side of the node.

@ProviderFor(tailnetBridge)
final tailnetBridgeProvider = TailnetBridgeProvider._();

/// The platform side of the node.

final class TailnetBridgeProvider
    extends $FunctionalProvider<TailnetBridge, TailnetBridge, TailnetBridge>
    with $Provider<TailnetBridge> {
  /// The platform side of the node.
  TailnetBridgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tailnetBridgeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tailnetBridgeHash();

  @$internal
  @override
  $ProviderElement<TailnetBridge> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TailnetBridge create(Ref ref) {
    return tailnetBridge(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TailnetBridge value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TailnetBridge>(value),
    );
  }
}

String _$tailnetBridgeHash() => r'd3c98268cfbd9fed21a24ccca6693e211276a9b2';

/// Whether the music server answers through the proxy at `local`
/// (`<local>/System/Info/Public`, no sign-in needed); overridden in tests.

@ProviderFor(tailnetProbe)
final tailnetProbeProvider = TailnetProbeProvider._();

/// Whether the music server answers through the proxy at `local`
/// (`<local>/System/Info/Public`, no sign-in needed); overridden in tests.

final class TailnetProbeProvider
    extends
        $FunctionalProvider<
          Future<bool> Function(Uri local),
          Future<bool> Function(Uri local),
          Future<bool> Function(Uri local)
        >
    with $Provider<Future<bool> Function(Uri local)> {
  /// Whether the music server answers through the proxy at `local`
  /// (`<local>/System/Info/Public`, no sign-in needed); overridden in tests.
  TailnetProbeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tailnetProbeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tailnetProbeHash();

  @$internal
  @override
  $ProviderElement<Future<bool> Function(Uri local)> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<bool> Function(Uri local) create(Ref ref) {
    return tailnetProbe(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<bool> Function(Uri local) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<bool> Function(Uri local)>(
        value,
      ),
    );
  }
}

String _$tailnetProbeHash() => r'e37a214304e15ea04a23aae3f69b57d1e1699019';

/// Where the node's secrets are kept.

@ProviderFor(tailnetSecretStore)
final tailnetSecretStoreProvider = TailnetSecretStoreProvider._();

/// Where the node's secrets are kept.

final class TailnetSecretStoreProvider
    extends
        $FunctionalProvider<
          TailnetSecretStore,
          TailnetSecretStore,
          TailnetSecretStore
        >
    with $Provider<TailnetSecretStore> {
  /// Where the node's secrets are kept.
  TailnetSecretStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tailnetSecretStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tailnetSecretStoreHash();

  @$internal
  @override
  $ProviderElement<TailnetSecretStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TailnetSecretStore create(Ref ref) {
    return tailnetSecretStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TailnetSecretStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TailnetSecretStore>(value),
    );
  }
}

String _$tailnetSecretStoreHash() =>
    r'24d79fb8d91148691ae71c23ace26a460ee675f6';

/// Joins, runs and leaves the tailnet of an invite.

@ProviderFor(TailnetController)
final tailnetControllerProvider = TailnetControllerProvider._();

/// Joins, runs and leaves the tailnet of an invite.
final class TailnetControllerProvider
    extends $NotifierProvider<TailnetController, TailnetState> {
  /// Joins, runs and leaves the tailnet of an invite.
  TailnetControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tailnetControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tailnetControllerHash();

  @$internal
  @override
  TailnetController create() => TailnetController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TailnetState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TailnetState>(value),
    );
  }
}

String _$tailnetControllerHash() => r'cdfe51fd9961fec826bc954248afbf9f4a6565da';

/// Joins, runs and leaves the tailnet of an invite.

abstract class _$TailnetController extends $Notifier<TailnetState> {
  TailnetState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TailnetState, TailnetState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TailnetState, TailnetState>,
              TailnetState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Routes requests for the tailnet server through the proxy.

@ProviderFor(tailnetRouter)
final tailnetRouterProvider = TailnetRouterProvider._();

/// Routes requests for the tailnet server through the proxy.

final class TailnetRouterProvider
    extends $FunctionalProvider<TailnetRouter, TailnetRouter, TailnetRouter>
    with $Provider<TailnetRouter> {
  /// Routes requests for the tailnet server through the proxy.
  TailnetRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tailnetRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tailnetRouterHash();

  @$internal
  @override
  $ProviderElement<TailnetRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TailnetRouter create(Ref ref) {
    return tailnetRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TailnetRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TailnetRouter>(value),
    );
  }
}

String _$tailnetRouterHash() => r'39ea46723378a6497118621d407ba051445333f4';
