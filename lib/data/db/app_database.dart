import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Saved sign-ins; access tokens live in secure storage instead.
class Accounts extends Table {
  /// Account id.
  TextColumn get id => text()();

  /// JSON of the account.
  TextColumn get payload => text()();

  /// Creation time, used for ordering.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Library items cached per account.
class CachedItems extends Table {
  /// Owning account.
  TextColumn get accountId => text()();

  /// Item kind, e.g. `album`.
  TextColumn get kind => text()();

  /// Item id on the source.
  TextColumn get itemId => text()();

  /// Lower-cased name for offline search.
  TextColumn get name => text()();

  /// JSON of the domain model.
  TextColumn get payload => text()();

  /// Last refresh.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {accountId, kind, itemId};
}

/// Ordered id lists of cached listings.
class CachedLists extends Table {
  /// Owning account.
  TextColumn get accountId => text()();

  /// Listing key, e.g. `albums:name::`.
  TextColumn get listKey => text()();

  /// JSON array of item ids.
  TextColumn get itemIds => text()();

  /// Last refresh.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {accountId, listKey};
}

/// Local SQLite database.
@DriftDatabase(tables: [Accounts, CachedItems, CachedLists])
class AppDatabase extends _$AppDatabase {
  /// Opens the database, by default the on-device file.
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'melody'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX IF NOT EXISTS cached_items_name '
        'ON cached_items (account_id, kind, name)',
      );
    },
  );
}
