// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_clip.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The song loader in use.

@ProviderFor(songAudioLoader)
final songAudioLoaderProvider = SongAudioLoaderProvider._();

/// The song loader in use.

final class SongAudioLoaderProvider
    extends
        $FunctionalProvider<SongAudioLoader, SongAudioLoader, SongAudioLoader>
    with $Provider<SongAudioLoader> {
  /// The song loader in use.
  SongAudioLoaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'songAudioLoaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$songAudioLoaderHash();

  @$internal
  @override
  $ProviderElement<SongAudioLoader> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SongAudioLoader create(Ref ref) {
    return songAudioLoader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SongAudioLoader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SongAudioLoader>(value),
    );
  }
}

String _$songAudioLoaderHash() => r'19a6e4f2c2819d87df7395be0feb64bbe3a18d40';

/// The story video maker in use.

@ProviderFor(storyVideoMaker)
final storyVideoMakerProvider = StoryVideoMakerProvider._();

/// The story video maker in use.

final class StoryVideoMakerProvider
    extends
        $FunctionalProvider<StoryVideoMaker, StoryVideoMaker, StoryVideoMaker>
    with $Provider<StoryVideoMaker> {
  /// The story video maker in use.
  StoryVideoMakerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storyVideoMakerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storyVideoMakerHash();

  @$internal
  @override
  $ProviderElement<StoryVideoMaker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StoryVideoMaker create(Ref ref) {
    return storyVideoMaker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StoryVideoMaker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StoryVideoMaker>(value),
    );
  }
}

String _$storyVideoMakerHash() => r'6bdb71666adaa302b787b903608c6045a9328174';

/// A new preview player for one share screen.

@ProviderFor(clipPreview)
final clipPreviewProvider = ClipPreviewProvider._();

/// A new preview player for one share screen.

final class ClipPreviewProvider
    extends $FunctionalProvider<ClipPreview, ClipPreview, ClipPreview>
    with $Provider<ClipPreview> {
  /// A new preview player for one share screen.
  ClipPreviewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clipPreviewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clipPreviewHash();

  @$internal
  @override
  $ProviderElement<ClipPreview> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ClipPreview create(Ref ref) {
    return clipPreview(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClipPreview value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClipPreview>(value),
    );
  }
}

String _$clipPreviewHash() => r'4070efee54db745b5534958b41e63f4327379fff';
