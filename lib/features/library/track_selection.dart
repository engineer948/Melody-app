import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/core/widgets/failure_view.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/downloads/download_controller.dart';
import 'package:melody/features/library/collection_actions.dart';
import 'package:melody/features/library/library_providers.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/player_controller.dart';

/// Songs picked on a page.
class TrackSelection extends ChangeNotifier {
  final _picked = <String, Track>{};

  /// Whether selection mode is on (at least one song picked).
  bool get active => _picked.isNotEmpty;

  /// Number of picked songs.
  int get count => _picked.length;

  /// Picked songs in the order of [page] (the songs shown), followed by
  /// picked songs no longer shown.
  List<Track> inOrder(List<Track> page) {
    final rest = Map.of(_picked);
    return [for (final t in page) ?rest.remove(_key(t)), ...rest.values];
  }

  /// Whether [track] is picked.
  bool contains(Track track) => _picked.containsKey(_key(track));

  /// Picks or unpicks [track].
  void toggle(Track track) {
    final key = _key(track);
    if (_picked.remove(key) == null) _picked[key] = track;
    notifyListeners();
  }

  /// Picks every song of [all] (or unpicks them when all are picked).
  void toggleAll(List<Track> all) {
    if (all.every(contains)) {
      _picked.clear();
    } else {
      for (final t in all) {
        _picked[_key(t)] = t;
      }
    }
    notifyListeners();
  }

  /// Leaves selection mode.
  void clear() {
    if (_picked.isEmpty) return;
    _picked.clear();
    notifyListeners();
  }

  // Playlist entries may hold the same song twice.
  static String _key(Track t) => t.playlistItemId ?? t.id;
}

/// Lets the song rows below pick several songs at once (long press) and
/// shows what can be done with them in a bar at the bottom.
class TrackSelectionScope extends StatefulWidget {
  /// Creates the scope around [child]; [tracks] is used by "select all".
  const TrackSelectionScope({
    required this.tracks,
    required this.child,
    super.key,
  });

  /// Every song on the page.
  final List<Track> tracks;

  /// The page content.
  final Widget child;

  /// The selection of the nearest scope, if any; does not listen to it.
  static TrackSelection? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_SelectionInherited>()?.notifier;

  /// Like [maybeOf], and rebuilds [context] when the selection changes.
  static TrackSelection? watch(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_SelectionInherited>()
      ?.notifier;

  @override
  State<TrackSelectionScope> createState() => _TrackSelectionScopeState();
}

class _TrackSelectionScopeState extends State<TrackSelectionScope> {
  final _selection = TrackSelection();

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SelectionInherited(
    notifier: _selection,
    child: ListenableBuilder(
      listenable: _selection,
      child: widget.child,
      builder: (context, child) => PopScope(
        // Back leaves selection mode first.
        canPop: !_selection.active,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _selection.clear();
        },
        child: Column(
          children: [
            Expanded(child: child!),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: _selection.active
                  ? _SelectionBar(selection: _selection, all: widget.tracks)
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SelectionInherited extends InheritedNotifier<TrackSelection> {
  const _SelectionInherited({required super.notifier, required super.child});
}

class _SelectionBar extends ConsumerWidget {
  const _SelectionBar({required this.selection, required this.all});

  final TrackSelection selection;
  final List<Track> all;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final capabilities = ref.watch(activeSourceProvider)?.capabilities;
    final player = ref.read(playerControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final allPicked = all.isNotEmpty && all.every(selection.contains);

    void done(String? message) {
      selection.clear();
      if (message != null) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    }

    final actions = <(IconData, String, VoidCallback)>[
      (
        Icons.play_arrow_rounded,
        l10n.play,
        () {
          unawaited(player.playTracks(selection.inOrder(all)));
          done(null);
        },
      ),
      (
        Icons.playlist_play,
        l10n.playNext,
        () {
          unawaited(player.playNext(selection.inOrder(all)));
          done(l10n.addedToQueue);
        },
      ),
      (
        Icons.playlist_add,
        l10n.addToQueue,
        () {
          unawaited(player.addToQueue(selection.inOrder(all)));
          done(l10n.addedToQueue);
        },
      ),
      if (capabilities?.editablePlaylists ?? false)
        (
          Icons.playlist_add_check,
          l10n.addToPlaylist,
          () {
            final tracks = selection.inOrder(all);
            unawaited(
              showAddToPlaylistSheet(
                context,
                ref,
                tracks,
              ).then((_) => selection.clear()),
            );
          },
        ),
      (
        Icons.download_outlined,
        l10n.download,
        () {
          unawaited(
            ref
                .read(downloadControllerProvider.notifier)
                .enqueue(selection.inOrder(all)),
          );
          done(l10n.downloadStarted(selection.count));
        },
      ),
      if (capabilities?.favorites ?? false)
        (
          Icons.favorite_border,
          l10n.favoriteAdd,
          () =>
              unawaited(_favorite(context, ref, selection.inOrder(all), done)),
        ),
    ];

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.cancel,
                  onPressed: selection.clear,
                ),
                Expanded(
                  child: Text(
                    l10n.selectedCount(selection.count),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => selection.toggleAll(all),
                  child: Text(allPicked ? l10n.selectNone : l10n.selectAll),
                ),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  for (final (icon, label, onTap) in actions)
                    _BarAction(icon: icon, label: label, onTap: onTap),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _favorite(
    BuildContext context,
    WidgetRef ref,
    List<Track> tracks,
    void Function(String? message) done,
  ) async {
    final source = ref.read(activeSourceProvider);
    if (source == null) return;
    final l10n = context.l10n;
    final player = ref.read(playerControllerProvider.notifier);
    for (final t in tracks.where((t) => !t.isFavorite)) {
      final result = await source.setFavorite(t.id, value: true);
      if (result case Err(:final failure)) {
        if (context.mounted) done(failureMessage(l10n, failure));
        return;
      }
      player.updateTrack(t.copyWith(isFavorite: true));
    }
    ref.invalidate(trackListProvider);
    if (context.mounted) done(l10n.favoritesAdded(tracks.length));
  }
}

class _BarAction extends StatelessWidget {
  const _BarAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: SizedBox(
      width: 84,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    ),
  );
}
