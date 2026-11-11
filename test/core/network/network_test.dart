import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/network/failure_mapper.dart';
import 'package:melody/core/network/http_client.dart';

import '../../helpers/fakes.dart';

void main() {
  final request = RequestOptions(path: '/x');

  DioException dio(DioExceptionType type, {int? status, Object? error}) =>
      DioException(
        requestOptions: request,
        type: type,
        error: error,
        response: status == null
            ? null
            : Response(requestOptions: request, statusCode: status),
      );

  test('maps Dio errors to failures', () {
    expect(
      mapNetworkError(dio(DioExceptionType.connectionError)),
      isA<NetworkFailure>(),
    );
    expect(
      mapNetworkError(dio(DioExceptionType.receiveTimeout)),
      isA<TimeoutFailure>(),
    );
    expect(
      mapNetworkError(dio(DioExceptionType.badResponse, status: 401)),
      isA<UnauthorizedFailure>(),
    );
    expect(
      mapNetworkError(dio(DioExceptionType.badResponse, status: 404)),
      isA<NotFoundFailure>(),
    );
    expect(
      mapNetworkError(dio(DioExceptionType.badResponse, status: 500)),
      isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 500),
    );
    expect(
      mapNetworkError(
        dio(DioExceptionType.unknown, error: const SocketException('down')),
      ),
      isA<NetworkFailure>(),
    );
    expect(
      mapNetworkError(
        dio(DioExceptionType.unknown, error: const FormatException()),
      ),
      isA<ParsingFailure>(),
    );
    expect(
      mapNetworkError(dio(DioExceptionType.unknown)),
      isA<UnknownFailure>(),
    );
  });

  test('maps plain errors and passes failures through', () {
    const failure = NotFoundFailure();
    expect(mapNetworkError(failure), same(failure));
    expect(mapNetworkError(TimeoutException('slow')), isA<TimeoutFailure>());
    expect(mapNetworkError(const FormatException()), isA<ParsingFailure>());
    expect(mapNetworkError(StateError('x')), isA<UnknownFailure>());
  });

  test('GET requests are retried after connection errors', () async {
    var calls = 0;
    final adapter = FakeHttpAdapter((options) {
      calls++;
      if (calls < 3) connectionError(options);
      return (status: 200, body: {'ok': true});
    });
    final client = createHttpClient(
      baseUrl: Uri.parse('https://example.com'),
      adapter: adapter,
    );
    client.interceptors
      ..removeWhere((i) => i is RetryInterceptor)
      ..insert(0, RetryInterceptor(client, baseDelay: Duration.zero));
    final response = await client.get<Map<String, dynamic>>('thing');
    expect(response.data, {'ok': true});
    expect(calls, 3);
  });

  test('POST requests and HTTP errors are not retried', () async {
    var calls = 0;
    final adapter = FakeHttpAdapter((options) {
      calls++;
      if (options.method == 'POST') connectionError(options);
      return (status: 500, body: null);
    });
    final client = createHttpClient(
      baseUrl: Uri.parse('https://example.com'),
      adapter: adapter,
    );
    await expectLater(client.post<void>('thing'), throwsA(isA<DioException>()));
    expect(calls, 1);
    await expectLater(client.get<void>('thing'), throwsA(isA<DioException>()));
    expect(calls, 2);
  });
}
