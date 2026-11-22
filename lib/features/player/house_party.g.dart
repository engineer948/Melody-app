// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'house_party.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// "House party": a small web page served from this phone on the local
/// network. Guests scan a QR code, search the library in their browser and
/// add songs to the queue; no app and no internet needed. Only someone
/// with the link (it carries a random key) can use it, and it stops when
/// the party ends or the app closes.

@ProviderFor(HouseParty)
final housePartyProvider = HousePartyProvider._();

/// "House party": a small web page served from this phone on the local
/// network. Guests scan a QR code, search the library in their browser and
/// add songs to the queue; no app and no internet needed. Only someone
/// with the link (it carries a random key) can use it, and it stops when
/// the party ends or the app closes.
final class HousePartyProvider
    extends $NotifierProvider<HouseParty, PartyState> {
  /// "House party": a small web page served from this phone on the local
  /// network. Guests scan a QR code, search the library in their browser and
  /// add songs to the queue; no app and no internet needed. Only someone
  /// with the link (it carries a random key) can use it, and it stops when
  /// the party ends or the app closes.
  HousePartyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'housePartyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$housePartyHash();

  @$internal
  @override
  HouseParty create() => HouseParty();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PartyState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PartyState>(value),
    );
  }
}

String _$housePartyHash() => r'614bee8cf7033bc928cbb069131290fd3fb7dab9';

/// "House party": a small web page served from this phone on the local
/// network. Guests scan a QR code, search the library in their browser and
/// add songs to the queue; no app and no internet needed. Only someone
/// with the link (it carries a random key) can use it, and it stops when
/// the party ends or the app closes.

abstract class _$HouseParty extends $Notifier<PartyState> {
  PartyState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PartyState, PartyState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PartyState, PartyState>,
              PartyState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
