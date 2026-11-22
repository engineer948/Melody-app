// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'life_journeys.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every play of the active account with a place.

@ProviderFor(placedEvents)
final placedEventsProvider = PlacedEventsProvider._();

/// Every play of the active account with a place.

final class PlacedEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlayEvent>>,
          List<PlayEvent>,
          FutureOr<List<PlayEvent>>
        >
    with $FutureModifier<List<PlayEvent>>, $FutureProvider<List<PlayEvent>> {
  /// Every play of the active account with a place.
  PlacedEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placedEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placedEventsHash();

  @$internal
  @override
  $FutureProviderElement<List<PlayEvent>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlayEvent>> create(Ref ref) {
    return placedEvents(ref);
  }
}

String _$placedEventsHash() => r'a142ac3266050714f8539f12a4c1d8d7099409ad';

/// Trips away from home, newest first.

@ProviderFor(trips)
final tripsProvider = TripsProvider._();

/// Trips away from home, newest first.

final class TripsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Trip>>,
          List<Trip>,
          FutureOr<List<Trip>>
        >
    with $FutureModifier<List<Trip>>, $FutureProvider<List<Trip>> {
  /// Trips away from home, newest first.
  TripsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripsHash();

  @$internal
  @override
  $FutureProviderElement<List<Trip>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Trip>> create(Ref ref) {
    return trips(ref);
  }
}

String _$tripsHash() => r'ba9d093e8d445fd5f1ac0357aab4a7c0aa43f077';

/// Places music was played at, in the order first visited.

@ProviderFor(stars)
final starsProvider = StarsProvider._();

/// Places music was played at, in the order first visited.

final class StarsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlaceStar>>,
          List<PlaceStar>,
          FutureOr<List<PlaceStar>>
        >
    with $FutureModifier<List<PlaceStar>>, $FutureProvider<List<PlaceStar>> {
  /// Places music was played at, in the order first visited.
  StarsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'starsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$starsHash();

  @$internal
  @override
  $FutureProviderElement<List<PlaceStar>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlaceStar>> create(Ref ref) {
    return stars(ref);
  }
}

String _$starsHash() => r'7259c06c6ee0519b069b72887d655fb422753c6c';

/// A big picture of photo [id] for the replay.

@ProviderFor(photoLarge)
final photoLargeProvider = PhotoLargeFamily._();

/// A big picture of photo [id] for the replay.

final class PhotoLargeProvider
    extends
        $FunctionalProvider<
          AsyncValue<Uint8List?>,
          Uint8List?,
          FutureOr<Uint8List?>
        >
    with $FutureModifier<Uint8List?>, $FutureProvider<Uint8List?> {
  /// A big picture of photo [id] for the replay.
  PhotoLargeProvider._({
    required PhotoLargeFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'photoLargeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$photoLargeHash();

  @override
  String toString() {
    return r'photoLargeProvider'
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
    return photoLarge(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PhotoLargeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$photoLargeHash() => r'03242a41374449b0f178b3d933b52363d3856f20';

/// A big picture of photo [id] for the replay.

final class PhotoLargeFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Uint8List?>, int> {
  PhotoLargeFamily._()
    : super(
        retry: null,
        name: r'photoLargeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A big picture of photo [id] for the replay.

  PhotoLargeProvider call(int id) =>
      PhotoLargeProvider._(argument: id, from: this);

  @override
  String toString() => r'photoLargeProvider';
}
