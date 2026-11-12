import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

/// Thrown when a transfer was stopped on purpose.
class DownloadCancelled implements Exception {
  /// Creates the exception.
  const DownloadCancelled();
}

/// Lets a running transfer be stopped.
class DownloadHandle {
  final _token = CancelToken();

  /// Whether [cancel] was called.
  bool get isCancelled => _token.isCancelled;

  /// Completes when [cancel] is called.
  Future<void> get whenCancelled => _token.whenCancel;

  /// Stops the transfer; its future then fails with [DownloadCancelled].
  void cancel() {
    if (!_token.isCancelled) _token.cancel();
  }
}

/// Fetches files; replaced by a fake in tests.
abstract interface class DownloadTransport {
  /// Appends the bytes of [uri] to [target], continuing after what it
  /// already holds when the server allows it.
  ///
  /// [onProgress] receives the bytes on disk and the full size (0 when
  /// unknown).
  Future<void> fetch(
    Uri uri,
    File target, {
    required DownloadHandle handle,
    Map<String, String> headers = const {},
    void Function(int bytes, int total)? onProgress,
  });
}

/// [DownloadTransport] over HTTP with `Range` requests for resuming.
class DioDownloadTransport implements DownloadTransport {
  /// Creates the transport.
  DioDownloadTransport([Dio? dio])
    : _dio =
          dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 15)));

  final Dio _dio;

  @override
  Future<void> fetch(
    Uri uri,
    File target, {
    required DownloadHandle handle,
    Map<String, String> headers = const {},
    void Function(int bytes, int total)? onProgress,
  }) async {
    var offset = target.existsSync() ? target.lengthSync() : 0;
    try {
      final response = await _dio.getUri<ResponseBody>(
        uri,
        cancelToken: handle._token,
        options: Options(
          responseType: ResponseType.stream,
          headers: {...headers, if (offset > 0) 'Range': 'bytes=$offset-'},
          // 416: the file is already complete.
          validateStatus: (s) => s != null && (s < 300 || s == 416),
        ),
      );
      if (response.statusCode == 416) return;
      // The server ignored the range: start over.
      if (response.statusCode != 206) offset = 0;
      final length =
          int.tryParse(
            response.headers.value(Headers.contentLengthHeader) ?? '',
          ) ??
          0;
      final total = length > 0 ? offset + length : 0;
      final sink = target.openWrite(
        mode: offset > 0 ? FileMode.append : FileMode.write,
      );
      var bytes = offset;
      try {
        await for (final chunk in response.data!.stream) {
          sink.add(chunk);
          bytes += chunk.length;
          onProgress?.call(bytes, total);
        }
      } finally {
        await sink.close();
      }
      if (handle._token.isCancelled) throw const DownloadCancelled();
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) throw const DownloadCancelled();
      rethrow;
    }
  }
}
