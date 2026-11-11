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

String _$historyRecorderHash() => r'c66b09defa932ff270de1cfa1a98dfc3b4425a0c';
