import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/core/widgets/empty_state.dart';
import 'package:melody/core/widgets/large_title_page.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/playlists/smart_playlist.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/library/collection_actions.dart';
import 'package:melody/features/library/library_providers.dart';
import 'package:melody/features/library/track_selection.dart';
import 'package:melody/features/library/widgets/media_tiles.dart';
import 'package:melody/features/library/widgets/paged_scroll_view.dart';
import 'package:melody/features/player/track_actions.dart';
import 'package:melody/features/playlist/m3u_actions.dart';
import 'package:melody/features/playlist/playlist_screen.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'smart_playlists.g.dart';

/// Smart playlists of the active account, saved on this device.
@Riverpod(keepAlive: true)
class SmartPlaylists extends _$SmartPlaylists {
  String? get _key {
    final id = ref.read(sessionControllerProvider).activeId;
    return id == null ? null : 'smartPlaylists.$id';
  }

  @override
  List<SmartPlaylist> build() {
    ref.watch(sessionControllerProvider.select((s) => s.activeId));
    final key = _key;
    final raw = key == null
        ? null
        : ref.read(preferencesProvider).getString(key);
    if (raw == null) return const [];
    try {
      return [
        for (final item in jsonDecode(raw) as List<dynamic>)
          SmartPlaylist.fromJson(item as Map<String, dynamic>),
      ];
    } on Object {
      return const [];
    }
  }

  /// Adds [playlist], or replaces the one with the same id.
  Future<void> save(SmartPlaylist playlist) async {
    final exists = state.any((p) => p.id == playlist.id);
    state = [
      for (final p in state)
        if (p.id == playlist.id) playlist else p,
      if (!exists) playlist,
    ];
    await _store();
  }

  /// Removes the playlist [id].
  Future<void> delete(String id) async {
    state = [
      for (final p in state)
        if (p.id != id) p,
    ];
    await _store();
  }

  Future<void> _store() async {
    final key = _key;
    if (key == null) return;
    await ref.read(preferencesProvider).setString(key, jsonEncode(state));
  }

  /// A new, unused id.
  static String newId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);
}

/// The songs a smart playlist picks right now.
@riverpod
Future<List<Track>> smartPlaylistTracks(Ref ref, String id) async {
  final playlist = ref
      .watch(smartPlaylistsProvider)
      .where((p) => p.id == id)
      .firstOrNull;
  final source = ref.watch(activeSourceProvider);
  if (playlist == null) throw const NotFoundFailure();
  if (source == null) throw const UnauthorizedFailure();
  return switch (await playlist.resolve(source)) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
}

/// Opens the editor for a new smart playlist and its page after saving.
Future<void> createSmartPlaylist(BuildContext context, WidgetRef ref) async {
  final created = await editSmartPlaylist(
    context,
    SmartPlaylist(id: SmartPlaylists.newId(), name: ''),
  );
  if (created == null || !context.mounted) return;
  await ref.read(smartPlaylistsProvider.notifier).save(created);
  if (context.mounted) {
    unawaited(context.push(AppRoutes.smartPlaylist(context, created.id)));
  }
}

/// Shows the rules editor; returns the changed playlist, `null` if cancelled.
Future<SmartPlaylist?> editSmartPlaylist(
  BuildContext context,
  SmartPlaylist playlist,
) => Navigator.of(context, rootNavigator: true).push(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => SmartPlaylistEditor(initial: playlist),
  ),
);

/// Row of a smart playlist in the playlist list.
class SmartPlaylistTile extends StatelessWidget {
  /// Creates the tile.
  const SmartPlaylistTile({required this.playlist, super.key});

  /// Playlist to show.
  final SmartPlaylist playlist;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(Icons.auto_awesome, color: scheme.onPrimaryContainer),
      ),
      title: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        smartPlaylistSummary(context.l10n, playlist),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(AppRoutes.smartPlaylist(context, playlist.id)),
    );
  }
}

/// Name of [sort] for display.
String smartSortLabel(AppLocalizations l10n, SmartSort sort) => switch (sort) {
  SmartSort.recentlyAdded => l10n.smartSortRecentlyAdded,
  SmartSort.mostPlayed => l10n.smartSortMostPlayed,
  SmartSort.recentlyPlayed => l10n.smartSortRecentlyPlayed,
  SmartSort.random => l10n.smartSortRandom,
  SmartSort.title => l10n.smartSortTitle,
};

/// Short description of the rules of [p], e.g. "Random · Pop · 1990–1999".
String smartPlaylistSummary(AppLocalizations l10n, SmartPlaylist p) {
  final from = p.yearFrom;
  final to = p.yearTo;
  return [
    smartSortLabel(l10n, p.sort),
    if (p.favoritesOnly) l10n.libraryFavorites,
    if (p.unplayedOnly && !p.sort.needsPlays) l10n.smartUnplayed,
    ?p.genreName,
    if (from != null || to != null) '${from ?? '…'}–${to ?? '…'}',
    l10n.smartLimitSongs(p.limit),
  ].join(' · ');
}

/// Page of one smart playlist.
class SmartPlaylistScreen extends ConsumerWidget {
  /// Creates the page of smart playlist [id].
  const SmartPlaylistScreen({required this.id, super.key});

  /// Smart playlist id.
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final playlist = ref
        .watch(smartPlaylistsProvider)
        .where((p) => p.id == id)
        .firstOrNull;
    final provider = smartPlaylistTracksProvider(id);
    final value = ref.watch(provider);
    final tracks = value.value ?? const <Track>[];
    final editable =
        ref.watch(activeSourceProvider)?.capabilities.editablePlaylists ??
        false;
    if (playlist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.auto_awesome, title: l10n.emptyList),
      );
    }
    return Scaffold(
      body: TrackSelectionScope(
        tracks: tracks,
        child: LargeTitlePage(
          title: playlist.name,
          onRefresh: () async => ref.invalidate(provider),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: l10n.smartEdit,
              onPressed: () async {
                final changed = await editSmartPlaylist(context, playlist);
                if (changed != null) {
                  await ref.read(smartPlaylistsProvider.notifier).save(changed);
                }
              },
            ),
            PopupMenuButton<String>(
              tooltip: l10n.moreOptions,
              onSelected: (action) async {
                switch (action) {
                  case 'save':
                    await createPlaylist(context, ref, tracks: tracks);
                  case 'export':
                    await exportM3u(context, playlist.name, tracks);
                  case 'delete':
                    await ref
                        .read(smartPlaylistsProvider.notifier)
                        .delete(playlist.id);
                    if (context.mounted) context.pop();
                }
              },
              itemBuilder: (context) => [
                if (editable && tracks.isNotEmpty)
                  PopupMenuItem(value: 'save', child: Text(l10n.smartSaveCopy)),
                if (tracks.isNotEmpty)
                  PopupMenuItem(value: 'export', child: Text(l10n.m3uExport)),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(l10n.playlistDelete),
                ),
              ],
            ),
          ],
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  smartPlaylistSummary(l10n, playlist),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            ...loadedSlivers(
              value: value,
              onRetry: () => ref.invalidate(provider),
              builder: (tracks) => [
                if (tracks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.auto_awesome,
                      title: l10n.smartEmpty,
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: MosaicCover(tracks: tracks)),
                    ),
                  ),
                  SliverToBoxAdapter(child: PlayShuffleButtons(tracks: tracks)),
                  TrackSliverList(tracks: tracks),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Form for the name and rules of a smart playlist.
class SmartPlaylistEditor extends ConsumerStatefulWidget {
  /// Creates the editor starting from [initial].
  const SmartPlaylistEditor({required this.initial, super.key});

  /// Playlist being edited (an empty name means a new one).
  final SmartPlaylist initial;

  @override
  ConsumerState<SmartPlaylistEditor> createState() =>
      _SmartPlaylistEditorState();
}

class _SmartPlaylistEditorState extends ConsumerState<SmartPlaylistEditor> {
  late SmartPlaylist _p = widget.initial;
  late final _name = TextEditingController(text: widget.initial.name);
  late final _from = TextEditingController(
    text: widget.initial.yearFrom?.toString() ?? '',
  );
  late final _to = TextEditingController(
    text: widget.initial.yearTo?.toString() ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = context.l10n;
    final from = int.tryParse(_from.text.trim());
    final to = int.tryParse(_to.text.trim());
    var name = _name.text.trim();
    if (name.isEmpty) name = smartSortLabel(l10n, _p.sort);
    Navigator.pop(
      context,
      _p.copyWith(
        name: name,
        yearFrom: from,
        yearTo: to,
        clearYearFrom: from == null,
        clearYearTo: to == null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final genres = ref.watch(genresProvider).value?.value ?? const <Genre>[];
    final isNew = widget.initial.name.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? l10n.smartNew : l10n.smartEdit),
        actions: [TextButton(onPressed: _save, child: Text(l10n.save))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            autofocus: isNew,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.playlistName,
              hintText: smartSortLabel(l10n, _p.sort),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<SmartSort>(
            initialValue: _p.sort,
            decoration: InputDecoration(
              labelText: l10n.smartSort,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final s in SmartSort.values)
                DropdownMenuItem(
                  value: s,
                  child: Text(smartSortLabel(l10n, s)),
                ),
            ],
            onChanged: (s) => setState(() => _p = _p.copyWith(sort: s)),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            initialValue: genres.any((g) => g.id == _p.genreId)
                ? _p.genreId
                : null,
            decoration: InputDecoration(
              labelText: l10n.smartGenre,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(child: Text(l10n.smartAnyGenre)),
              for (final g in genres)
                DropdownMenuItem(value: g.id, child: Text(g.name)),
            ],
            onChanged: (id) => setState(() {
              final genre = genres.where((g) => g.id == id).firstOrNull;
              _p = genre == null
                  ? _p.copyWith(clearGenre: true)
                  : _p.copyWith(genreId: genre.id, genreName: genre.name);
            }),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _yearField(_from, l10n.smartYearFrom)),
              const SizedBox(width: 12),
              Expanded(child: _yearField(_to, l10n.smartYearTo)),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.smartFavoritesOnly),
            value: _p.favoritesOnly,
            onChanged: (v) =>
                setState(() => _p = _p.copyWith(favoritesOnly: v)),
          ),
          if (!_p.sort.needsPlays)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.smartUnplayedOnly),
              value: _p.unplayedOnly,
              onChanged: (v) =>
                  setState(() => _p = _p.copyWith(unplayedOnly: v)),
            ),
          const SizedBox(height: 8),
          Text(l10n.smartLimit, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final n in SmartPlaylist.limitChoices)
                ChoiceChip(
                  label: Text('$n'),
                  selected: _p.limit == n,
                  onSelected: (_) => setState(() => _p = _p.copyWith(limit: n)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.smartBody,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _yearField(TextEditingController controller, String label) =>
      TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        decoration: InputDecoration(
          labelText: label,
          hintText: label == context.l10n.smartYearFrom ? '1990' : '1999',
          border: const OutlineInputBorder(),
        ),
      );
}
