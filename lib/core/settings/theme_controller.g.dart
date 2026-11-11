// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds and persists the user's appearance preferences.

@ProviderFor(ThemeController)
final themeControllerProvider = ThemeControllerProvider._();

/// Holds and persists the user's appearance preferences.
final class ThemeControllerProvider
    extends $NotifierProvider<ThemeController, ThemeSettings> {
  /// Holds and persists the user's appearance preferences.
  ThemeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeControllerHash();

  @$internal
  @override
  ThemeController create() => ThemeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeSettings>(value),
    );
  }
}

String _$themeControllerHash() => r'ee9b1e17f36a2d516cae74fe8db4c5d3982b221c';

/// Holds and persists the user's appearance preferences.

abstract class _$ThemeController extends $Notifier<ThemeSettings> {
  ThemeSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeSettings, ThemeSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeSettings, ThemeSettings>,
              ThemeSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
