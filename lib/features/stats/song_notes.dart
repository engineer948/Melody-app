import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/core/widgets/artwork_image.dart';
import 'package:melody/core/widgets/shelf_header.dart';
import 'package:melody/data/history/song_notes_store.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/history_recorder.dart';
import 'package:melody/player/listening_settings.dart';
import 'package:melody/player/player_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'song_notes.g.dart';

/// The song memories of every account.
@Riverpod(keepAlive: true)
SongNotesStore songNotesStore(Ref ref) =>
    SongNotesStore(ref.watch(appDatabaseProvider));

/// Folder of the photos added to memories.
@Riverpod(keepAlive: true)
Future<Directory> memoriesDir(Ref ref) async {
  final base = await getApplicationSupportDirectory();
  return Directory('${base.path}/memories');
}

/// Memories of the active account, newest first.
@riverpod
class SongNotes extends _$SongNotes {
  @override
  Future<List<SongNote>> build() async {
    final accountId = ref.watch(
      sessionControllerProvider.select((s) => s.activeId),
    );
    if (accountId == null) return const [];
    return await ref.watch(songNotesStoreProvider).all(accountId);
  }

  String? get _accountId => ref.read(sessionControllerProvider).activeId;

  /// Saves [note] (an empty one is removed).
  Future<void> save(SongNote note) async {
    final accountId = _accountId;
    if (accountId == null) return;
    await ref.read(songNotesStoreProvider).put(accountId, note);
    ref.invalidateSelf();
    await future;
  }

  /// Removes the memory of [track] and its photo.
  Future<void> remove(Track track) async {
    final accountId = _accountId;
    if (accountId == null) return;
    final old = await ref.read(songNotesStoreProvider).get(accountId, track.id);
    await ref.read(songNotesStoreProvider).remove(accountId, track.id);
    if (old?.photo case final photo?) await _deletePhoto(photo);
    ref.invalidateSelf();
    await future;
  }

  Future<void> _deletePhoto(String name) async {
    try {
      final dir = await ref.read(memoriesDirProvider.future);
      await File('${dir.path}/$name').delete();
    } on Object {
      // Already gone.
    }
  }
}

/// The memory of [trackId], if any.
@riverpod
SongNote? songNote(Ref ref, String trackId) {
  final notes = ref.watch(songNotesProvider).value ?? const [];
  return notes.where((n) => n.track.id == trackId).firstOrNull;
}

/// How often [trackId] was played today.
@riverpod
Future<int> playsToday(Ref ref, String trackId) async {
  ref.watch(historyRevisionProvider);
  final accountId = ref.watch(
    sessionControllerProvider.select((s) => s.activeId),
  );
  if (accountId == null) return 0;
  final now = DateTime.now();
  return await ref
      .watch(historyStoreProvider)
      .playsSince(accountId, trackId, DateTime(now.year, now.month, now.day));
}

/// Plays in one day after which the player offers to write a memory.
const replayMomentPlays = 5;

/// Preference prefix: songs already offered a memory after many replays.
const replayAskedKey = 'life.replayAsked.';

/// Opens the editor of the memory of [track].
Future<void> showSongNoteEditor(BuildContext context, Track track) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      // Above the bottom bar, so "Save" is never hidden under it.
      useRootNavigator: true,
      builder: (context) => _NoteEditor(track: track),
    );

class _NoteEditor extends ConsumerStatefulWidget {
  const _NoteEditor({required this.track});

  final Track track;

  @override
  ConsumerState<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<_NoteEditor> {
  late final SongNote? _old = ref.read(songNoteProvider(widget.track.id));
  late final _body = TextEditingController(text: _old?.body);
  late final _person = TextEditingController(text: _old?.person);
  late String? _photo = _old?.photo;
  // Photos picked in this editor, deleted again when not kept.
  final _picked = <String>{};
  var _saved = false;

  @override
  void dispose() {
    _body.dispose();
    _person.dispose();
    if (!_saved) unawaited(_forget(_picked));
    super.dispose();
  }

  Future<void> _forget(Iterable<String> names) async {
    if (names.isEmpty) return;
    final dir = await ref.read(memoriesDirProvider.future);
    for (final name in names) {
      try {
        await File('${dir.path}/$name').delete();
      } on Object {
        // Already gone.
      }
    }
  }

  Future<void> _pickPhoto() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'images',
          extensions: ['png', 'jpg', 'jpeg', 'webp', 'heic'],
          mimeTypes: ['image/*'],
          uniformTypeIdentifiers: ['public.image'],
        ),
      ],
    );
    if (file == null) return;
    final dir = await ref.read(memoriesDirProvider.future);
    await dir.create(recursive: true);
    final dot = file.name.lastIndexOf('.');
    final ext = dot < 0 ? '.jpg' : file.name.substring(dot).toLowerCase();
    final name =
        '${DateTime.now().microsecondsSinceEpoch}'
        '${Random().nextInt(1 << 20)}$ext';
    await File('${dir.path}/$name').writeAsBytes(await file.readAsBytes());
    _picked.add(name);
    setState(() => _photo = name);
  }

  Future<void> _save() async {
    final notes = ref.read(songNotesProvider.notifier);
    final navigator = Navigator.of(context);
    _saved = true;
    await notes.save(
      SongNote(
        track: widget.track,
        body: _body.text,
        person: _person.text,
        photo: _photo,
        updatedAt: DateTime.now(),
      ),
    );
    // Photos replaced or removed while editing.
    await _forget({
      ..._picked.where((p) => p != _photo),
      if (_old?.photo case final old? when old != _photo) old,
    });
    if (mounted) navigator.pop();
  }

  Future<void> _delete() async {
    final notes = ref.read(songNotesProvider.notifier);
    final navigator = Navigator.of(context);
    await notes.remove(widget.track);
    if (mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final people = notePeople(ref.watch(songNotesProvider).value ?? const []);
    final dir = ref.watch(memoriesDirProvider).value;
    final photo = _photo;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.track.title, style: theme.textTheme.titleLarge),
            Text(
              widget.track.artistLine,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _body,
              autofocus: _old == null,
              minLines: 3,
              maxLines: 8,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.noteHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _person,
              maxLength: 40,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.notePerson,
                helperText: l10n.notePersonHelp,
                prefixIcon: const Icon(Icons.favorite_border_rounded),
                border: const OutlineInputBorder(),
              ),
            ),
            if (people.isNotEmpty)
              Wrap(
                spacing: 8,
                children: [
                  for (final (name, _) in people.take(8))
                    ActionChip(
                      label: Text(name),
                      onPressed: () => setState(() => _person.text = name),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            if (photo != null && dir != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File('${dir.path}/$photo'),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton.filledTonal(
                      tooltip: l10n.noteRemovePhoto,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() => _photo = null),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: () => unawaited(_pickPhoto()),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(l10n.notePhoto),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_old != null)
                  TextButton.icon(
                    onPressed: () => unawaited(_delete()),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.delete),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: () => unawaited(_save()),
                  child: Text(l10n.save),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.notePrivate,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The memory of [track] inside "This song's story", or a button to write
/// one.
class SongNoteSection extends ConsumerWidget {
  /// Creates the section.
  const SongNoteSection({required this.track, super.key});

  /// The song.
  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final note = ref.watch(songNoteProvider(track.id));
    if (note == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: FilledButton.tonalIcon(
          onPressed: () => unawaited(showSongNoteEditor(context, track)),
          icon: const Icon(Icons.edit_note_rounded),
          label: Text(l10n.noteAdd),
        ),
      );
    }
    return NoteCard(
      note: note,
      onTap: () => unawaited(showSongNoteEditor(context, track)),
    );
  }
}

/// A memory as a card: photo, who it is about and the words.
class NoteCard extends ConsumerWidget {
  /// Creates the card.
  const NoteCard({required this.note, this.onTap, super.key});

  /// The memory.
  final SongNote note;

  /// Called when tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dir = ref.watch(memoriesDirProvider).value;
    final photo = note.photo;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (photo != null && dir != null)
              Image.file(
                File('${dir.path}/$photo'),
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (note.person case final person?)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '♥ $person',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  if (note.body.isNotEmpty)
                    Text(
                      note.body,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A line under the song in the full player: its memory, or after many
/// plays today, an offer to write one. `null` when there is nothing.
Widget? noteLine(BuildContext context, WidgetRef ref, Track track) {
  final l10n = context.l10n;
  final note = ref.watch(songNoteProvider(track.id));
  if (note != null) {
    final text = note.body.isNotEmpty ? note.body : '♥ ${note.person ?? ''}';
    return _PlayerLine(
      icon: Icons.format_quote_rounded,
      text: text,
      onTap: () => unawaited(showSongNoteEditor(context, track)),
    );
  }
  final settings = ref.watch(listeningSettingsControllerProvider);
  if (!settings.lifeShelf) return null;
  final prefs = ref.watch(preferencesProvider);
  if (prefs.getBool('$replayAskedKey${track.id}') ?? false) return null;
  final plays = ref.watch(playsTodayProvider(track.id)).value ?? 0;
  // The current play is recorded when it ends: count it already.
  if (plays + 1 < replayMomentPlays) return null;
  return _PlayerLine(
    icon: Icons.edit_note_rounded,
    text: l10n.noteReplay(plays + 1),
    onTap: () {
      unawaited(prefs.setBool('$replayAskedKey${track.id}', true));
      unawaited(showSongNoteEditor(context, track));
    },
  );
}

class _PlayerLine extends StatelessWidget {
  const _PlayerLine({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}

/// "Memories" on the soundtrack screen: people the songs are about, then
/// the memories themselves.
class MemoriesShelf extends ConsumerWidget {
  /// Creates the shelf.
  const MemoriesShelf({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notes = ref.watch(songNotesProvider).value ?? const [];
    if (notes.isEmpty) return const SizedBox.shrink();
    final people = notePeople(notes);
    final player = ref.read(playerControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShelfHeader(l10n.noteMemories),
        if (people.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final (name, count) in people)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.favorite_rounded, size: 18),
                      label: Text('$name · $count'),
                      tooltip: l10n.notePlayPerson(name),
                      onPressed: () => unawaited(
                        player.playTracks([
                          for (final n in notes)
                            if (n.person?.toLowerCase() == name.toLowerCase())
                              n.track,
                        ], shuffle: true),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        SizedBox(
          height: 150,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final note in notes.take(30)) _MemoryTile(note: note),
            ],
          ),
        ),
      ],
    );
  }
}

class _MemoryTile extends ConsumerWidget {
  const _MemoryTile({required this.note});

  final SongNote note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dir = ref.watch(memoriesDirProvider).value;
    final photo = note.photo;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => unawaited(showSongNoteEditor(context, note.track)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photo != null && dir != null)
                  Image.file(
                    File('${dir.path}/$photo'),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        ArtworkImage(artwork: note.track.artwork, radius: 0),
                  )
                else
                  ArtworkImage(artwork: note.track.artwork, radius: 0),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x22000000), Color(0xDD000000)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(color: Colors.white),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (note.person case final person?)
                          Text(
                            '♥ $person',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        const Spacer(),
                        if (note.body.isNotEmpty)
                          Text(
                            '“${note.body}”',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 13,
                            ),
                          ),
                        Text(
                          '♪ ${note.track.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
