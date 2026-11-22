// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_look.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The player's look, kept in preferences.

@ProviderFor(PlayerLookController)
final playerLookControllerProvider = PlayerLookControllerProvider._();

/// The player's look, kept in preferences.
final class PlayerLookControllerProvider
    extends $NotifierProvider<PlayerLookController, PlayerLook> {
  /// The player's look, kept in preferences.
  PlayerLookControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playerLookControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playerLookControllerHash();

  @$internal
  @override
  PlayerLookController create() => PlayerLookController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayerLook value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayerLook>(value),
    );
  }
}

String _$playerLookControllerHash() =>
    r'c1adc6916313b9a9402c11023c53eefb9947be03';

/// The player's look, kept in preferences.

abstract class _$PlayerLookController extends $Notifier<PlayerLook> {
  PlayerLook build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PlayerLook, PlayerLook>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlayerLook, PlayerLook>,
              PlayerLook,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
