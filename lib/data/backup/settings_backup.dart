import 'dart:convert';

import 'package:melody/domain/models/server.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A backup of the app's settings, smart playlists and server list (never
/// passwords or tokens), as one JSON file.
class SettingsBackup {
  /// Creates a backup.
  const SettingsBackup({
    required this.preferences,
    required this.accounts,
    required this.created,
  });

  /// Reads what can be backed up from [prefs] and [accounts].
  factory SettingsBackup.collect(
    SharedPreferences prefs,
    List<ServerAccount> accounts, {
    DateTime? now,
  }) => SettingsBackup(
    preferences: {
      for (final key in prefs.getKeys())
        if (includes(key))
          if (prefs.get(key) case final Object value) key: value,
    },
    accounts: accounts,
    created: now ?? DateTime.now(),
  );

  /// Reads a backup file; throws [FormatException] when it is not one.
  factory SettingsBackup.decode(String text) {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      throw const FormatException('not JSON');
    }
    if (json is! Map<String, dynamic> || json['kind'] != kind) {
      throw const FormatException('not a Melody settings backup');
    }
    if ((json['version'] as int? ?? 0) > version) {
      throw const FormatException('made by a newer version');
    }
    final prefs = <String, Object>{};
    for (final e
        in (json['preferences'] as Map<String, dynamic>? ?? {}).entries) {
      if (!includes(e.key)) continue;
      final entry = e.value;
      if (entry is! Map<String, dynamic>) continue;
      final value = switch ((entry['t'], entry['v'])) {
        ('b', final bool v) => v,
        ('i', final int v) => v,
        ('d', final num v) => v.toDouble(),
        ('s', final String v) => v,
        ('l', final List<dynamic> v) => v.whereType<String>().toList(),
        _ => null,
      };
      if (value != null) prefs[e.key] = value;
    }
    return SettingsBackup(
      preferences: prefs,
      accounts: [
        for (final a in json['accounts'] as List<dynamic>? ?? const [])
          if (_account(a) case final ServerAccount account) account,
      ],
      created:
          DateTime.tryParse(json['created'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Kind marker in the file.
  static const kind = 'melody-settings';

  /// File format version.
  static const version = 1;

  /// Preferences that belong to this phone only and are never backed up
  /// or restored: Tailscale keys and node, device id, active account,
  /// queue, unsent reports, guards.
  static const _excludedPrefixes = [
    'tailnet.',
    'session.',
    'app.deviceId',
    'player.queue',
    'player.pendingReports',
    'melody.',
    'update.',
  ];

  /// Whether the preference [key] is part of a backup.
  static bool includes(String key) =>
      !_excludedPrefixes.any((prefix) => key.startsWith(prefix));

  /// Settings by key.
  final Map<String, Object> preferences;

  /// Saved servers, without tokens.
  final List<ServerAccount> accounts;

  /// When the backup was made.
  final DateTime created;

  static ServerAccount? _account(Object? json) {
    try {
      return ServerAccount.fromJson(json! as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  /// The backup as JSON text.
  String encode() => const JsonEncoder.withIndent('  ').convert({
    'kind': kind,
    'version': version,
    'created': created.toUtc().toIso8601String(),
    'preferences': {
      for (final e in preferences.entries)
        e.key: switch (e.value) {
          final bool v => {'t': 'b', 'v': v},
          final int v => {'t': 'i', 'v': v},
          final double v => {'t': 'd', 'v': v},
          final String v => {'t': 's', 'v': v},
          final List<String> v => {'t': 'l', 'v': v},
          _ => {'t': '?'},
        },
    },
    'accounts': [for (final a in accounts) a.toJson()],
  });

  /// Writes the settings into [prefs]; settings missing from the backup
  /// are left as they are.
  Future<void> restoreInto(SharedPreferences prefs) async {
    for (final e in preferences.entries) {
      switch (e.value) {
        case final bool v:
          await prefs.setBool(e.key, v);
        case final int v:
          await prefs.setInt(e.key, v);
        case final double v:
          await prefs.setDouble(e.key, v);
        case final String v:
          await prefs.setString(e.key, v);
        case final List<String> v:
          await prefs.setStringList(e.key, v);
      }
    }
  }

  /// File name for a backup made on [day].
  static String fileName(DateTime day) =>
      'melody-settings-${day.year}-${_two(day.month)}-${_two(day.day)}.json';

  static String _two(int n) => n.toString().padLeft(2, '0');
}
