// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Disk cache of played tracks.

@ProviderFor(streamCache)
final streamCacheProvider = StreamCacheProvider._();

/// Disk cache of played tracks.

final class StreamCacheProvider
    extends $FunctionalProvider<StreamCache, StreamCache, StreamCache>
    with $Provider<StreamCache> {
  /// Disk cache of played tracks.
  StreamCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'streamCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$streamCacheHash();

  @$internal
  @override
  $ProviderElement<StreamCache> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StreamCache create(Ref ref) {
    return streamCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StreamCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StreamCache>(value),
    );
  }
}

String _$streamCacheHash() => r'd9c585d13f327f39effa82b7bbf998d33f652ba7';

/// The audio engine; overridden with a fake in tests.

@ProviderFor(audioEngine)
final audioEngineProvider = AudioEngineProvider._();

/// The audio engine; overridden with a fake in tests.

final class AudioEngineProvider
    extends $FunctionalProvider<AudioEngine, AudioEngine, AudioEngine>
    with $Provider<AudioEngine> {
  /// The audio engine; overridden with a fake in tests.
  AudioEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'audioEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$audioEngineHash();

  @$internal
  @override
  $ProviderElement<AudioEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AudioEngine create(Ref ref) {
    return audioEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AudioEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AudioEngine>(value),
    );
  }
}

String _$audioEngineHash() => r'13922db3d40595630b7389f0cd052cc906126770';

/// Current position, refreshed a few times per second while playing.

@ProviderFor(playerPosition)
final playerPositionProvider = PlayerPositionProvider._();

/// Current position, refreshed a few times per second while playing.

final class PlayerPositionProvider
    extends
        $FunctionalProvider<AsyncValue<Duration>, Duration, Stream<Duration>>
    with $FutureModifier<Duration>, $StreamProvider<Duration> {
  /// Current position, refreshed a few times per second while playing.
  PlayerPositionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playerPositionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playerPositionHash();

  @$internal
  @override
  $StreamProviderElement<Duration> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Duration> create(Ref ref) {
    return playerPosition(ref);
  }
}

String _$playerPositionHash() => r'6f9f54d5f71825cc23f45b9132e86bfaa9ecd393';

/// Owns the queue and drives the [AudioEngine].

@ProviderFor(PlayerController)
final playerControllerProvider = PlayerControllerProvider._();

/// Owns the queue and drives the [AudioEngine].
final class PlayerControllerProvider
    extends $NotifierProvider<PlayerController, PlayerState> {
  /// Owns the queue and drives the [AudioEngine].
  PlayerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playerControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playerControllerHash();

  @$internal
  @override
  PlayerController create() => PlayerController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayerState>(value),
    );
  }
}

String _$playerControllerHash() => r'd234af60483400c63f3846cdb933656916f313e7';

/// Owns the queue and drives the [AudioEngine].

abstract class _$PlayerController extends $Notifier<PlayerState> {
  PlayerState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PlayerState, PlayerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlayerState, PlayerState>,
              PlayerState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
