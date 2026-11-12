import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/widgets/artwork_image.dart';
import 'package:melody/core/widgets/empty_state.dart';
import 'package:melody/core/widgets/large_title_page.dart';
import 'package:melody/data/downloads/download_models.dart';
import 'package:melody/data/downloads/download_settings.dart';
import 'package:melody/features/downloads/download_controller.dart';
import 'package:melody/features/library/widgets/media_tiles.dart';
import 'package:melody/features/player/track_actions.dart';
import 'package:melody/features/settings/widgets/media_sections.dart';
import 'package:melody/l10n/l10n.dart';

/// Songs available offline, and downloads in progress.
class DownloadsPage extends ConsumerWidget {
  /// Creates the page.
  const DownloadsPage({super.key});

  Future<void> _removeAll(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.downloadRemoveAllConfirm),
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
    if (confirmed != true) return;
    // Otherwise the next sync would fetch them again.
    await ref
        .read(downloadSettingsControllerProvider.notifier)
        .update(
          (s) => s.copyWith(autoFavorites: false, syncedPlaylists: const {}),
        );
    await ref.read(downloadControllerProvider.notifier).remove();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final downloads = ref.watch(downloadControllerProvider);
    final controller = ref.read(downloadControllerProvider.notifier);
    final done = [
      for (final d in downloads.values)
        if (d.isDone) d,
    ];
    final pending = [
      for (final d in downloads.values)
        if (!d.isDone) d,
    ];
    final tracks = [for (final d in done) d.track];
    final bytes = done.fold(0, (sum, d) => sum + d.bytes);
    final anyActive = pending.any(
      (d) =>
          d.status == DownloadStatus.queued ||
          d.status == DownloadStatus.running,
    );
    return Scaffold(
      body: LargeTitlePage(
        title: l10n.libraryDownloads,
        actions: [
          if (downloads.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: l10n.downloadRemoveAll,
              onPressed: () => unawaited(_removeAll(context, ref)),
            ),
        ],
        slivers: [
          if (downloads.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.download_for_offline_outlined,
                title: l10n.downloadsEmptyTitle,
                message: l10n.downloadsEmptyBody,
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  l10n.downloadsSummary(done.length, formatBytes(l10n, bytes)),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            if (pending.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: ListTile(
                  title: Text(
                    l10n.downloadsPending(pending.length),
                    style: theme.textTheme.titleMedium,
                  ),
                  trailing: TextButton(
                    onPressed: anyActive
                        ? controller.pauseAll
                        : () => unawaited(controller.resumeAll()),
                    child: Text(
                      anyActive
                          ? l10n.downloadPauseAll
                          : l10n.downloadResumeAll,
                    ),
                  ),
                ),
              ),
              SliverList.builder(
                itemCount: pending.length,
                itemBuilder: (context, index) =>
                    _PendingTile(item: pending[index]),
              ),
              const SliverToBoxAdapter(child: Divider()),
            ],
            if (tracks.isNotEmpty)
              SliverToBoxAdapter(child: PlayShuffleButtons(tracks: tracks)),
            TrackSliverList(tracks: tracks),
          ],
        ],
      ),
    );
  }
}

class _PendingTile extends ConsumerWidget {
  const _PendingTile({required this.item});

  final DownloadItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(downloadControllerProvider.notifier);
    final id = item.track.id;
    final (label, icon, tooltip, action) = switch (item.status) {
      DownloadStatus.running || DownloadStatus.queued => (
        item.status == DownloadStatus.running
            ? l10n.downloadRunning
            : l10n.downloadQueued,
        Icons.pause_rounded,
        l10n.downloadPause,
        () => controller.pause(id),
      ),
      DownloadStatus.failed => (
        l10n.downloadFailed,
        Icons.refresh_rounded,
        l10n.retry,
        () => unawaited(controller.resume(id)),
      ),
      _ => (
        l10n.downloadPaused,
        Icons.play_arrow_rounded,
        l10n.downloadResume,
        () => unawaited(controller.resume(id)),
      ),
    };
    return ListTile(
      leading: ArtworkImage(
        artwork: item.track.artwork,
        size: 48,
        radius: 6,
        icon: Icons.music_note_outlined,
      ),
      title: Text(
        item.track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (item.status == DownloadStatus.running) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(value: item.progress),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: Icon(icon), tooltip: tooltip, onPressed: action),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: l10n.downloadRemove,
            onPressed: () => unawaited(controller.remove([id])),
          ),
        ],
      ),
    );
  }
}
