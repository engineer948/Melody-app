// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_recorder.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The on-device listening history.

@ProviderFor(historyStore)
final historyStoreProvider = HistoryStoreProvider._();

/// The on-device listening history.

final class HistoryStoreProvider
    extends $FunctionalProvider<HistoryStore, HistoryStore, HistoryStore>
    with $Provider<HistoryStore> {
  /// The on-device listening history.
  HistoryStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyStoreHash();

  @$internal
  @override
  $ProviderElement<HistoryStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HistoryStore create(Ref ref) {
    return historyStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HistoryStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HistoryStore>(value),
    );
  }
}

String _$historyStoreHash() => r'67d39711edc0b95236acd7dd3ec07cb185967fde';

/// The phone's places and photos (Android).

@ProviderFor(placesBridge)
final placesBridgeProvider = PlacesBridgeProvider._();

/// The phone's places and photos (Android).

final class PlacesBridgeProvider
    extends $FunctionalProvider<PlacesBridge, PlacesBridge, PlacesBridge>
    with $Provider<PlacesBridge> {
  /// The phone's places and photos (Android).
  PlacesBridgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placesBridgeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placesBridgeHash();

  @$internal
  @override
  $ProviderElement<PlacesBridge> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlacesBridge create(Ref ref) {
    return placesBridge(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlacesBridge value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlacesBridge>(value),
    );
  }
}

String _$placesBridgeHash() => r'33a40374a8b57ecc158ad20a0e3bdbde6692d96c';

/// Rough place of the phone, for "soundtrack of your life".

@ProviderFor(placeLocator)
final placeLocatorProvider = PlaceLocatorProvider._();

/// Rough place of the phone, for "soundtrack of your life".

final class PlaceLocatorProvider
    extends $FunctionalProvider<PlaceLocator, PlaceLocator, PlaceLocator>
    with $Provider<PlaceLocator> {
  /// Rough place of the phone, for "soundtrack of your life".
  PlaceLocatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placeLocatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placeLocatorHash();

  @$internal
  @override
  $ProviderElement<PlaceLocator> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlaceLocator create(Ref ref) {
    return placeLocator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaceLocator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaceLocator>(value),
    );
  }
}

String _$placeLocatorHash() => r'71559fa90a248569be0a00ab823a4441a39727b4';

/// Bumped whenever the history changes, so statistics and suggestions
/// refresh.

@ProviderFor(HistoryRevision)
final historyRevisionProvider = HistoryRevisionProvider._();

/// Bumped whenever the history changes, so statistics and suggestions
/// refresh.
final class HistoryRevisionProvider
    extends $NotifierProvider<HistoryRevision, int> {
  /// Bumped whenever the history changes, so statistics and suggestions
  /// refresh.
  HistoryRevisionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyRevisionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyRevisionHash();

  @$internal
  @override
  HistoryRevision create() => HistoryRevision();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$historyRevisionHash() => r'99cea70ac55905db2cb40ea1228b0e58bbf118ec';

/// Bumped whenever the history changes, so statistics and suggestions
/// refresh.

abstract class _$HistoryRevision extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Records what is played into the history while it is enabled.

@ProviderFor(historyRecorder)
final historyRecorderProvider = HistoryRecorderProvider._();

/// Records what is played into the history while it is enabled.

final class HistoryRecorderProvider
    extends
        $FunctionalProvider<HistoryRecorder, HistoryRecorder, HistoryRecorder>
    with $Provider<HistoryRecorder> {
  /// Records what is played into the history while it is enabled.
  HistoryRecorderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyRecorderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyRecorderHash();

  @$internal
  @override
  $ProviderElement<HistoryRecorder> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HistoryRecorder create(Ref ref) {
    return historyRecorder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HistoryRecorder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HistoryRecorder>(value),
    );
  }
}

String _$historyRecorderHash() => r'0dbcd90d268e74428fc7eb414f4a70d4aa0bb907';
