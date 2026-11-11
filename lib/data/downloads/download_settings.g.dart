// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_settings.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds and persists [DownloadSettings].

@ProviderFor(DownloadSettingsController)
final downloadSettingsControllerProvider =
    DownloadSettingsControllerProvider._();

/// Holds and persists [DownloadSettings].
final class DownloadSettingsControllerProvider
    extends $NotifierProvider<DownloadSettingsController, DownloadSettings> {
  /// Holds and persists [DownloadSettings].
  DownloadSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadSettingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadSettingsControllerHash();

  @$internal
  @override
  DownloadSettingsController create() => DownloadSettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DownloadSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DownloadSettings>(value),
    );
  }
}

String _$downloadSettingsControllerHash() =>
    r'd11393e2438e65d406844faa6b64870b7c066114';

/// Holds and persists [DownloadSettings].

abstract class _$DownloadSettingsController
    extends $Notifier<DownloadSettings> {
  DownloadSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DownloadSettings, DownloadSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DownloadSettings, DownloadSettings>,
              DownloadSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
