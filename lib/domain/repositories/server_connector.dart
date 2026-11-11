import 'package:melody/core/errors/result.dart';
import 'package:melody/domain/models/server.dart';

/// Finds servers of one kind and signs users in.
abstract interface class ServerConnector {
  /// Servers answering on the local network; completes after a short scan.
  Stream<ServerInfo> discover();

  /// Checks that [address] points at a compatible server.
  ///
  /// [address] may lack a scheme or port; sensible variants are tried.
  Future<Result<ServerInfo>> probe(String address);

  /// Users the server shows on its sign-in page.
  Future<Result<List<PublicUser>>> publicUsers(ServerInfo server);

  /// Signs in with a password. The password is never stored.
  Future<Result<AuthSession>> signIn(
    ServerInfo server, {
    required String username,
    required String password,
  });

  /// Whether the server offers Quick Connect.
  Future<Result<bool>> quickConnectAvailable(ServerInfo server);

  /// Starts a Quick Connect request and returns the code to show.
  Future<Result<QuickConnectRequest>> quickConnectStart(ServerInfo server);

  /// Whether the request has been approved on another device.
  Future<Result<bool>> quickConnectApproved(
    ServerInfo server,
    QuickConnectRequest request,
  );

  /// Signs in with an approved Quick Connect request.
  Future<Result<AuthSession>> quickConnectSignIn(
    ServerInfo server,
    QuickConnectRequest request,
  );
}
