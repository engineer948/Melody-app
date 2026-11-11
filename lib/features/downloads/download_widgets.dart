import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/data/downloads/download_models.dart';
import 'package:melody/data/downloads/download_settings.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/downloads/download_controller.dart';
import 'package:melody/l10n/l10n.dart';

/// How far a group of tracks is downloaded.
enum _GroupState { none, partial, busy, done }

_GroupState _groupState(
  Map<String, DownloadItem> downloads,
  List<Track> tracks,
) {
  var done = 0;
  var busy = 0;
  for (final t in tracks) {
    final item = downloads[t.id];
    if (item == null) continue;
    if (item.isDone) {
      done++;
    } else if (item.status == DownloadStatus.queued ||
        item.status == DownloadStatus.running) {
      busy++;
    }
  }
  if (busy > 0) return _GroupState.busy;
  if (tracks.isNotEmpty && done == tracks.length) return _GroupState.done;
  return done > 0 ? _GroupState.partial : _GroupState.none;
}

/// App bar button that downloads [tracks] (an album or a playlist), shows
/// progress, and offers to delete them once they are all there.
///
/// With [playlistId] the playlist is kept in sync instead: songs added to
/// it later are downloaded too and removed ones are deleted.
class DownloadButton extends ConsumerWidget {
  /// Creates the button.
  const DownloadButton({required this.tracks, this.playlistId, super.key});

  /// Tracks of the album or playlist.
  final List<Track> tracks;

  /// Set for playlists that should stay in sync.
  final String? playlistId;

  String? _syncKey(WidgetRef ref) {
    final accountId = ref.read(sessionControllerProvider).activeId;
    final id = playlistId;
    return accountId == null || id == null
        ? null
        : DownloadSettings.playlistKey(accountId, id);
  }

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final key = _syncKey(ref);
    if (key != null) {
      await ref
          .read(downloadSettingsControllerProvider.notifier)
          .update(
            (s) => s.copyWith(syncedPlaylists: {...s.syncedPlaylists, key}),
          );
    } else {
      await ref.read(downloadControllerProvider.notifier).enqueue(tracks);
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.downloadStarted(tracks.length))),
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.downloadRemoveConfirm(tracks.length)),
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
    final key = _syncKey(ref);
    if (key != null) {
      await ref
          .read(downloadSettingsControllerProvider.notifier)
          .update(
            (s) => s.copyWith(
              syncedPlaylists: {...s.syncedPlaylists}..remove(key),
            ),
          );
    } else {
      await ref.read(downloadControllerProvider.notifier).remove([
        for (final t in tracks) t.id,
      ]);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final group = ref.watch(
      downloadControllerProvider.select((d) => _groupState(d, tracks)),
    );
    final synced = ref.watch(
      downloadSettingsControllerProvider.select(
        (s) => s.syncedPlaylists.contains(_syncKey(ref)),
      ),
    );
    final kept = group == _GroupState.done || synced;
    return IconButton(
      tooltip: kept
          ? l10n.downloadRemove
          : playlistId == null
          ? l10n.download
          : l10n.downloadKeepSynced,
      onPressed: tracks.isEmpty
          ? null
          : () => unawaited(
              kept ? _remove(context, ref) : _download(context, ref),
            ),
      icon: switch (group) {
        _GroupState.busy => const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        _GroupState.done => Icon(
          Icons.download_done_rounded,
          color: scheme.primary,
        ),
        _ => Icon(
          synced ? Icons.sync_rounded : Icons.download_outlined,
          color: synced ? scheme.primary : null,
        ),
      },
    );
  }
}

/// Small mark shown next to a track that is available offline.
class DownloadedBadge extends ConsumerWidget {
  /// Creates the badge for [trackId].
  const DownloadedBadge({required this.trackId, super.key});

  /// Track to look up.
  final String trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(
      downloadControllerProvider.select((d) => d[trackId]?.isDone ?? false),
    );
    if (!done) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Icon(
        Icons.download_done_rounded,
        size: 16,
        color: Theme.of(context).colorScheme.primary,
        semanticLabel: context.l10n.downloaded,
      ),
    );
  }
}
