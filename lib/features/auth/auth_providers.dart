import 'package:melody/core/config/feature_flags.dart';
import 'package:melody/core/device/client_identity.dart';
import 'package:melody/data/repositories/source_factory.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/domain/repositories/server_connector.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

/// Sources the UI may offer (build-time flags); overridden in tests.
@Riverpod(keepAlive: true)
Set<SourceType> enabledSources(Ref ref) => FeatureFlags.enabledSources;

/// Kind of source being added or signed in to.
@Riverpod(keepAlive: true)
class SelectedSourceType extends _$SelectedSourceType {
  @override
  SourceType build() {
    final enabled = ref.watch(enabledSourcesProvider);
    return enabled.contains(SourceType.jellyfin)
        ? SourceType.jellyfin
        : enabled.first;
  }

  /// Switches to [type] when it is enabled.
  void select(SourceType type) {
    if (ref.read(enabledSourcesProvider).contains(type)) state = type;
  }
}

/// Signs users in to sources of the selected kind.
@Riverpod(keepAlive: true)
ServerConnector serverConnector(Ref ref) => createServerConnector(
  ref.watch(selectedSourceTypeProvider),
  ref.watch(clientIdentityProvider),
);

/// Users [server] lists on its sign-in page; empty when it hides them.
@riverpod
Future<List<PublicUser>> publicUsers(Ref ref, ServerInfo server) async {
  final result = await ref.watch(serverConnectorProvider).publicUsers(server);
  return result.valueOrNull ?? const [];
}

/// Whether [server] offers Quick Connect.
@riverpod
Future<bool> quickConnectAvailable(Ref ref, ServerInfo server) async {
  final result = await ref
      .watch(serverConnectorProvider)
      .quickConnectAvailable(server);
  return result.valueOrNull ?? false;
}
