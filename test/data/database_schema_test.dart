// The old schemas are kept as they were written, one statement per item.
// ignore_for_file: no_adjacent_strings_in_list

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/data/db/app_database.dart';

const List<String> _v1 = [
  'CREATE TABLE accounts (id TEXT NOT NULL PRIMARY KEY, '
      'payload TEXT NOT NULL, created_at INTEGER NOT NULL)',
  'CREATE TABLE cached_items (account_id TEXT NOT NULL, '
      'kind TEXT NOT NULL, item_id TEXT NOT NULL, name TEXT NOT NULL, '
      'payload TEXT NOT NULL, updated_at INTEGER NOT NULL, '
      'PRIMARY KEY (account_id, kind, item_id))',
  'CREATE TABLE cached_lists (account_id TEXT NOT NULL, '
      'list_key TEXT NOT NULL, item_ids TEXT NOT NULL, '
      'updated_at INTEGER NOT NULL, PRIMARY KEY (account_id, list_key))',
];

const List<String> _v2 = [
  ..._v1,
  'CREATE TABLE play_history (id INTEGER NOT NULL PRIMARY KEY '
      'AUTOINCREMENT, account_id TEXT NOT NULL, track_id TEXT NOT NULL, '
      'payload TEXT NOT NULL, started_at INTEGER NOT NULL, '
      'listened_ms INTEGER NOT NULL, duration_ms INTEGER NOT NULL, '
      'skipped INTEGER NOT NULL CHECK (skipped IN (0, 1)))',
  'CREATE TABLE downloads (account_id TEXT NOT NULL, '
      'track_id TEXT NOT NULL, payload TEXT NOT NULL, '
      'status TEXT NOT NULL, bytes INTEGER NOT NULL DEFAULT 0, '
      'total_bytes INTEGER NOT NULL DEFAULT 0, '
      'file_name TEXT NOT NULL, origins TEXT NOT NULL, '
      'created_at INTEGER NOT NULL, '
      'PRIMARY KEY (account_id, track_id))',
];

const List<String> _v3 = [
  ..._v2,
  'ALTER TABLE play_history ADD COLUMN latitude REAL',
  'ALTER TABLE play_history ADD COLUMN longitude REAL',
  'ALTER TABLE play_history ADD COLUMN place TEXT',
];

/// Table name → column names, as SQLite sees them.
Future<Map<String, Set<String>>> _columns(AppDatabase db) async {
  final tables = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      )
      .map((r) => r.read<String>('name'))
      .get();
  return {
    for (final t in tables)
      t:
          (await db
                  .customSelect('PRAGMA table_info($t)')
                  .map((r) => r.read<String>('name'))
                  .get())
              .toSet(),
  };
}

AppDatabase _old(int version, List<String> statements) => AppDatabase(
  NativeDatabase.memory(
    setup: (raw) {
      statements.forEach(raw.execute);
      raw.execute('PRAGMA user_version = $version');
    },
  ),
);

void main() {
  test(
    'every old version migrates to the same tables as a new install',
    () async {
      final fresh = AppDatabase(NativeDatabase.memory());
      addTearDown(fresh.close);
      final want = await _columns(fresh);
      expect(fresh.schemaVersion, 4, reason: 'add the new version here');

      for (final (version, statements) in [(1, _v1), (2, _v2), (3, _v3)]) {
        final db = _old(version, statements);
        addTearDown(db.close);
        expect(await _columns(db), want, reason: 'from version $version');
        final userVersion = await db
            .customSelect('PRAGMA user_version')
            .map((r) => r.read<int>('user_version'))
            .getSingle();
        expect(userVersion, fresh.schemaVersion);
      }
    },
  );
}
