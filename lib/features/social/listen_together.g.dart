// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listen_together.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Listening-together transport of the active account; `null` when the
/// source has none (only Jellyfin / Emby).

@ProviderFor(syncPlayTransport)
final syncPlayTransportProvider = SyncPlayTransportProvider._();

/// Listening-together transport of the active account; `null` when the
/// source has none (only Jellyfin / Emby).

final class SyncPlayTransportProvider
    extends
        $FunctionalProvider<
          SyncPlayTransport?,
          SyncPlayTransport?,
          SyncPlayTransport?
        >
    with $Provider<SyncPlayTransport?> {
  /// Listening-together transport of the active account; `null` when the
  /// source has none (only Jellyfin / Emby).
  SyncPlayTransportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncPlayTransportProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncPlayTransportHash();

  @$internal
  @override
  $ProviderElement<SyncPlayTransport?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SyncPlayTransport? create(Ref ref) {
    return syncPlayTransport(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncPlayTransport? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncPlayTransport?>(value),
    );
  }
}

String _$syncPlayTransportHash() => r'ba0bc918f84d49eaf357c4c7f307c3599d0b6810';

/// Plays in step with a Jellyfin SyncPlay group.
///
/// While joined, the user's actions go to the group ([PlaybackRelay]); the
/// group's queue and commands are applied to the player at the server time
/// they name, so everyone hears the same moment.

@ProviderFor(ListenTogether)
final listenTogetherProvider = ListenTogetherProvider._();

/// Plays in step with a Jellyfin SyncPlay group.
///
/// While joined, the user's actions go to the group ([PlaybackRelay]); the
/// group's queue and commands are applied to the player at the server time
/// they name, so everyone hears the same moment.
final class ListenTogetherProvider
    extends $NotifierProvider<ListenTogether, ListenState> {
  /// Plays in step with a Jellyfin SyncPlay group.
  ///
  /// While joined, the user's actions go to the group ([PlaybackRelay]); the
  /// group's queue and commands are applied to the player at the server time
  /// they name, so everyone hears the same moment.
  ListenTogetherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listenTogetherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listenTogetherHash();

  @$internal
  @override
  ListenTogether create() => ListenTogether();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ListenState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ListenState>(value),
    );
  }
}

String _$listenTogetherHash() => r'2ca7e7517b8d36002a2dd959646bacd7648d98b0';

/// Plays in step with a Jellyfin SyncPlay group.
///
/// While joined, the user's actions go to the group ([PlaybackRelay]); the
/// group's queue and commands are applied to the player at the server time
/// they name, so everyone hears the same moment.

abstract class _$ListenTogether extends $Notifier<ListenState> {
  ListenState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ListenState, ListenState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ListenState, ListenState>,
              ListenState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
