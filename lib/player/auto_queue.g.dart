// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_queue.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Auto DJ bound to the player.

@ProviderFor(autoQueue)
final autoQueueProvider = AutoQueueProvider._();

/// Auto DJ bound to the player.

final class AutoQueueProvider
    extends
        $FunctionalProvider<
          AutoQueueService,
          AutoQueueService,
          AutoQueueService
        >
    with $Provider<AutoQueueService> {
  /// Auto DJ bound to the player.
  AutoQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoQueueHash();

  @$internal
  @override
  $ProviderElement<AutoQueueService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AutoQueueService create(Ref ref) {
    return autoQueue(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AutoQueueService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AutoQueueService>(value),
    );
  }
}

String _$autoQueueHash() => r'eaf38ae52e24d01948098429ef49c569c3383509';
