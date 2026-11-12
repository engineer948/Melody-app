import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:melody/core/logging/app_logger.dart';
import 'package:melody/domain/models/server.dart';

/// Finds Jellyfin servers on the local network with a UDP broadcast.
class JellyfinDiscovery {
  /// Creates the discovery helper.
  const JellyfinDiscovery({
    this.timeout = const Duration(seconds: 3),
    this.port = 7359,
    this.message = probeMessage,
    this._log = const AppLogger('discovery'),
  });

  /// Message sent to the network; Emby servers answer to their own.
  final String message;

  /// How long to wait for answers.
  final Duration timeout;

  /// UDP port servers listen on.
  final int port;

  final AppLogger _log;

  /// Message servers answer to.
  static const probeMessage = 'who is JellyfinServer?';

  /// Parses one answer datagram; `null` when it is not a server reply.
  static ServerInfo? parseReply(String payload) {
    try {
      final json = jsonDecode(payload);
      if (json is! Map<String, dynamic>) return null;
      final address = json['Address'];
      if (address is! String) return null;
      final uri = Uri.tryParse(address);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
      final name = json['Name'];
      final id = json['Id'];
      return ServerInfo(
        baseUrl: uri,
        name: name is String && name.isNotEmpty ? name : uri.host,
        id: id is String ? id : null,
      );
    } on FormatException {
      return null;
    }
  }

  /// Broadcasts the probe and emits every distinct server that answers.
  Stream<ServerInfo> scan() {
    final controller = StreamController<ServerInfo>();
    RawDatagramSocket? socket;
    Timer? timer;

    Future<void> stop() async {
      timer?.cancel();
      socket?.close();
      socket = null;
      if (!controller.isClosed) await controller.close();
    }

    controller
      ..onListen = () async {
        try {
          final bound = await RawDatagramSocket.bind(
            InternetAddress.anyIPv4,
            0,
          );
          socket = bound..broadcastEnabled = true;
          final seen = <String>{};
          bound.listen((event) {
            if (event != RawSocketEvent.read) return;
            final datagram = bound.receive();
            if (datagram == null) return;
            final server = parseReply(
              utf8.decode(datagram.data, allowMalformed: true),
            );
            if (server == null) return;
            if (seen.add(server.id ?? server.baseUrl.toString())) {
              controller.add(server);
            }
          });
          bound.send(
            utf8.encode(message),
            InternetAddress('255.255.255.255'),
            port,
          );
          timer = Timer(timeout, stop);
        } on Object catch (error) {
          _log.error('Discovery unavailable', error);
          await stop();
        }
      }
      ..onCancel = stop;
    return controller.stream;
  }
}
