import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:melody/data/db/app_database.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/stats/play_event.dart';

/// On-device listening history of every account. Nothing leaves the device.
class HistoryStore {
  /// Creates a store on top of [_db].
  HistoryStore(this._db);

  final AppDatabase _db;

  /// Records one play.
  Future<void> add(String accountId, PlayEvent event) => _db
      .into(_db.playHistory)
      .insert(
        PlayHistoryCompanion.insert(
          accountId: accountId,
          trackId: event.track.id,
          payload: jsonEncode(event.track.toJson()),
          startedAt: event.startedAt,
          listenedMs: event.listened.inMilliseconds,
          durationMs: event.track.duration?.inMilliseconds ?? 0,
          skipped: event.skipped,
        ),
      );

  /// Plays of [accountId], oldest first, optionally only those in
  /// [from, to).
  Future<List<PlayEvent>> events(
    String accountId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final query = _db.select(_db.playHistory)
      ..where((t) {
        var filter = t.accountId.equals(accountId);
        if (from != null) {
          filter = filter & t.startedAt.isBiggerOrEqualValue(from);
        }
        if (to != null) filter = filter & t.startedAt.isSmallerThanValue(to);
        return filter;
      })
      ..orderBy([(t) => OrderingTerm(expression: t.startedAt)]);
    final events = <PlayEvent>[];
    for (final row in await query.get()) {
      try {
        events.add(
          PlayEvent(
            track: Track.fromJson(
              jsonDecode(row.payload) as Map<String, dynamic>,
            ),
            startedAt: row.startedAt,
            listened: Duration(milliseconds: row.listenedMs),
            skipped: row.skipped,
          ),
        );
      } on Object {
        // Written by an incompatible version; skipped.
      }
    }
    return events;
  }

  /// Number of plays recorded for [accountId].
  Future<int> count(String accountId) async {
    final amount = _db.playHistory.id.count();
    final query = _db.selectOnly(_db.playHistory)
      ..addColumns([amount])
      ..where(_db.playHistory.accountId.equals(accountId));
    final row = await query.getSingle();
    return row.read<int>(amount) ?? 0;
  }

  /// Deletes the history of [accountId], or of everyone when `null`.
  Future<void> clear([String? accountId]) async {
    final delete = _db.delete(_db.playHistory);
    if (accountId != null) {
      delete.where((t) => t.accountId.equals(accountId));
    }
    await delete.go();
  }
}
