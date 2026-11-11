// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_settings.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds and persists [PlaybackSettings].

@ProviderFor(PlaybackSettingsController)
final playbackSettingsControllerProvider =
    PlaybackSettingsControllerProvider._();

/// Holds and persists [PlaybackSettings].
final class PlaybackSettingsControllerProvider
    extends $NotifierProvider<PlaybackSettingsController, PlaybackSettings> {
  /// Holds and persists [PlaybackSettings].
  PlaybackSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playbackSettingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playbackSettingsControllerHash();

  @$internal
  @override
  PlaybackSettingsController create() => PlaybackSettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaybackSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaybackSettings>(value),
    );
  }
}

String _$playbackSettingsControllerHash() =>
    r'c50cc1b91b369e062207fb1ab1a68e323f36eb11';

/// Holds and persists [PlaybackSettings].

abstract class _$PlaybackSettingsController
    extends $Notifier<PlaybackSettings> {
  PlaybackSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PlaybackSettings, PlaybackSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlaybackSettings, PlaybackSettings>,
              PlaybackSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
