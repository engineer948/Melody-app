import 'package:melody/core/errors/failure.dart';
import 'package:meta/meta.dart';

/// Outcome of an operation that can fail without throwing.
@immutable
sealed class Result<T> {
  const Result();

  /// Wraps a successful [value].
  const factory Result.ok(T value) = Ok<T>;

  /// Wraps a [failure].
  const factory Result.err(Failure failure) = Err<T>;

  /// Runs [body] and converts thrown errors with [onError].
  static Future<Result<T>> guard<T>(
    Future<T> Function() body, {
    Failure Function(Object error)? onError,
  }) async {
    try {
      return Ok(await body());
    } on Object catch (error) {
      return Err(onError?.call(error) ?? UnknownFailure(cause: error));
    }
  }

  /// Whether this is an [Ok].
  bool get isOk => this is Ok<T>;

  /// The value, or `null` for an [Err].
  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  /// The failure, or `null` for an [Ok].
  Failure? get failureOrNull => switch (this) {
    Ok() => null,
    Err(:final failure) => failure,
  };

  /// Collapses both cases into a single value.
  R fold<R>(R Function(T value) onOk, R Function(Failure failure) onErr) =>
      switch (this) {
        Ok(:final value) => onOk(value),
        Err(:final failure) => onErr(failure),
      };

  /// Transforms the value, leaving failures untouched.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok(:final value) => Ok(transform(value)),
    Err(:final failure) => Err(failure),
  };
}

/// Successful [Result].
final class Ok<T> extends Result<T> {
  /// Creates an [Ok] holding [value].
  const Ok(this.value);

  /// The produced value.
  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok, value);

  @override
  String toString() => 'Ok($value)';
}

/// Failed [Result].
final class Err<T> extends Result<T> {
  /// Creates an [Err] holding [failure].
  const Err(this.failure);

  /// Why the operation failed.
  final Failure failure;

  @override
  bool operator ==(Object other) => other is Err<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Err, failure);

  @override
  String toString() => 'Err($failure)';
}
