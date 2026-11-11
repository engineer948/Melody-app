import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Signature of the function that finally emits a log line.
typedef LogSink = void Function(String message, {required String name});

/// Minimal logger that never prints secrets and stays silent in release.
class AppLogger {
  /// Creates a logger tagged with [name].
  const AppLogger(this.name, {LogSink? sink, bool? enabled})
    : _sink = sink ?? _developerSink,
      _enabled = enabled ?? !kReleaseMode;

  /// Tag shown next to every message.
  final String name;

  final LogSink _sink;
  final bool _enabled;

  static final _sensitiveParam = RegExp(
    r'((?:^|[?&\s])(?:api_?key|token|access_?token|password|pw|[tsp])=)[^&\s"]+',
    caseSensitive: false,
  );
  static final _headerToken = RegExp(
    r'''(Token=)(["']?)[^"',\s]+\2''',
    caseSensitive: false,
  );
  static final _bearer = RegExp(
    r'((?:Bearer|Basic)\s+)[\w\-.~+/=]+',
    caseSensitive: false,
  );

  /// Replaces tokens, passwords and credential query parameters in [input].
  static String redact(String input) => input
      .replaceAllMapped(_headerToken, (m) => '${m[1]}${m[2]}***${m[2]}')
      .replaceAllMapped(_bearer, (m) => '${m[1]}***')
      .replaceAllMapped(_sensitiveParam, (m) => '${m[1]}***');

  /// Logs an informational [message].
  void info(String message) => _emit(message);

  /// Logs a [message] together with an optional [error].
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    final details = [
      message,
      if (error != null) '$error',
      if (stackTrace != null) '$stackTrace',
    ].join('\n');
    _emit(details);
  }

  void _emit(String message) {
    if (!_enabled) return;
    _sink(redact(message), name: name);
  }

  static void _developerSink(String message, {required String name}) =>
      developer.log(message, name: name);
}
