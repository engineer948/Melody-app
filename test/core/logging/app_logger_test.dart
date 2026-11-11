import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/logging/app_logger.dart';

void main() {
  group('AppLogger.redact', () {
    test('masks the token of a MediaBrowser authorization header', () {
      const header =
          'Authorization: MediaBrowser Client="Melody", Device="Pixel", '
          'DeviceId="abc", Version="1.0", Token="s3cr3t"';
      final redacted = AppLogger.redact(header);
      expect(redacted, isNot(contains('s3cr3t')));
      expect(redacted, contains('Token="***"'));
      expect(redacted, contains('Client="Melody"'));
    });

    test('masks credential query parameters only', () {
      final query = [
        'u=ada',
        't=deadbeef',
        's=salt1',
        'id=42',
        'limit=50',
        'api_key=KEY',
        'format=opus',
      ].join('&');
      final redacted = AppLogger.redact(
        'GET https://music.example/rest/stream?$query',
      );
      expect(redacted, isNot(contains('deadbeef')));
      expect(redacted, isNot(contains('salt1')));
      expect(redacted, isNot(contains('KEY')));
      expect(redacted, contains('u=ada'));
      expect(redacted, contains('id=42'));
      expect(redacted, contains('limit=50'));
      expect(redacted, contains('format=opus'));
    });

    test('masks bearer tokens', () {
      expect(
        AppLogger.redact('Authorization: Bearer abc.def-123'),
        'Authorization: Bearer ***',
      );
    });
  });

  group('AppLogger', () {
    test('redacts before writing to the sink', () {
      final lines = <String>[];
      AppLogger(
        'test',
        enabled: true,
        sink: (message, {required name}) => lines.add('$name: $message'),
      ).error('request failed', 'url?token=abc');
      expect(lines.single, startsWith('test: request failed'));
      expect(lines.single, contains('token=***'));
    });

    test('stays silent when disabled', () {
      final lines = <String>[];
      AppLogger(
        'test',
        enabled: false,
        sink: (message, {required name}) => lines.add(message),
      ).info('hello');
      expect(lines, isEmpty);
    });
  });
}
