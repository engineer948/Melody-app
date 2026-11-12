import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:melody/core/network/tailnet_address.dart';
import 'package:meta/meta.dart';

/// Why an invite (or the parts it is made of) was rejected.
enum InviteProblem {
  /// Not a Melody invite, or damaged (wrong characters, cut off).
  malformed,

  /// The text was changed: the checksum does not match.
  corrupted,

  /// Not a Tailscale auth key (`tskey-auth-…`). API keys and OAuth client
  /// secrets are refused on purpose: they would give full control over the
  /// tailnet.
  notAuthKey,

  /// The server is not a Tailscale address (100.x.y.z or *.ts.net).
  notTailnetServer,
}

/// Thrown by [TailnetInvite.decode] and [TailnetInvite.create].
class InviteException implements Exception {
  /// Creates the exception.
  const InviteException(this.problem);

  /// What is wrong.
  final InviteProblem problem;

  @override
  String toString() => 'InviteException($problem)';
}

/// What a friend needs to reach the music server: a Tailscale auth key and
/// the server's address inside the tailnet, packed into one text.
///
/// The text is only encoded, not encrypted: whoever has it can read the
/// key. Invites should therefore use one-time, short-lived, tagged keys.
@immutable
class TailnetInvite {
  const TailnetInvite._(this.authKey, this.server, this.name);

  /// Validates the parts and builds an invite.
  ///
  /// [server] may lack the scheme (http) and the port (8096).
  factory TailnetInvite.create({
    required String authKey,
    required String server,
    String? name,
  }) {
    final key = authKey.trim();
    if (!isAuthKey(key)) throw const InviteException(InviteProblem.notAuthKey);
    final url = parseServer(server);
    if (url == null) {
      throw const InviteException(InviteProblem.notTailnetServer);
    }
    final label = name?.trim();
    return TailnetInvite._(
      key,
      url,
      label == null || label.isEmpty ? null : label,
    );
  }

  /// Reads an invite made by [encode]; whitespace and line breaks (from
  /// chat apps) are ignored.
  factory TailnetInvite.decode(String text) {
    final compact = text.replaceAll(RegExp(r'\s'), '');
    final match = RegExp(r'^MELODY1-([A-Za-z0-9_-]+)\.([0-9a-f]{8})$')
        .firstMatch(compact);
    if (match == null) throw const InviteException(InviteProblem.malformed);
    final payload = match.group(1)!;
    if (_checksum(payload) != match.group(2)) {
      throw const InviteException(InviteProblem.corrupted);
    }
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(payload))),
      ) as Map<String, dynamic>;
    } on Object {
      throw const InviteException(InviteProblem.malformed);
    }
    final key = json['k'];
    final server = json['s'];
    final name = json['n'];
    if (key is! String ||
        server is! String ||
        (name != null && name is! String)) {
      throw const InviteException(InviteProblem.malformed);
    }
    return TailnetInvite.create(
      authKey: key,
      server: server,
      name: name as String?,
    );
  }

  /// Text prefix of every invite.
  static const prefix = 'MELODY1-';

  /// Tailscale auth key (`tskey-auth-…`).
  final String authKey;

  /// Music server inside the tailnet, e.g. `http://100.101.102.103:8096`.
  final Uri server;

  /// Optional label shown to the friend.
  final String? name;

  /// Whether [key] looks like a Tailscale auth key.
  static bool isAuthKey(String key) =>
      RegExp(r'^tskey-auth-[A-Za-z0-9_-]{8,200}$').hasMatch(key);

  /// Parses a tailnet server address; `null` when it is not one.
  static Uri? parseServer(String input) {
    var text = input.trim();
    while (text.endsWith('/')) {
      text = text.substring(0, text.length - 1);
    }
    if (text.isEmpty || text.contains(RegExp(r'\s'))) return null;
    if (!text.contains('://')) text = 'http://$text';
    final uri = Uri.tryParse(text);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !TailnetAddress.isTailnetHost(uri.host)) {
      return null;
    }
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : (uri.scheme == 'http' ? 8096 : 443),
      path: uri.path,
    );
  }

  static String _checksum(String payload) =>
      sha256.convert(utf8.encode(payload)).toString().substring(0, 8);

  /// The invite as one line of text: `MELODY1-<data>.<checksum>`.
  String encode() {
    final payload = base64Url
        .encode(
          utf8.encode(
            jsonEncode({'k': authKey, 's': server.toString(), 'n': ?name}),
          ),
        )
        .replaceAll('=', '');
    return '$prefix$payload.${_checksum(payload)}';
  }

  @override
  bool operator ==(Object other) =>
      other is TailnetInvite &&
      other.authKey == authKey &&
      other.server == server &&
      other.name == name;

  @override
  int get hashCode => Object.hash(authKey, server, name);

  /// Never prints the key.
  @override
  String toString() => 'TailnetInvite($server)';
}
