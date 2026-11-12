// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listening_settings.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds and persists [ListeningSettings].

@ProviderFor(ListeningSettingsController)
final listeningSettingsControllerProvider =
    ListeningSettingsControllerProvider._();

/// Holds and persists [ListeningSettings].
final class ListeningSettingsControllerProvider
    extends $NotifierProvider<ListeningSettingsController, ListeningSettings> {
  /// Holds and persists [ListeningSettings].
  ListeningSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listeningSettingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listeningSettingsControllerHash();

  @$internal
  @override
  ListeningSettingsController create() => ListeningSettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ListeningSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ListeningSettings>(value),
    );
  }
}

String _$listeningSettingsControllerHash() =>
    r'2d2b61184e669a5e983f0323a175d8099e7496c4';

/// Holds and persists [ListeningSettings].

abstract class _$ListeningSettingsController
    extends $Notifier<ListeningSettings> {
  ListeningSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ListeningSettings, ListeningSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ListeningSettings, ListeningSettings>,
              ListeningSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
