import 'package:dio/dio.dart';
import 'package:melody/core/config/feature_flags.dart';
import 'package:melody/core/device/client_identity.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/core/network/failure_mapper.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_api.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_discovery.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_dtos.dart';
import 'package:melody/data/sources/jellyfin/server_address.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/domain/repositories/server_connector.dart';

/// Signs users in to Jellyfin servers.
class JellyfinConnector implements ServerConnector {
  /// Creates a connector.
  JellyfinConnector({
    required this.identity,
    this.adapter,
    this.discovery = const JellyfinDiscovery(),
  });

  /// Identity sent to servers.
  final ClientIdentity identity;

  /// Transport override for tests.
  final HttpClientAdapter? adapter;

  /// Local network scanner.
  final JellyfinDiscovery discovery;

  JellyfinApi _api(Uri baseUrl, {bool probing = false}) => JellyfinApi(
    baseUrl: baseUrl,
    identity: identity,
    adapter: adapter,
    retries: probing ? 0 : 2,
    connectTimeout: probing ? const Duration(seconds: 5) : null,
  );

  Future<Result<T>> _run<T>(
    ServerInfo server,
    Future<T> Function(JellyfinApi api) body,
  ) async {
    final api = _api(server.baseUrl);
    try {
      return await Result.guard(() => body(api), onError: mapNetworkError);
    } finally {
      api.close();
    }
  }

  @override
  Stream<ServerInfo> discover() => discovery.scan();

  @override
  Future<Result<ServerInfo>> probe(String address) async {
    final candidates = ServerAddress.candidates(address);
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

  Future<Result<ServerInfo>> _probeOne(Uri baseUrl) async {
    final api = _api(baseUrl, probing: true);
    try {
      return await Result.guard(() async {
        final dto = PublicSystemInfoDto.fromJson(
          await api.getObject('System/Info/Public'),
        );
        if (dto.id == null && dto.version == null) {
          throw const ParsingFailure();
        }
        return ServerInfo(
          baseUrl: baseUrl,
          name: dto.serverName ?? baseUrl.host,
          id: dto.id,
          version: dto.version,
        );
      }, onError: mapNetworkError);
    } finally {
      api.close();
    }
  }

  @override
  Future<Result<List<PublicUser>>> publicUsers(ServerInfo server) =>
      _run(server, (api) async {
        final list = await api.getList('Users/Public');
        return [
          for (final raw in list.whereType<Map<String, dynamic>>())
            if (UserDto.fromJson(raw)
                case UserDto(:final id?, :final name?) && final user)
              PublicUser(
                id: id,
                name: name,
                hasPassword: user.hasPassword ?? true,
                avatar: user.primaryImageTag == null
                    ? null
                    : api.resolve('Users/$id/Images/Primary', {
                        'tag': user.primaryImageTag!,
                        'fillWidth': '160',
                        'fillHeight': '160',
                      }),
              ),
        ];
      });

  AuthSession _session(ServerInfo server, AuthenticationResultDto dto) {
    final token = dto.accessToken;
    final userId = dto.user?.id;
    if (token == null || userId == null) throw const ParsingFailure();
    final serverId = dto.serverId ?? server.id ?? server.baseUrl.toString();
    return AuthSession(
      accessToken: token,
      account: ServerAccount(
        id: '${SourceType.jellyfin.name}:$serverId:$userId',
        type: SourceType.jellyfin,
        baseUrl: server.baseUrl,
        serverName: server.name,
        serverId: serverId,
        serverVersion: server.version,
        userId: userId,
        userName: dto.user?.name ?? '',
      ),
    );
  }

  @override
  Future<Result<AuthSession>> signIn(
    ServerInfo server, {
    required String username,
    required String password,
  }) => _run(server, (api) async {
    final json = await api.post(
      'Users/AuthenticateByName',
      body: {'Username': username, 'Pw': password},
    );
    return _session(server, AuthenticationResultDto.fromJson(json));
  });

  @override
  Future<Result<bool>> quickConnectAvailable(ServerInfo server) =>
      _run(server, (api) async {
        return await api.getValue('QuickConnect/Enabled') == true;
      });

  @override
  Future<Result<QuickConnectRequest>> quickConnectStart(ServerInfo server) =>
      _run(server, (api) async {
        Map<String, dynamic> json;
        try {
          json = await api.post('QuickConnect/Initiate');
        } on DioException catch (error) {
          // Servers older than 10.9 expect GET here.
          if (error.response?.statusCode != 405) rethrow;
          json = await api.getObject('QuickConnect/Initiate');
        }
        final dto = QuickConnectResultDto.fromJson(json);
        final code = dto.code;
        final secret = dto.secret;
        if (code == null || secret == null) throw const ParsingFailure();
        return QuickConnectRequest(code: code, secret: secret);
      });

  @override
  Future<Result<bool>> quickConnectApproved(
    ServerInfo server,
    QuickConnectRequest request,
  ) => _run(server, (api) async {
    final json = await api.getObject('QuickConnect/Connect', {
      'secret': request.secret,
    });
    return QuickConnectResultDto.fromJson(json).authenticated ?? false;
  });

  @override
  Future<Result<AuthSession>> quickConnectSignIn(
    ServerInfo server,
    QuickConnectRequest request,
  ) => _run(server, (api) async {
    final json = await api.post(
      'Users/AuthenticateWithQuickConnect',
      body: {'Secret': request.secret},
    );
    return _session(server, AuthenticationResultDto.fromJson(json));
  });
}
