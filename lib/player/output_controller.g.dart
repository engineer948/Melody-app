// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'output_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Talks to DLNA renderers; replaced in tests.

@ProviderFor(dlnaClient)
final dlnaClientProvider = DlnaClientProvider._();

/// Talks to DLNA renderers; replaced in tests.

final class DlnaClientProvider
    extends $FunctionalProvider<DlnaClient, DlnaClient, DlnaClient>
    with $Provider<DlnaClient> {
  /// Talks to DLNA renderers; replaced in tests.
  DlnaClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dlnaClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dlnaClientHash();

  @$internal
  @override
  $ProviderElement<DlnaClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DlnaClient create(Ref ref) {
    return dlnaClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DlnaClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DlnaClient>(value),
    );
  }
}

String _$dlnaClientHash() => r'3da15c54b4fc25aa4923be2d85a8fb1ae2be5917';

/// Renderers found on the local network; grows while the search runs.

@ProviderFor(dlnaRenderers)
final dlnaRenderersProvider = DlnaRenderersProvider._();

/// Renderers found on the local network; grows while the search runs.

final class DlnaRenderersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DlnaRenderer>>,
          List<DlnaRenderer>,
          Stream<List<DlnaRenderer>>
        >
    with
        $FutureModifier<List<DlnaRenderer>>,
        $StreamProvider<List<DlnaRenderer>> {
  /// Renderers found on the local network; grows while the search runs.
  DlnaRenderersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dlnaRenderersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dlnaRenderersHash();

  @$internal
  @override
  $StreamProviderElement<List<DlnaRenderer>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<DlnaRenderer>> create(Ref ref) {
    return dlnaRenderers(ref);
  }
}

String _$dlnaRenderersHash() => r'9310e723dfdc6f61e79dc49226fabf3450fa2d40';

/// Where audio is played: `null` for this device, otherwise a DLNA
/// renderer.

@ProviderFor(OutputController)
final outputControllerProvider = OutputControllerProvider._();

/// Where audio is played: `null` for this device, otherwise a DLNA
/// renderer.
final class OutputControllerProvider
    extends $NotifierProvider<OutputController, DlnaRenderer?> {
  /// Where audio is played: `null` for this device, otherwise a DLNA
  /// renderer.
  OutputControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'outputControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$outputControllerHash();

  @$internal
  @override
  OutputController create() => OutputController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DlnaRenderer? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DlnaRenderer?>(value),
    );
  }
}

String _$outputControllerHash() => r'd7576abf679b3282a409746f373df3d86d069530';

/// Where audio is played: `null` for this device, otherwise a DLNA
/// renderer.

abstract class _$OutputController extends $Notifier<DlnaRenderer?> {
  DlnaRenderer? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DlnaRenderer?, DlnaRenderer?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DlnaRenderer?, DlnaRenderer?>,
              DlnaRenderer?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
