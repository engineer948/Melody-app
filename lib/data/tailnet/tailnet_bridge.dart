import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Connection state of the built-in Tailscale node.
enum TailnetStatus {
  /// Not running.
  stopped,

  /// Connecting.
  starting,

  /// The tailnet wants a (new) auth key.
  needsLogin,

  /// Waiting for an admin to approve this device.
  needsApproval,

  /// Connected; the server can be reached.
  running,

  /// Something went wrong; see the error text.
  error,
}

/// One status report of the node.
@immutable
class TailnetReport {
  /// Creates a report.
  const TailnetReport(this.status, {this.error, this.ip, this.port});

  /// Parses the JSON from the Go library.
  factory TailnetReport.fromJson(String text) {
    final json = jsonDecode(text) as Map<String, dynamic>;
    final status =
        TailnetStatus.values.asNameMap()[json['state']] ?? TailnetStatus.error;
    return TailnetReport(
      status,
      error: json['error'] as String?,
      ip: json['ip'] as String?,
      port: json['port'] as int?,
    );
  }

  /// State.
  final TailnetStatus status;

  /// Error text from Tailscale, when [status] is [TailnetStatus.error].
  final String? error;

  /// This device's Tailscale IP once connected.
  final String? ip;

  /// Loopback port of the proxy.
  final int? port;
}

/// Talks to the Tailscale node compiled into the Android app
/// (native/tailscale, android/.../TailscaleChannel.kt).
abstract interface class TailnetBridge {
  /// Whether this build contains the node (Android with the Go library).
  Future<bool> available();

  /// Starts the node and the proxy; returns the proxy's port.
  Future<int> start({
    required String hostname,
    required Uri target,
    required String secret,
    required String stateKey,
    required int port,
    String authKey = '',
  });

  /// Current state.
  Future<TailnetReport> status();

  /// Disconnects, keeping this device's identity.
  Future<void> stop();

  /// Removes this device from the tailnet and deletes its keys.
  Future<void> logout();
}

/// [TailnetBridge] over the "melody/tailscale" platform channel.
class ChannelTailnetBridge implements TailnetBridge {
  /// Creates the bridge.
  const ChannelTailnetBridge();

  static const _channel = MethodChannel('melody/tailscale');

  @override
  Future<bool> available() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>('available') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<int> start({
    required String hostname,
    required Uri target,
    required String secret,
    required String stateKey,
    required int port,
    String authKey = '',
  }) async => (await _channel.invokeMethod<int>('start', {
    'authKey': authKey,
    'hostname': hostname,
    'target': target.toString(),
    'secret': secret,
    'port': port,
    'stateKey': stateKey,
  }))!;

  @override
  Future<TailnetReport> status() async => TailnetReport.fromJson(
    await _channel.invokeMethod<String>('status') ?? '{"state":"stopped"}',
  );

  @override
  Future<void> stop() => _channel.invokeMethod<void>('stop');

  @override
  Future<void> logout() => _channel.invokeMethod<void>('logout');
}
