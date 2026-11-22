// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'life_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The last [lifeSpan] of the active account, day by day.

@ProviderFor(lifeTimeline)
final lifeTimelineProvider = LifeTimelineProvider._();

/// The last [lifeSpan] of the active account, day by day.

final class LifeTimelineProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LifeDay>>,
          List<LifeDay>,
          FutureOr<List<LifeDay>>
        >
    with $FutureModifier<List<LifeDay>>, $FutureProvider<List<LifeDay>> {
  /// The last [lifeSpan] of the active account, day by day.
  LifeTimelineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lifeTimelineProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lifeTimelineHash();

  @$internal
  @override
  $FutureProviderElement<List<LifeDay>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LifeDay>> create(Ref ref) {
    return lifeTimeline(ref);
  }
}

String _$lifeTimelineHash() => r'09c5aaf4d2d0e624613be78d5f51d242fde1d662';

/// The same calendar day 1 to 5 years ago, when music was played then,
/// as (years ago, day), most recent first.

@ProviderFor(onThisDay)
final onThisDayProvider = OnThisDayProvider._();

/// The same calendar day 1 to 5 years ago, when music was played then,
/// as (years ago, day), most recent first.

final class OnThisDayProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<(int, LifeDay)>>,
          List<(int, LifeDay)>,
          FutureOr<List<(int, LifeDay)>>
        >
    with
        $FutureModifier<List<(int, LifeDay)>>,
        $FutureProvider<List<(int, LifeDay)>> {
  /// The same calendar day 1 to 5 years ago, when music was played then,
  /// as (years ago, day), most recent first.
  OnThisDayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onThisDayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onThisDayHash();

  @$internal
  @override
  $FutureProviderElement<List<(int, LifeDay)>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<(int, LifeDay)>> create(Ref ref) {
    return onThisDay(ref);
  }
}

String _$onThisDayHash() => r'36377d16e66fb078f6740b92ac1e7447cf8a12eb';

/// What was played the last time at the place the phone is now, when the
/// user is back after a while; `null` otherwise. Asked again when the app
/// comes back to the foreground.

@ProviderFor(placeMemory)
final placeMemoryProvider = PlaceMemoryProvider._();

/// What was played the last time at the place the phone is now, when the
/// user is back after a while; `null` otherwise. Asked again when the app
/// comes back to the foreground.

final class PlaceMemoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlaceMemory?>,
          PlaceMemory?,
          FutureOr<PlaceMemory?>
        >
    with $FutureModifier<PlaceMemory?>, $FutureProvider<PlaceMemory?> {
  /// What was played the last time at the place the phone is now, when the
  /// user is back after a while; `null` otherwise. Asked again when the app
  /// comes back to the foreground.
  PlaceMemoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placeMemoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placeMemoryHash();

  @$internal
  @override
  $FutureProviderElement<PlaceMemory?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PlaceMemory?> create(Ref ref) {
    return placeMemory(ref);
  }
}

String _$placeMemoryHash() => r'089729c9ff209d1ab36a82391a27cc5457c749ea';

/// Hides the place reminder until the app is opened again.

@ProviderFor(PlaceMemoryDismissed)
final placeMemoryDismissedProvider = PlaceMemoryDismissedProvider._();

/// Hides the place reminder until the app is opened again.
final class PlaceMemoryDismissedProvider
    extends $NotifierProvider<PlaceMemoryDismissed, bool> {
  /// Hides the place reminder until the app is opened again.
  PlaceMemoryDismissedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placeMemoryDismissedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placeMemoryDismissedHash();

  @$internal
  @override
  PlaceMemoryDismissed create() => PlaceMemoryDismissed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$placeMemoryDismissedHash() =>
    r'0810a3e8d3c675a8313950f116a6cd366b7d46f2';

/// Hides the place reminder until the app is opened again.

abstract class _$PlaceMemoryDismissed extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// First play of a song and how often it was played.

@ProviderFor(trackMemory)
final trackMemoryProvider = TrackMemoryFamily._();

/// First play of a song and how often it was played.

final class TrackMemoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<({PlayEvent first, int plays})?>,
          ({PlayEvent first, int plays})?,
          FutureOr<({PlayEvent first, int plays})?>
        >
    with
        $FutureModifier<({PlayEvent first, int plays})?>,
        $FutureProvider<({PlayEvent first, int plays})?> {
  /// First play of a song and how often it was played.
  TrackMemoryProvider._({
    required TrackMemoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'trackMemoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$trackMemoryHash();

  @override
  String toString() {
    return r'trackMemoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<({PlayEvent first, int plays})?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<({PlayEvent first, int plays})?> create(Ref ref) {
    final argument = this.argument as String;
    return trackMemory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TrackMemoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$trackMemoryHash() => r'9c2d073339cb1cc750fc12e80b697f42c6938714';

/// First play of a song and how often it was played.

final class TrackMemoryFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<({PlayEvent first, int plays})?>,
          String
        > {
  TrackMemoryFamily._()
    : super(
        retry: null,
        name: r'trackMemoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// First play of a song and how often it was played.

  TrackMemoryProvider call(String trackId) =>
      TrackMemoryProvider._(argument: trackId, from: this);

  @override
  String toString() => r'trackMemoryProvider';
}

/// Photos taken on [day] (only when allowed).

@ProviderFor(dayPhotos)
final dayPhotosProvider = DayPhotosFamily._();

/// Photos taken on [day] (only when allowed).

final class DayPhotosProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GalleryPhoto>>,
          List<GalleryPhoto>,
          FutureOr<List<GalleryPhoto>>
        >
    with
        $FutureModifier<List<GalleryPhoto>>,
        $FutureProvider<List<GalleryPhoto>> {
  /// Photos taken on [day] (only when allowed).
  DayPhotosProvider._({
    required DayPhotosFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'dayPhotosProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dayPhotosHash();

  @override
  String toString() {
    return r'dayPhotosProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<GalleryPhoto>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GalleryPhoto>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return dayPhotos(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DayPhotosProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dayPhotosHash() => r'0362c921ea5336d1b467d8b9d639cbc0fda14fe3';

/// Photos taken on [day] (only when allowed).

final class DayPhotosFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<GalleryPhoto>>, DateTime> {
  DayPhotosFamily._()
    : super(
        retry: null,
        name: r'dayPhotosProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Photos taken on [day] (only when allowed).

  DayPhotosProvider call(DateTime day) =>
      DayPhotosProvider._(argument: day, from: this);

  @override
  String toString() => r'dayPhotosProvider';
}

/// A small picture of photo [id].

@ProviderFor(photoThumb)
final photoThumbProvider = PhotoThumbFamily._();

/// A small picture of photo [id].

final class PhotoThumbProvider
    extends
        $FunctionalProvider<
          AsyncValue<Uint8List?>,
          Uint8List?,
          FutureOr<Uint8List?>
        >
    with $FutureModifier<Uint8List?>, $FutureProvider<Uint8List?> {
  /// A small picture of photo [id].
  PhotoThumbProvider._({
    required PhotoThumbFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'photoThumbProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$photoThumbHash();

  @override
  String toString() {
    return r'photoThumbProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Uint8List?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Uint8List?> create(Ref ref) {
    final argument = this.argument as int;
    return photoThumb(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PhotoThumbProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$photoThumbHash() => r'bf6cb0531b8e720c02da1d0f844dcb07a6e8cbc0';

/// A small picture of photo [id].

final class PhotoThumbFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Uint8List?>, int> {
  PhotoThumbFamily._()
    : super(
        retry: null,
        name: r'photoThumbProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A small picture of photo [id].

  PhotoThumbProvider call(int id) =>
      PhotoThumbProvider._(argument: id, from: this);

  @override
  String toString() => r'photoThumbProvider';
}

/// Whether photos may be shown.

@ProviderFor(photosAllowed)
final photosAllowedProvider = PhotosAllowedProvider._();

/// Whether photos may be shown.

final class PhotosAllowedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether photos may be shown.
  PhotosAllowedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photosAllowedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photosAllowedHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return photosAllowed(ref);
  }
}

String _$photosAllowedHash() => r'd6f7cc1b5c9fd75f1ec8fb7828a04a12bbb8d536';
