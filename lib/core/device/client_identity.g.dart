// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_identity.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Identity of this installation; overridden at startup with the real version.

@ProviderFor(clientIdentity)
final clientIdentityProvider = ClientIdentityProvider._();

/// Identity of this installation; overridden at startup with the real version.

final class ClientIdentityProvider
    extends $FunctionalProvider<ClientIdentity, ClientIdentity, ClientIdentity>
    with $Provider<ClientIdentity> {
  /// Identity of this installation; overridden at startup with the real version.
  ClientIdentityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clientIdentityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clientIdentityHash();

  @$internal
  @override
  $ProviderElement<ClientIdentity> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ClientIdentity create(Ref ref) {
    return clientIdentity(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClientIdentity value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClientIdentity>(value),
    );
  }
}

String _$clientIdentityHash() => r'aca4d149f69aacf4626cf1e47e23caad04caa0b0';
