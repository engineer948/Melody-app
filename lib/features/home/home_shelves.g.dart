// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_shelves.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds and persists [HomeShelves].

@ProviderFor(HomeShelvesController)
final homeShelvesControllerProvider = HomeShelvesControllerProvider._();

/// Holds and persists [HomeShelves].
final class HomeShelvesControllerProvider
    extends $NotifierProvider<HomeShelvesController, HomeShelves> {
  /// Holds and persists [HomeShelves].
  HomeShelvesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeShelvesControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeShelvesControllerHash();

  @$internal
  @override
  HomeShelvesController create() => HomeShelvesController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeShelves value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeShelves>(value),
    );
  }
}

String _$homeShelvesControllerHash() =>
    r'474259165987fba0bb03628780ca888e2e0bfda8';

/// Holds and persists [HomeShelves].

abstract class _$HomeShelvesController extends $Notifier<HomeShelves> {
  HomeShelves build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<HomeShelves, HomeShelves>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HomeShelves, HomeShelves>,
              HomeShelves,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
