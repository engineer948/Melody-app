// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Signs users in; only Jellyfin is offered for now.

@ProviderFor(serverConnector)
final serverConnectorProvider = ServerConnectorProvider._();

/// Signs users in; only Jellyfin is offered for now.

final class ServerConnectorProvider
    extends
        $FunctionalProvider<ServerConnector, ServerConnector, ServerConnector>
    with $Provider<ServerConnector> {
  /// Signs users in; only Jellyfin is offered for now.
  ServerConnectorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverConnectorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverConnectorHash();

  @$internal
  @override
  $ProviderElement<ServerConnector> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ServerConnector create(Ref ref) {
    return serverConnector(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServerConnector value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServerConnector>(value),
    );
  }
}

String _$serverConnectorHash() => r'536eb4ef5e2fafd0edb2c3b694cf18e7da066360';

/// Users [server] lists on its sign-in page; empty when it hides them.

@ProviderFor(publicUsers)
final publicUsersProvider = PublicUsersFamily._();

/// Users [server] lists on its sign-in page; empty when it hides them.

final class PublicUsersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PublicUser>>,
          List<PublicUser>,
          FutureOr<List<PublicUser>>
        >
    with $FutureModifier<List<PublicUser>>, $FutureProvider<List<PublicUser>> {
  /// Users [server] lists on its sign-in page; empty when it hides them.
  PublicUsersProvider._({
    required PublicUsersFamily super.from,
    required ServerInfo super.argument,
  }) : super(
         retry: null,
         name: r'publicUsersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$publicUsersHash();

  @override
  String toString() {
    return r'publicUsersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PublicUser>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PublicUser>> create(Ref ref) {
    final argument = this.argument as ServerInfo;
    return publicUsers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PublicUsersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$publicUsersHash() => r'241997ae1bc5c18fa5d09d95ade536b500d3ea98';

/// Users [server] lists on its sign-in page; empty when it hides them.

final class PublicUsersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PublicUser>>, ServerInfo> {
  PublicUsersFamily._()
    : super(
        retry: null,
        name: r'publicUsersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Users [server] lists on its sign-in page; empty when it hides them.

  PublicUsersProvider call(ServerInfo server) =>
      PublicUsersProvider._(argument: server, from: this);

  @override
  String toString() => r'publicUsersProvider';
}

/// Whether [server] offers Quick Connect.

@ProviderFor(quickConnectAvailable)
final quickConnectAvailableProvider = QuickConnectAvailableFamily._();

/// Whether [server] offers Quick Connect.

final class QuickConnectAvailableProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether [server] offers Quick Connect.
  QuickConnectAvailableProvider._({
    required QuickConnectAvailableFamily super.from,
    required ServerInfo super.argument,
  }) : super(
         retry: null,
         name: r'quickConnectAvailableProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$quickConnectAvailableHash();

  @override
  String toString() {
    return r'quickConnectAvailableProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as ServerInfo;
    return quickConnectAvailable(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is QuickConnectAvailableProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$quickConnectAvailableHash() =>
    r'0c105ccf589bea8d1b49672fcff37ed7fb3ccfae';

/// Whether [server] offers Quick Connect.

final class QuickConnectAvailableFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, ServerInfo> {
  QuickConnectAvailableFamily._()
    : super(
        retry: null,
        name: r'quickConnectAvailableProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether [server] offers Quick Connect.

  QuickConnectAvailableProvider call(ServerInfo server) =>
      QuickConnectAvailableProvider._(argument: server, from: this);

  @override
  String toString() => r'quickConnectAvailableProvider';
}
