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

/// One play of a track, kept on the device only (statistics, suggestions).
class PlayHistory extends Table {
  /// Row id.
  IntColumn get id => integer().autoIncrement()();

  /// Owning account.
  TextColumn get accountId => text()();

  /// Track played.
  TextColumn get trackId => text()();

  /// JSON of the track as it was when played.
  TextColumn get payload => text()();

  /// When playback of the track began.
  DateTimeColumn get startedAt => dateTime()();

  /// Time actually listened, in milliseconds.
  IntColumn get listenedMs => integer()();

  /// Length of the track in milliseconds; 0 when unknown.
  IntColumn get durationMs => integer()();

  /// Whether the track was left early.
  BoolColumn get skipped => boolean()();
}

/// Tracks saved for offline playback.
class Downloads extends Table {
  /// Owning account.
  TextColumn get accountId => text()();

  /// Track id on the source.
  TextColumn get trackId => text()();

  /// JSON of the track.
  TextColumn get payload => text()();

  /// `queued`, `running`, `paused`, `done` or `failed`.
  TextColumn get status => text()();

  /// Bytes on disk so far.
  IntColumn get bytes => integer().withDefault(const Constant(0))();

  /// Expected size; 0 when the server did not say.
  IntColumn get totalBytes => integer().withDefault(const Constant(0))();

  /// File name inside the download folder.
  TextColumn get fileName => text()();

  /// JSON array of why it is kept: `manual`, `favorites`, `playlist:<id>`…
  TextColumn get origins => text()();

  /// When it was requested.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {accountId, trackId};
}

/// Local SQLite database.
@DriftDatabase(
  tables: [Accounts, CachedItems, CachedLists, PlayHistory, Downloads],
)
class AppDatabase extends _$AppDatabase {
  /// Opens the database, by default the on-device file.
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'melody'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX IF NOT EXISTS cached_items_name '
        'ON cached_items (account_id, kind, name)',
      );
      await _createHistoryIndex();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(playHistory);
        await m.createTable(downloads);
        await _createHistoryIndex();
      }
    },
  );

  Future<void> _createHistoryIndex() => customStatement(
    'CREATE INDEX IF NOT EXISTS play_history_time '
    'ON play_history (account_id, started_at)',
  );
}
