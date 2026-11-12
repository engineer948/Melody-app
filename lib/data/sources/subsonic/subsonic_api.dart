import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/network/http_client.dart';

/// Credentials for the Subsonic API: the user name and a salted token.
///
/// The token is `md5(password + salt)`; the password itself is never kept.
class SubsonicCredentials {
  /// Creates credentials from a stored token.
  const SubsonicCredentials({
    required this.user,
    required this.token,
    required this.salt,
  });

  /// Derives credentials from a password with a fresh random salt.
  factory SubsonicCredentials.fromPassword(
    String user,
    String password, {
    Random? random,
  }) {
    final rnd = random ?? Random.secure();
    final salt = List.generate(
      12,
      (_) => rnd.nextInt(36).toRadixString(36),
    ).join();
    final token = md5.convert(utf8.encode(password + salt)).toString();
    return SubsonicCredentials(user: user, token: token, salt: salt);
  }

  /// Restores credentials saved with [encode].
  factory SubsonicCredentials.decode(String user, String stored) {
    final json = jsonDecode(stored) as Map<String, dynamic>;
    return SubsonicCredentials(
      user: user,
      token: json['t'] as String,
      salt: json['s'] as String,
    );
  }

  /// User name.
  final String user;

  /// `md5(password + salt)`.
  final String token;

  /// Random salt.
  final String salt;

  /// Text kept in secure storage as the account's access token.
  String encode() => jsonEncode({'t': token, 's': salt});
}

/// Error reported inside a Subsonic response.
class SubsonicError implements Exception {
  /// Creates the error.
  const SubsonicError(this.code, this.message);

  /// Subsonic error code (40 wrong credentials, 70 not found, ...).
  final int code;

  /// Server message.
  final String message;

  /// The matching app failure.
  Failure get failure => switch (code) {
    40 || 41 || 44 => const UnauthorizedFailure(),
    50 => const UnauthorizedFailure(),
    70 => const NotFoundFailure(),
    0 when message.contains('not implemented') => const UnsupportedFailure(),
    _ => ServerFailure(statusCode: code),
  };

  @override
  String toString() => 'SubsonicError($code, $message)';
}

/// Thin HTTP layer for the Subsonic / OpenSubsonic REST API (JSON).
class SubsonicApi {
  /// Creates a client for the server at [baseUrl].
  SubsonicApi({
    required this.baseUrl,
    this.credentials,
    this.clientName = 'Melody',
    HttpClientAdapter? adapter,
    this._onUnauthorized,
    int retries = 2,
  }) : _dio = createHttpClient(
         baseUrl: baseUrl,
         adapter: adapter,
         retries: retries,
       );

  /// Root address of the server.
  final Uri baseUrl;

  /// Signed-in user; `null` while probing.
  final SubsonicCredentials? credentials;

  /// Client name sent as `c`.
  final String clientName;

  final Dio _dio;
  final void Function()? _onUnauthorized;

  /// Protocol version announced to the server.
  static const apiVersion = '1.16.1';

  /// Authentication and format parameters sent with every request.
  Map<String, String> get authParams => {
    if (credentials case final c?) ...{'u': c.user, 't': c.token, 's': c.salt},
    'v': apiVersion,
    'c': clientName,
    'f': 'json',
  };

  /// Absolute address of the endpoint [method] (e.g. `stream`), with
  /// authentication; used for streams and cover images.
  Uri resolve(String method, [Map<String, String> query = const {}]) {
    final base = baseUrl.toString();
    final root = base.endsWith('/') ? base : '$base/';
    return Uri.parse('${root}rest/$method')
        .replace(queryParameters: {...authParams, ...query});
  }

  static Map<String, dynamic> _clean(Map<String, Object?> query) => {
    for (final entry in query.entries)
      if (entry.value case final value?)
        entry.key: value is List ? [for (final v in value) '$v'] : '$value',
  };

  /// Calls [method] and returns the inner `subsonic-response` object.
  ///
  /// Throws [SubsonicError] when the server reports a failure.
  Future<Map<String, dynamic>> get(
    String method, [
    Map<String, Object?> query = const {},
  ]) async {
    final response = await _dio.get<Object?>(
      'rest/$method',
      queryParameters: {...authParams, ..._clean(query)},
      options: Options(listFormat: ListFormat.multi),
    );
    final data = response.data;
    final body = data is String ? jsonDecode(data) : data;
    if (body is! Map<String, dynamic>) throw const ParsingFailure();
    final inner = body['subsonic-response'];
    if (inner is! Map<String, dynamic>) throw const ParsingFailure();
    if (inner['status'] != 'ok') {
      final error = inner['error'];
      final code = error is Map ? (error['code'] as num?)?.toInt() ?? 0 : 0;
      final message = error is Map ? '${error['message'] ?? ''}' : '';
      if (code == 40 || code == 41 || code == 44) _onUnauthorized?.call();
      throw SubsonicError(code, message);
    }
    return inner;
  }

  /// Releases the underlying connections.
  void close() => _dio.close();
}
