// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_clip.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The clip maker in use.

@ProviderFor(clipMaker)
final clipMakerProvider = ClipMakerProvider._();

/// The clip maker in use.

final class ClipMakerProvider
    extends $FunctionalProvider<ClipMaker, ClipMaker, ClipMaker>
    with $Provider<ClipMaker> {
  /// The clip maker in use.
  ClipMakerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clipMakerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clipMakerHash();

  @$internal
  @override
  $ProviderElement<ClipMaker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ClipMaker create(Ref ref) {
    return clipMaker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClipMaker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClipMaker>(value),
    );
  }
}

String _$clipMakerHash() => r'0036a6e1df02624447f894d67932cd9c6f6ec3c9';

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
