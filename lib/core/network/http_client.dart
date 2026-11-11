import 'dart:async';

import 'package:dio/dio.dart';
import 'package:melody/core/logging/app_logger.dart';

/// Builds the [Dio] instance used to talk to one server.
Dio createHttpClient({
  required Uri baseUrl,
  Map<String, String> headers = const {},
  HttpClientAdapter? adapter,
  AppLogger log = const AppLogger('http'),
  int retries = 2,
}) {
  final base = baseUrl.toString();
  final dio = Dio(
    BaseOptions(
      baseUrl: base.endsWith('/') ? base : '$base/',
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json', ...headers},
    ),
  );
  if (adapter != null) dio.httpClientAdapter = adapter;
  dio.transformer = BackgroundTransformer();
  dio.interceptors.addAll([
    RetryInterceptor(dio, retries: retries),
    RedactedLogInterceptor(log),
  ]);
  return dio;
}

/// Repeats idempotent requests that failed before reaching the server.
class RetryInterceptor extends Interceptor {
  /// Creates the interceptor for [_dio].
  RetryInterceptor(
    this._dio, {
    this.retries = 2,
    this.baseDelay = const Duration(milliseconds: 400),
  });

  final Dio _dio;

  /// Number of extra attempts.
  final int retries;

  /// Delay before the first retry; doubles every attempt.
  final Duration baseDelay;

  static const _attemptKey = 'melody.retryAttempt';

  static bool _isTransient(DioException e) => switch (e.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout => true,
    _ => false,
  };

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;
    final retryable = options.method == 'GET' && _isTransient(err);
    if (!retryable || attempt >= retries) return handler.next(err);
    await Future<void>.delayed(baseDelay * (1 << attempt));
    options.extra[_attemptKey] = attempt + 1;
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

/// Logs one line per request without leaking credentials.
class RedactedLogInterceptor extends Interceptor {
  /// Creates the interceptor writing to [_log].
  RedactedLogInterceptor(this._log);

  final AppLogger _log;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final request = response.requestOptions;
    _log.info('${request.method} ${request.uri} -> ${response.statusCode}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final request = err.requestOptions;
    _log.error(
      '${request.method} ${request.uri} failed: '
      '${err.response?.statusCode ?? err.type.name}',
    );
    handler.next(err);
  }
}
