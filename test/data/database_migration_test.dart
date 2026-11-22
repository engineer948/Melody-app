import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/data/db/app_database.dart';

void main() {
  test('a version 1 database gains the history and download tables', () async {
    // The schema as it was shipped up to 0.4.1.
    final executor = NativeDatabase.memory(
      setup: (raw) {
        raw
          ..execute(
            'CREATE TABLE accounts (id TEXT NOT NULL PRIMARY KEY, '
            'payload TEXT NOT NULL, created_at INTEGER NOT NULL)',
          )
          ..execute(
            'CREATE TABLE cached_items (account_id TEXT NOT NULL, '
            'kind TEXT NOT NULL, item_id TEXT NOT NULL, name TEXT NOT NULL, '
            'payload TEXT NOT NULL, updated_at INTEGER NOT NULL, '
            'PRIMARY KEY (account_id, kind, item_id))',
          )
          ..execute(
            'CREATE TABLE cached_lists (account_id TEXT NOT NULL, '
            'list_key TEXT NOT NULL, item_ids TEXT NOT NULL, '
            'updated_at INTEGER NOT NULL, PRIMARY KEY (account_id, list_key))',
          )
          ..execute("INSERT INTO accounts VALUES ('acc1', '{}', 1700000000)")
          ..execute('PRAGMA user_version = 1');
      },
    );
    final db = AppDatabase(executor);
    addTearDown(db.close);

    // Old data survives and the new tables work.
    expect(await db.select(db.accounts).get(), hasLength(1));
    await db
        .into(db.playHistory)
        .insert(
          PlayHistoryCompanion.insert(
            accountId: 'acc1',
            trackId: 't1',
            payload: '{}',
            startedAt: DateTime(2026),
            listenedMs: 1000,
            durationMs: 2000,
            skipped: false,
          ),
        );
    await db
        .into(db.downloads)
        .insert(
          DownloadsCompanion.insert(
            accountId: 'acc1',
            trackId: 't1',
            payload: '{}',
            status: 'queued',
            fileName: 'f',
            origins: '[]',
            createdAt: DateTime(2026),
          ),
        );
    expect(await db.select(db.playHistory).get(), hasLength(1));
    final download = await db.select(db.downloads).getSingle();
    expect(download.bytes, 0);
    expect(
      await db
          .customSelect('PRAGMA user_version')
          .map((row) => row.read<int>('user_version'))
          .getSingle(),
      4,
    );
  });

  test('a version 2 database gains the place columns', () async {
    final executor = NativeDatabase.memory(
      setup: (raw) {
        raw
          ..execute(
            'CREATE TABLE accounts (id TEXT NOT NULL PRIMARY KEY, '
            'payload TEXT NOT NULL, created_at INTEGER NOT NULL)',
          )
          ..execute(
            'CREATE TABLE cached_items (account_id TEXT NOT NULL, '
            'kind TEXT NOT NULL, item_id TEXT NOT NULL, name TEXT NOT NULL, '
            'payload TEXT NOT NULL, updated_at INTEGER NOT NULL, '
            'PRIMARY KEY (account_id, kind, item_id))',
          )
          ..execute(
            'CREATE TABLE cached_lists (account_id TEXT NOT NULL, '
            'list_key TEXT NOT NULL, item_ids TEXT NOT NULL, '
            'updated_at INTEGER NOT NULL, PRIMARY KEY (account_id, list_key))',
          )
          ..execute(
            'CREATE TABLE play_history (id INTEGER NOT NULL PRIMARY KEY '
            'AUTOINCREMENT, account_id TEXT NOT NULL, track_id TEXT NOT NULL, '
            'payload TEXT NOT NULL, started_at INTEGER NOT NULL, '
            'listened_ms INTEGER NOT NULL, duration_ms INTEGER NOT NULL, '
            'skipped INTEGER NOT NULL CHECK (skipped IN (0, 1)))',
          )
          ..execute(
            'CREATE TABLE downloads (account_id TEXT NOT NULL, '
            'track_id TEXT NOT NULL, payload TEXT NOT NULL, '
            'status TEXT NOT NULL, bytes INTEGER NOT NULL DEFAULT 0, '
            'total_bytes INTEGER NOT NULL DEFAULT 0, '
            'file_name TEXT NOT NULL, origins TEXT NOT NULL, '
            'created_at INTEGER NOT NULL, '
            'PRIMARY KEY (account_id, track_id))',
          )
          ..execute(
            'INSERT INTO play_history (account_id, track_id, payload, '
            'started_at, listened_ms, duration_ms, skipped) '
            "VALUES ('acc1', 't1', '{}', 1700000000, 1000, 2000, 0)",
          )
          ..execute('PRAGMA user_version = 2');
      },
    );
    final db = AppDatabase(executor);
    addTearDown(db.close);
    final old = await db.select(db.playHistory).getSingle();
    expect(old.latitude, isNull);
    await db
        .into(db.playHistory)
        .insert(
          PlayHistoryCompanion.insert(
            accountId: 'acc1',
            trackId: 't2',
            payload: '{}',
            startedAt: DateTime(2026),
            listenedMs: 1000,
            durationMs: 2000,
            skipped: false,
            latitude: const Value(40.38),
            longitude: const Value(49.89),
            place: const Value('Sahil, Bakı'),
          ),
        );
    final rows = await db.select(db.playHistory).get();
    expect(rows.last.place, 'Sahil, Bakı');
    // And the song memories table of version 4.
    await db
        .into(db.songNotes)
        .insert(
          SongNotesCompanion.insert(
            accountId: 'acc1',
            trackId: 't1',
            payload: '{}',
            body: 'First dance',
            updatedAt: DateTime(2026),
          ),
        );
    expect(await db.select(db.songNotes).get(), hasLength(1));
  });
}
