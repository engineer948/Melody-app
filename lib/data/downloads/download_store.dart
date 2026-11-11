import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:melody/data/db/app_database.dart';
import 'package:melody/data/downloads/download_models.dart';
import 'package:melody/domain/models/media.dart';

/// Persists the list of downloads of every account.
class DownloadStore {
  /// Creates a store on top of [_db].
  DownloadStore(this._db);

  final AppDatabase _db;

  /// Downloads of [accountId] in the order they were requested.
  Future<List<DownloadItem>> load(String accountId) async {
    final rows =
        await (_db.select(_db.downloads)
              ..where((t) => t.accountId.equals(accountId))
              ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
            .get();
    final items = <DownloadItem>[];
    for (final row in rows) {
      try {
        items.add(
          DownloadItem(
            track: Track.fromJson(
              jsonDecode(row.payload) as Map<String, dynamic>,
            ),
            fileName: row.fileName,
            status:
                DownloadStatus.values.asNameMap()[row.status] ??
                DownloadStatus.queued,
            bytes: row.bytes,
            totalBytes: row.totalBytes,
            origins: (jsonDecode(row.origins) as List<dynamic>)
                .cast<String>()
                .toSet(),
          ),
        );
      } on Object {
        // Written by an incompatible version; skipped.
      }
    }
    return items;
  }

  /// Inserts or updates [item], keeping its original request time.
  Future<void> save(String accountId, DownloadItem item) async {
    final updated =
        await (_db.update(_db.downloads)..where(
              (t) =>
                  t.accountId.equals(accountId) &
                  t.trackId.equals(item.track.id),
            ))
            .write(
              DownloadsCompanion(
                payload: Value(jsonEncode(item.track.toJson())),
                status: Value(item.status.name),
                bytes: Value(item.bytes),
                totalBytes: Value(item.totalBytes),
                origins: Value(jsonEncode(item.origins.toList())),
              ),
            );
    if (updated > 0) return;
    await _db
        .into(_db.downloads)
        .insert(
          DownloadsCompanion.insert(
            accountId: accountId,
            trackId: item.track.id,
            payload: jsonEncode(item.track.toJson()),
            status: item.status.name,
            bytes: Value(item.bytes),
            totalBytes: Value(item.totalBytes),
            fileName: item.fileName,
            origins: jsonEncode(item.origins.toList()),
            createdAt: DateTime.now(),
          ),
        );
  }

  /// Forgets the download of [trackId].
  Future<void> remove(String accountId, String trackId) =>
      (_db.delete(_db.downloads)..where(
            (t) => t.accountId.equals(accountId) & t.trackId.equals(trackId),
          ))
          .go();
}
