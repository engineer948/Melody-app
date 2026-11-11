// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streaming_settings.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds and persists [StreamingSettings].

@ProviderFor(StreamingSettingsController)
final streamingSettingsControllerProvider =
    StreamingSettingsControllerProvider._();

/// Holds and persists [StreamingSettings].
final class StreamingSettingsControllerProvider
    extends $NotifierProvider<StreamingSettingsController, StreamingSettings> {
  /// Holds and persists [StreamingSettings].
  StreamingSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'streamingSettingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$streamingSettingsControllerHash();

  @$internal
  @override
  StreamingSettingsController create() => StreamingSettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StreamingSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StreamingSettings>(value),
    );
  }
}

String _$streamingSettingsControllerHash() =>
    r'fdd99afcd8ce92d2f72cc41adb4421e39880bc63';

/// Holds and persists [StreamingSettings].

abstract class _$StreamingSettingsController
    extends $Notifier<StreamingSettings> {
  StreamingSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<StreamingSettings, StreamingSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StreamingSettings, StreamingSettings>,
              StreamingSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Whether the device is on mobile data (and not on Wi-Fi or Ethernet).

@ProviderFor(onMobileData)
final onMobileDataProvider = OnMobileDataProvider._();

/// Whether the device is on mobile data (and not on Wi-Fi or Ethernet).

final class OnMobileDataProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Whether the device is on mobile data (and not on Wi-Fi or Ethernet).
  OnMobileDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onMobileDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onMobileDataHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return onMobileData(ref);
  }
}

String _$onMobileDataHash() => r'e5a303ea3a0b7e72ab0bdf7ef70a787df0cc2754';
