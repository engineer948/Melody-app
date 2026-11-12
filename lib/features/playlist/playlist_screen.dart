import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/core/theme/artwork_palette.dart';
import 'package:melody/core/widgets/artwork_image.dart';
import 'package:melody/core/widgets/failure_view.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/downloads/download_widgets.dart';
import 'package:melody/features/library/collection_actions.dart';
import 'package:melody/features/library/library_providers.dart';
import 'package:melody/features/library/widgets/media_tiles.dart';
import 'package:melody/features/library/widgets/paged_scroll_view.dart';
import 'package:melody/features/player/track_actions.dart';
import 'package:melody/l10n/l10n.dart';

/// Tracks of one playlist; can be renamed, reordered, trimmed and deleted.
class PlaylistScreen extends ConsumerStatefulWidget {
  /// Creates the page of playlist [id].
  const PlaylistScreen({required this.id, required this.name, super.key});

  /// Playlist id.
  final String id;

  /// Playlist name.
  final String name;

  @override
  ConsumerState<PlaylistScreen> createState() => _PlaylistScreenState();
}

enum _Action { rename, edit, delete }

class _PlaylistScreenState extends ConsumerState<PlaylistScreen> {
  late String _name = widget.name;
  bool _editing = false;

  TrackQuery get _query =>
      TrackQuery(sort: TrackSort.natural, playlistId: widget.id, limit: 500);

  MusicSource? get _source => ref.read(activeSourceProvider);

  void _reload() => ref
    ..invalidate(trackListProvider(_query))
    ..invalidate(playlistsProvider);

  Future<void> _run(
    Future<Result<Object?>> Function(MusicSource s) action,
  ) async {
    final source = _source;
    if (source == null) return;
    final failure = (await action(source)).failureOrNull;
    if (!mounted) return;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failureMessage(context.l10n, failure))),
      );
    }
    _reload();
  }

  Future<void> _onAction(_Action action) async {
    final l10n = context.l10n;
    switch (action) {
      case _Action.rename:
        final name = await askPlaylistName(
          context,
          title: l10n.playlistRename,
          action: l10n.save,
          initial: _name,
        );
        if (name == null) return;
        setState(() => _name = name);
        await _run((s) => s.renamePlaylist(widget.id, name));
      case _Action.edit:
        setState(() => _editing = true);
      case _Action.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.playlistDelete),
            content: Text(l10n.playlistDeleteConfirm(_name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.delete),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
        await _run((s) => s.deletePlaylist(widget.id));
        if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(trackListProvider(_query));
    final editable =
        ref.watch(activeSourceProvider)?.capabilities.editablePlaylists ??
        false;
    if (_editing) {
      return _EditView(
        name: _name,
        tracks: state.items,
        onDone: () => setState(() => _editing = false),
        onRemove: (track) => _run(
          (s) => s.removeFromPlaylist(widget.id, [?track.playlistItemId]),
        ),
        onMove: (track, to) => _run(
          (s) => s.movePlaylistItem(widget.id, track.playlistItemId ?? '', to),
        ),
      );
    }
    return Scaffold(
      body: PagedScrollView<Track>(
        title: _name,
        colors: ref
            .watch(
              artworkPaletteProvider(
                state.items
                    .where((t) => t.artwork != null)
                    .firstOrNull
                    ?.artwork,
              ),
            )
            .value
            ?.colors,
        state: state,
        emptyIcon: Icons.queue_music_outlined,
        onRefresh: _reload,
        onLoadMore: () =>
            ref.read(trackListProvider(_query).notifier).loadMore(),
        actions: [
          if (state.items.isNotEmpty)
            DownloadButton(tracks: state.items, playlistId: widget.id),
          if (editable)
            PopupMenuButton<_Action>(
              tooltip: l10n.moreOptions,
              onSelected: (a) => unawaited(_onAction(a)),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _Action.rename,
                  child: Text(l10n.playlistRename),
                ),
                if (state.items.isNotEmpty)
                  PopupMenuItem(
                    value: _Action.edit,
                    child: Text(l10n.playlistEdit),
                  ),
                PopupMenuItem(
                  value: _Action.delete,
                  child: Text(l10n.playlistDelete),
                ),
              ],
            ),
        ],
        headers: [
          if (state.items.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(child: MosaicCover(tracks: state.items)),
              ),
            ),
            SliverToBoxAdapter(child: PlayShuffleButtons(tracks: state.items)),
          ],
        ],
        sliverBuilder: (tracks) => TrackSliverList(tracks: tracks),
      ),
    );
  }
}

/// Cover made of the first four different album covers of [tracks].
class MosaicCover extends StatelessWidget {
  /// Creates the cover.
  const MosaicCover({required this.tracks, this.size = 200, super.key});

  /// Tracks to take covers from.
  final List<Track> tracks;

  /// Edge length.
  final double size;

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final art = <Artwork>[
      for (final t in tracks)
        if (t.artwork case final a? when seen.add(a.itemId)) a,
    ].take(4).toList();
    if (art.length < 4) {
      return CoverArt(
        artwork: art.firstOrNull,
        size: size,
        icon: Icons.queue_music_outlined,
      );
    }
    final half = size / 2;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox.square(
          dimension: size,
          child: Wrap(
            children: [
              for (final a in art)
                ArtworkImage(artwork: a, size: half, radius: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditView extends StatefulWidget {
  const _EditView({
    required this.name,
    required this.tracks,
    required this.onDone,
    required this.onRemove,
    required this.onMove,
  });

  final String name;
  final List<Track> tracks;
  final VoidCallback onDone;
  final Future<void> Function(Track track) onRemove;
  final Future<void> Function(Track track, int newIndex) onMove;

  @override
  State<_EditView> createState() => _EditViewState();
}

class _EditViewState extends State<_EditView> {
  late final List<Track> _tracks = [...widget.tracks];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(onPressed: widget.onDone, child: Text(l10n.playlistDone)),
        ],
      ),
      body: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 16,
        ),
        itemCount: _tracks.length,
        onReorderItem: (from, to) {
          final track = _tracks[from];
          setState(() => _tracks.insert(to, _tracks.removeAt(from)));
          unawaited(widget.onMove(track, to));
        },
        itemBuilder: (context, i) {
          final track = _tracks[i];
          return ListTile(
            key: ValueKey(track.playlistItemId ?? '${track.id}#$i'),
            leading: IconButton(
              tooltip: l10n.removeFromPlaylist,
              icon: Icon(
                Icons.remove_circle,
                color: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                setState(() => _tracks.removeAt(i));
                unawaited(widget.onRemove(track));
              },
            ),
            title: Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              track.artistLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: ReorderableDragStartListener(
              index: i,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.drag_handle),
              ),
            ),
          );
        },
      ),
    );
  }
}
