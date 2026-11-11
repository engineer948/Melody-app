/// Reason an operation could not produce a value.
///
/// Failures carry no user-facing text; screens map them to localized
/// messages.
sealed class Failure implements Exception {
  const Failure({this.cause});

  /// Underlying exception, kept for logging only.
  final Object? cause;
}

/// The device is offline or the host could not be reached.
final class NetworkFailure extends Failure {
  /// Creates a [NetworkFailure].
  const NetworkFailure({super.cause});
}

/// The request took too long.
final class TimeoutFailure extends Failure {
  /// Creates a [TimeoutFailure].
  const TimeoutFailure({super.cause});
}

/// Credentials are missing, wrong or expired.
final class UnauthorizedFailure extends Failure {
  /// Creates an [UnauthorizedFailure].
  const UnauthorizedFailure({super.cause});
}

/// The requested item does not exist.
final class NotFoundFailure extends Failure {
  /// Creates a [NotFoundFailure].
  const NotFoundFailure({super.cause});
}

/// The server answered with an error status.
final class ServerFailure extends Failure {
  /// Creates a [ServerFailure].
  const ServerFailure({this.statusCode, super.cause});

  /// HTTP status code, when known.
  final int? statusCode;
}

/// The active source cannot perform the operation.
final class UnsupportedFailure extends Failure {
  /// Creates an [UnsupportedFailure].
  const UnsupportedFailure({super.cause});
}

/// The response could not be understood.
final class ParsingFailure extends Failure {
  /// Creates a [ParsingFailure].
  const ParsingFailure({super.cause});
}

/// Anything not covered by the other cases.
final class UnknownFailure extends Failure {
  /// Creates an [UnknownFailure].
  const UnknownFailure({super.cause});
}
