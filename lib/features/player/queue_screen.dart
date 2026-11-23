import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/widgets/artwork_image.dart';
import 'package:melody/core/widgets/empty_state.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/library/collection_actions.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/player_controller.dart';

/// The queue: drag to reorder, swipe to remove, tap to jump.
class QueueScreen extends ConsumerWidget {
  /// Creates the screen.
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = ref.watch(playerControllerProvider);
    final player = ref.read(playerControllerProvider.notifier);
    final queue = state.queue;
    final upcoming = queue.length - queue.index - 1;
    final editable =
        ref.watch(activeSourceProvider)?.capabilities.editablePlaylists ??
        false;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.queue),
        actions: [
          if (!queue.isEmpty && editable)
            IconButton(
              tooltip: l10n.queueSaveAsPlaylist,
              icon: const Icon(Icons.playlist_add),
              onPressed: () =>
                  createPlaylist(context, ref, tracks: queue.tracks),
            ),
          if (upcoming > 0)
            TextButton(
              onPressed: player.clearUpcoming,
              child: Text(l10n.queueClear),
            ),
        ],
      ),
      body: queue.isEmpty
          ? EmptyState(icon: Icons.queue_music_outlined, title: l10n.queueEmpty)
          : ReorderableListView.builder(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 16,
              ),
              buildDefaultDragHandles: false,
              itemCount: queue.length,
              onReorderItem: (from, to) => unawaited(player.move(from, to)),
              itemBuilder: (context, index) {
                final entry = queue.entries[index];
                final track = entry.track;
                final isCurrent = index == queue.index;
                final played = index < queue.index;
                return Dismissible(
                  key: ValueKey(entry.uid),
                  direction: isCurrent
                      ? DismissDirection.none
                      : DismissDirection.endToStart,
                  background: ColoredBox(
                    color: theme.colorScheme.error,
                    child: const Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Padding(
                        padding: EdgeInsets.only(right: 24),
                        child: Icon(Icons.delete_outline, color: Colors.white),
                      ),
                    ),
                  ),
                  onDismissed: (_) {
                    unawaited(player.removeAt(index));
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l10n.queueRemoved)));
                  },
                  child: Opacity(
                    opacity: played ? 0.5 : 1,
                    child: ListTile(
                      leading: ArtworkImage(
                        artwork: track.artwork,
                        size: 44,
                        radius: 6,
                        icon: Icons.music_note_outlined,
                      ),
                      title: Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: isCurrent
                            ? TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              )
                            : null,
                      ),
                      subtitle: Text(
                        track.artistLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.drag_handle),
                        ),
                      ),
                      onTap: () => player.skipTo(index),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
