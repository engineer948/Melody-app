import 'package:dio/dio.dart';
import 'package:melody/core/device/client_identity.dart';
import 'package:melody/core/network/http_client.dart';

/// Thin HTTP layer for the Jellyfin REST API.
///
/// Methods throw `DioException`; callers convert them to failures.
class JellyfinApi {
  /// Creates a client for the server at [baseUrl].
  JellyfinApi({
    required this.baseUrl,
    required this.identity,
    this.token,
    HttpClientAdapter? adapter,
    void Function()? onUnauthorized,
    int retries = 2,
    Duration? connectTimeout,
    this.authHeader = 'Authorization',
  }) : _dio = createHttpClient(
         baseUrl: baseUrl,
         adapter: adapter,
         retries: retries,
         headers: {authHeader: authorization(identity, token: token)},
       ) {
    if (connectTimeout != null) _dio.options.connectTimeout = connectTimeout;
    if (onUnauthorized != null && token != null) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onError: (error, handler) {
            if (error.response?.statusCode == 401) onUnauthorized();
            handler.next(error);
          },
        ),
      );
    }
  }

  /// Root address of the server.
  final Uri baseUrl;

  /// Identity sent with every request.
  final ClientIdentity identity;

  /// Access token, absent before sign-in.
  final String? token;

  /// Header carrying [authorizationHeader]; Emby reads its own name.
  final String authHeader;

  final Dio _dio;

  /// Builds the `Authorization` header value.
  static String authorization(ClientIdentity identity, {String? token}) {
    String clean(String value) => value.replaceAll(RegExp('[",]'), '');
    return [
      'MediaBrowser Client="${clean(identity.clientName)}"',
      'Device="${clean(identity.deviceName)}"',
      'DeviceId="${clean(identity.deviceId)}"',
      'Version="${clean(identity.version)}"',
      if (token != null) 'Token="${clean(token)}"',
    ].join(', ');
  }

  /// The `Authorization` header of this client.
  String get authorizationHeader => authorization(identity, token: token);

  /// Absolute address of [path] with [query] parameters.
  Uri resolve(String path, [Map<String, String> query = const {}]) {
    final base = baseUrl.toString();
    final root = base.endsWith('/') ? base : '$base/';
    final uri = Uri.parse('$root$path');
    return query.isEmpty ? uri : uri.replace(queryParameters: query);
  }

  static Map<String, dynamic> _clean(Map<String, Object?> query) => {
    for (final entry in query.entries)
      if (entry.value != null) entry.key: '${entry.value}',
  };

  /// GET returning a JSON object.
  Future<Map<String, dynamic>> getObject(
    String path, [
    Map<String, Object?> query = const {},
  ]) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: _clean(query),
    );
    return response.data ?? const {};
  }

  /// GET returning a JSON array.
  Future<List<dynamic>> getList(
    String path, [
    Map<String, Object?> query = const {},
  ]) async {
    final response = await _dio.get<List<dynamic>>(
      path,
      queryParameters: _clean(query),
    );
    return response.data ?? const [];
  }

  /// GET returning a bare JSON value such as `true`.
  Future<Object?> getValue(String path) async =>
      (await _dio.get<Object?>(path)).data;

  /// POST returning a JSON object (empty when there is no body).
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, Object?> query = const {},
    Object? body,
  }) async {
    final response = await _dio.post<Object?>(
      path,
      queryParameters: _clean(query),
      data: body,
    );
    final data = response.data;
    return data is Map<String, dynamic> ? data : const {};
  }

  /// DELETE without a response body.
  Future<void> delete(String path, [Map<String, Object?> query = const {}]) =>
      _dio.delete<Object?>(path, queryParameters: _clean(query));

  /// Releases the underlying connections.
  void close() => _dio.close();
}
