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
          latitude: Value(event.place?.latitude),
          longitude: Value(event.place?.longitude),
          place: Value(event.place?.name),
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
            place: row.latitude == null || row.longitude == null
                ? null
                : PlayPlace(
                    latitude: row.latitude!,
                    longitude: row.longitude!,
                    name: row.place,
                  ),
          ),
        );
      } on Object {
        // Written by an incompatible version; skipped.
      }
    }
    return events;
  }

  /// The first play of [trackId] and how often it was played (not
  /// skipped), or `null` when it never was.
  Future<({PlayEvent first, int plays})?> memoryOf(
    String accountId,
    String trackId,
  ) async {
    final rows =
        await (_db.select(_db.playHistory)
              ..where(
                (t) =>
                    t.accountId.equals(accountId) & t.trackId.equals(trackId),
              )
              ..orderBy([(t) => OrderingTerm(expression: t.startedAt)]))
            .get();
    if (rows.isEmpty) return null;
    final first = rows.first;
    final Track track;
    try {
      track = Track.fromJson(jsonDecode(first.payload) as Map<String, dynamic>);
    } on Object {
      return null;
    }
    return (
      first: PlayEvent(
        track: track,
        startedAt: first.startedAt,
        listened: Duration(milliseconds: first.listenedMs),
        skipped: first.skipped,
        place: first.latitude == null || first.longitude == null
            ? null
            : PlayPlace(
                latitude: first.latitude!,
                longitude: first.longitude!,
                name: first.place,
              ),
      ),
      plays: rows.where((r) => !r.skipped).length,
    );
  }

  /// When each song of [accountId] was first played, by track id.
  Future<Map<String, DateTime>> firstPlays(String accountId) async {
    final first = _db.playHistory.startedAt.min();
    final query = _db.selectOnly(_db.playHistory)
      ..addColumns([_db.playHistory.trackId, first])
      ..where(_db.playHistory.accountId.equals(accountId))
      ..groupBy([_db.playHistory.trackId]);
    return {
      for (final row in await query.get())
        if (row.read(first) case final DateTime at)
          row.read(_db.playHistory.trackId)!: at,
    };
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
