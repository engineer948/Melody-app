import 'dart:math';

import 'package:dio/dio.dart';
import 'package:melody/core/config/feature_flags.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/data/sources/jellyfin/server_address.dart';
import 'package:melody/data/sources/subsonic/subsonic_api.dart';
import 'package:melody/data/sources/subsonic/subsonic_mapper.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/domain/repositories/server_connector.dart';

/// Signs users in to Subsonic-compatible servers.
///
/// Only the salted token is kept (see [SubsonicCredentials]); there is no
/// discovery, list of users or Quick Connect in this API.
class SubsonicConnector implements ServerConnector {
  /// Creates a connector.
  SubsonicConnector({this.adapter, this._random});

  /// Transport override for tests.
  final HttpClientAdapter? adapter;

  final Random? _random;

  /// Port Navidrome listens on by default.
  static const defaultPort = 4533;

  @override
  Stream<ServerInfo> discover() => const Stream.empty();

  @override
  Future<Result<ServerInfo>> probe(String address) async {
    final candidates = ServerAddress.candidates(
      address,
      httpPort: defaultPort,
      httpsPort: defaultPort,
    );
    if (candidates.isEmpty) return const Err(NotFoundFailure());
    final attempts = await Future.wait(candidates.map(_probeOne));
    for (final attempt in attempts) {
      if (attempt.isOk) return attempt;
    }
    return attempts.firstWhere(
      (a) => a.failureOrNull is! NetworkFailure,
      orElse: () => attempts.first,
    );
  }

  /// `ping` without credentials: any Subsonic answer, even "wrong
  /// credentials", proves the address.
  Future<Result<ServerInfo>> _probeOne(Uri baseUrl) async {
    final api = SubsonicApi(baseUrl: baseUrl, adapter: adapter, retries: 0);
    try {
      return await Result.guard(() async {
        Map<String, dynamic>? json;
        try {
          json = await api.get('ping');
        } on SubsonicError {
          json = null;
        }
        final kind = json?['type'] as String?;
        return ServerInfo(
          baseUrl: baseUrl,
          name: kind == null ? baseUrl.host : '$kind (${baseUrl.host})',
          version:
              json?['serverVersion'] as String? ?? json?['version'] as String?,
          type: SourceType.subsonic,
        );
      }, onError: mapSubsonicError);
    } finally {
      api.close();
    }
  }

  @override
  Future<Result<List<PublicUser>>> publicUsers(ServerInfo server) async =>
      const Ok([]);

  @override
  Future<Result<AuthSession>> signIn(
    ServerInfo server, {
    required String username,
    required String password,
  }) async {
    final credentials = SubsonicCredentials.fromPassword(
      username,
      password,
      random: _random,
    );
    final api = SubsonicApi(
      baseUrl: server.baseUrl,
      credentials: credentials,
      adapter: adapter,
    );
    try {
      return await Result.guard(() async {
        await api.get('ping');
        return AuthSession(
          accessToken: credentials.encode(),
          account: ServerAccount(
            id: '${SourceType.subsonic.name}:${server.baseUrl}:$username',
            type: SourceType.subsonic,
            baseUrl: server.baseUrl,
            serverName: server.name,
            serverVersion: server.version,
            userId: username,
            userName: username,
          ),
        );
      }, onError: mapSubsonicError);
    } finally {
      api.close();
    }
  }

  @override
  Future<Result<bool>> quickConnectAvailable(ServerInfo server) async =>
      const Ok(false);

  @override
  Future<Result<QuickConnectRequest>> quickConnectStart(
    ServerInfo server,
  ) async => const Err(UnsupportedFailure());

  @override
  Future<Result<bool>> quickConnectApproved(
    ServerInfo server,
    QuickConnectRequest request,
  ) async => const Err(UnsupportedFailure());

  @override
  Future<Result<AuthSession>> quickConnectSignIn(
    ServerInfo server,
    QuickConnectRequest request,
  ) async => const Err(UnsupportedFailure());
}
