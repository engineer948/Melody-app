import 'dart:convert';

import 'package:melody/player/play_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saved queue and position, restored on the next start.
typedef SavedQueue = ({PlayQueue queue, Duration position, String accountId});

/// Persists the queue so playback can resume after a restart.
class QueueStore {
  /// Creates the store.
  QueueStore(this._prefs);

  final SharedPreferences _prefs;

  /// Preference key.
  static const key = 'player.queue';

  /// Saves [queue] of [accountId] at [position].
  Future<void> save(String accountId, PlayQueue queue, Duration position) =>
      queue.isEmpty
      ? _prefs.remove(key)
      : _prefs.setString(
          key,
          jsonEncode({
            'accountId': accountId,
            'positionMs': position.inMilliseconds,
            'queue': queue.toJson(),
          }),
        );

  /// The saved queue, or `null` when there is none or it is unreadable.
  SavedQueue? load() {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return (
        queue: PlayQueue.fromJson(json['queue'] as Map<String, dynamic>),
        position: Duration(milliseconds: json['positionMs'] as int? ?? 0),
        accountId: json['accountId'] as String,
      );
    } on Object {
      return null;
    }
  }

  /// Forgets the saved queue.
  Future<void> clear() => _prefs.remove(key);
}
