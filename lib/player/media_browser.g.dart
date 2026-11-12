// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_browser.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Which [AutoTab]s are shown in the car; all of them by default.

@ProviderFor(AutoTabs)
final autoTabsProvider = AutoTabsProvider._();

/// Which [AutoTab]s are shown in the car; all of them by default.
final class AutoTabsProvider extends $NotifierProvider<AutoTabs, Set<AutoTab>> {
  /// Which [AutoTab]s are shown in the car; all of them by default.
  AutoTabsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoTabsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoTabsHash();

  @$internal
  @override
  AutoTabs create() => AutoTabs();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<AutoTab> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<AutoTab>>(value),
    );
  }
}

String _$autoTabsHash() => r'747b36cc573c520c529b2c7cc2aeb1c7ffc5e5ac';

/// Which [AutoTab]s are shown in the car; all of them by default.

abstract class _$AutoTabs extends $Notifier<Set<AutoTab>> {
  Set<AutoTab> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<AutoTab>, Set<AutoTab>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<AutoTab>, Set<AutoTab>>,
              Set<AutoTab>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
