import 'package:melody/core/errors/result.dart';
import 'package:melody/data/tailnet/invite_code.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/domain/repositories/server_connector.dart';
import 'package:melody/features/tailnet/tailnet_controller.dart';

/// Sends sign-in traffic for the tailnet server through the built-in
/// Tailscale proxy, while everything above keeps seeing the server's real
/// tailnet address (that is what gets saved with the account).
class TailnetRoutingConnector implements ServerConnector {
  /// Wraps [inner].
  const TailnetRoutingConnector(this.inner, this.router);

  /// The real connector.
  final ServerConnector inner;

  /// Address mapping.
  final TailnetRouter router;

  ServerInfo _in(ServerInfo s) => s.copyWith(baseUrl: router.route(s.baseUrl));

  ServerInfo _out(ServerInfo s) =>
      s.copyWith(baseUrl: router.unroute(s.baseUrl));

  Result<AuthSession> _session(Result<AuthSession> r) => switch (r) {
    Ok(value: final s) => Ok(
      s.copyWith(
        account: s.account.copyWith(baseUrl: router.unroute(s.account.baseUrl)),
      ),
    ),
    Err() => r,
  };

  @override
  Stream<ServerInfo> discover() => inner.discover();

  @override
  Future<Result<ServerInfo>> probe(String address) async {
    final url = TailnetInvite.parseServer(address);
    if (url == null || !router.handles(url) || router.local == null) {
      return await inner.probe(address);
    }
    final result = await inner.probe(router.route(url).toString());
    return switch (result) {
      Ok(value: final s) => Ok(_out(s)),
      Err() => result,
    };
  }

  /// Avatar URLs keep pointing at the proxy, so they load.
  @override
  Future<Result<List<PublicUser>>> publicUsers(ServerInfo server) =>
      inner.publicUsers(_in(server));

  @override
  Future<Result<AuthSession>> signIn(
    ServerInfo server, {
    required String username,
    required String password,
  }) async => _session(
    await inner.signIn(_in(server), username: username, password: password),
  );

  @override
  Future<Result<bool>> quickConnectAvailable(ServerInfo server) =>
      inner.quickConnectAvailable(_in(server));

  @override
  Future<Result<QuickConnectRequest>> quickConnectStart(ServerInfo server) =>
      inner.quickConnectStart(_in(server));

  @override
  Future<Result<bool>> quickConnectApproved(
    ServerInfo server,
    QuickConnectRequest request,
  ) => inner.quickConnectApproved(_in(server), request);

  @override
  Future<Result<AuthSession>> quickConnectSignIn(
    ServerInfo server,
    QuickConnectRequest request,
  ) async => _session(await inner.quickConnectSignIn(_in(server), request));
}
