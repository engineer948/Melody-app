import 'package:melody/core/config/feature_flags.dart';
import 'package:melody/core/device/client_identity.dart';
import 'package:melody/data/repositories/source_factory.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/domain/repositories/server_connector.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

/// Signs users in; only Jellyfin is offered for now.
@Riverpod(keepAlive: true)
ServerConnector serverConnector(Ref ref) => createServerConnector(
  SourceType.jellyfin,
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
