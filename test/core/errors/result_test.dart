import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/errors/result.dart';

void main() {
  group('Result', () {
    test('Ok exposes its value', () {
      const result = Result.ok(42);
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, 42);
      expect(result.failureOrNull, isNull);
      expect(result.fold((v) => 'ok $v', (f) => 'err'), 'ok 42');
      expect(result, const Ok(42));
    });

    test('Err exposes its failure', () {
      const failure = NetworkFailure();
      const result = Result<int>.err(failure);
      expect(result.isOk, isFalse);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, same(failure));
      expect(result.fold((v) => 'ok', (f) => 'err'), 'err');
      expect(result, const Err<int>(failure));
    });

    test('map transforms values and keeps failures', () {
      expect(const Result.ok(2).map((v) => v * 2), const Ok(4));
      const failure = ServerFailure(statusCode: 500);
      expect(
        const Result<int>.err(failure).map((v) => '$v').failureOrNull,
        same(failure),
      );
    });

    test('guard captures thrown errors', () async {
      expect(await Result.guard(() async => 1), const Ok(1));

      final unknown = await Result.guard<int>(
        () async => throw const FormatException('bad'),
      );
      expect(unknown.failureOrNull, isA<UnknownFailure>());
      expect(unknown.failureOrNull?.cause, isA<FormatException>());

      final mapped = await Result.guard<int>(
        () async => throw StateError('x'),
        onError: (error) => ParsingFailure(cause: error),
      );
      expect(mapped.failureOrNull, isA<ParsingFailure>());
    });
  });
}
