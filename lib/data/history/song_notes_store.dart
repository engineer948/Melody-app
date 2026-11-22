import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:melody/data/db/app_database.dart';
import 'package:melody/domain/models/media.dart';
import 'package:meta/meta.dart';

/// A memory written for a song.
@immutable
class SongNote {
  /// Creates a memory.
  const SongNote({
    required this.track,
    required this.body,
    required this.updatedAt,
    this.person,
    this.photo,
  });

  /// The song.
  final Track track;

  /// The words (may be empty).
  final String body;

  /// Who the song is about.
  final String? person;

  /// File name of the photo in the memories folder.
  final String? photo;

  /// When it was last written.
  final DateTime updatedAt;

  /// Whether there is nothing in it.
  bool get isEmpty =>
      body.trim().isEmpty && (person ?? '').trim().isEmpty && photo == null;
}

/// Song memories of every account, on the device only.
class SongNotesStore {
  /// Creates a store on top of [_db].
  SongNotesStore(this._db);

  final AppDatabase _db;

  /// The memory of [trackId], if any.
  Future<SongNote?> get(String accountId, String trackId) async {
    final row =
        await (_db.select(_db.songNotes)..where(
              (t) => t.accountId.equals(accountId) & t.trackId.equals(trackId),
            ))
            .getSingleOrNull();
    return row == null ? null : _note(row);
  }

  /// Every memory of [accountId], newest first.
  Future<List<SongNote>> all(String accountId) async {
    final rows =
        await (_db.select(_db.songNotes)
              ..where((t) => t.accountId.equals(accountId))
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.updatedAt,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();
    return [for (final row in rows) ?_note(row)];
  }

  /// Saves [note], replacing the memory of the same song; an empty note
  /// removes it.
  Future<void> put(String accountId, SongNote note) async {
    if (note.isEmpty) {
      await remove(accountId, note.track.id);
      return;
    }
    final person = note.person?.trim();
    await _db
        .into(_db.songNotes)
        .insertOnConflictUpdate(
          SongNotesCompanion.insert(
            accountId: accountId,
            trackId: note.track.id,
            payload: jsonEncode(note.track.toJson()),
            body: note.body.trim(),
            person: Value(person == null || person.isEmpty ? null : person),
            photo: Value(note.photo),
            updatedAt: note.updatedAt,
          ),
        );
  }

  /// Removes the memory of [trackId].
  Future<void> remove(String accountId, String trackId) =>
      (_db.delete(_db.songNotes)..where(
            (t) => t.accountId.equals(accountId) & t.trackId.equals(trackId),
          ))
          .go();

  SongNote? _note(SongNoteRow row) {
    try {
      return SongNote(
        track: Track.fromJson(jsonDecode(row.payload) as Map<String, dynamic>),
        body: row.body,
        person: row.person,
        photo: row.photo,
        updatedAt: row.updatedAt,
      );
    } on Object {
      return null;
    }
  }
}

/// People named in [notes] with how many songs are about each, most first.
List<(String, int)> notePeople(List<SongNote> notes) {
  final counts = <String, int>{};
  final names = <String, String>{};
  for (final n in notes) {
    final person = n.person?.trim();
    if (person == null || person.isEmpty) continue;
    final key = person.toLowerCase();
    names.putIfAbsent(key, () => person);
    counts[key] = (counts[key] ?? 0) + 1;
  }
  final keys = counts.keys.toList()
    ..sort((a, b) {
      final c = counts[b]!.compareTo(counts[a]!);
      return c != 0 ? c : a.compareTo(b);
    });
  return [for (final k in keys) (names[k]!, counts[k]!)];
}
