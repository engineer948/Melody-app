// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sharing storage of the active account; `null` when the source cannot
/// share (only Jellyfin / Emby can).

@ProviderFor(socialApi)
final socialApiProvider = SocialApiProvider._();

/// Sharing storage of the active account; `null` when the source cannot
/// share (only Jellyfin / Emby can).

final class SocialApiProvider
    extends $FunctionalProvider<SocialApi?, SocialApi?, SocialApi?>
    with $Provider<SocialApi?> {
  /// Sharing storage of the active account; `null` when the source cannot
  /// share (only Jellyfin / Emby can).
  SocialApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'socialApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$socialApiHash();

  @$internal
  @override
  $ProviderElement<SocialApi?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SocialApi? create(Ref ref) {
    return socialApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SocialApi? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SocialApi?>(value),
    );
  }
}

String _$socialApiHash() => r'26f1ba9b4fe5a21fe461cde27f022f69edcbbb26';

/// Loads and changes the sharing state; refreshes every few minutes.

@ProviderFor(SocialController)
final socialControllerProvider = SocialControllerProvider._();

/// Loads and changes the sharing state; refreshes every few minutes.
final class SocialControllerProvider
    extends $NotifierProvider<SocialController, SocialState> {
  /// Loads and changes the sharing state; refreshes every few minutes.
  SocialControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'socialControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$socialControllerHash();

  @$internal
  @override
  SocialController create() => SocialController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SocialState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SocialState>(value),
    );
  }
}

String _$socialControllerHash() => r'3f1d415ef4705f825052f8bb0f67621d734f1e2d';

/// Loads and changes the sharing state; refreshes every few minutes.

abstract class _$SocialController extends $Notifier<SocialState> {
  SocialState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SocialState, SocialState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SocialState, SocialState>,
              SocialState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
