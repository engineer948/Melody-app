// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sources the UI may offer (build-time flags); overridden in tests.

@ProviderFor(enabledSources)
final enabledSourcesProvider = EnabledSourcesProvider._();

/// Sources the UI may offer (build-time flags); overridden in tests.

final class EnabledSourcesProvider
    extends
        $FunctionalProvider<Set<SourceType>, Set<SourceType>, Set<SourceType>>
    with $Provider<Set<SourceType>> {
  /// Sources the UI may offer (build-time flags); overridden in tests.
  EnabledSourcesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'enabledSourcesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$enabledSourcesHash();

  @$internal
  @override
  $ProviderElement<Set<SourceType>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<SourceType> create(Ref ref) {
    return enabledSources(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<SourceType> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<SourceType>>(value),
    );
  }
}

String _$enabledSourcesHash() => r'3baf904f72790ea757e9a2272a0c130ff185ad46';

/// Kind of source being added or signed in to.

@ProviderFor(SelectedSourceType)
final selectedSourceTypeProvider = SelectedSourceTypeProvider._();

/// Kind of source being added or signed in to.
final class SelectedSourceTypeProvider
    extends $NotifierProvider<SelectedSourceType, SourceType> {
  /// Kind of source being added or signed in to.
  SelectedSourceTypeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedSourceTypeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedSourceTypeHash();

  @$internal
  @override
  SelectedSourceType create() => SelectedSourceType();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SourceType value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SourceType>(value),
    );
  }
}

String _$selectedSourceTypeHash() =>
    r'd4373b3a2f4a1fb1bbae586b20dd4f98f01ab9d4';

/// Kind of source being added or signed in to.

abstract class _$SelectedSourceType extends $Notifier<SourceType> {
  SourceType build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SourceType, SourceType>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SourceType, SourceType>,
              SourceType,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Signs users in to sources of the selected kind; a server reached
/// through the built-in Tailscale node goes through its proxy.

@ProviderFor(serverConnector)
final serverConnectorProvider = ServerConnectorProvider._();

/// Signs users in to sources of the selected kind; a server reached
/// through the built-in Tailscale node goes through its proxy.

final class ServerConnectorProvider
    extends
        $FunctionalProvider<ServerConnector, ServerConnector, ServerConnector>
    with $Provider<ServerConnector> {
  /// Signs users in to sources of the selected kind; a server reached
  /// through the built-in Tailscale node goes through its proxy.
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

String _$serverConnectorHash() => r'ccac2d8e070fde33b31ad0dccdd1821fb55082ba';

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
