import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:melody/core/errors/failure.dart';

/// Converts anything thrown by the network layer into a [Failure].
Failure mapNetworkError(Object error) {
  if (error is Failure) return error;
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return TimeoutFailure(cause: error);
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return NetworkFailure(cause: error);
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        return switch (status) {
          401 => UnauthorizedFailure(cause: error),
          404 => NotFoundFailure(cause: error),
          _ => ServerFailure(statusCode: status, cause: error),
        };
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        final inner = error.error;
        if (inner is SocketException || inner is HandshakeException) {
          return NetworkFailure(cause: error);
        }
        if (inner is FormatException || inner is TypeError) {
          return ParsingFailure(cause: error);
        }
        return UnknownFailure(cause: error);
    }
  }
  if (error is SocketException) return NetworkFailure(cause: error);
  if (error is TimeoutException) return TimeoutFailure(cause: error);
  if (error is FormatException || error is TypeError) {
    return ParsingFailure(cause: error);
  }
  return UnknownFailure(cause: error);
}
