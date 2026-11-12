import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/core/widgets/artwork_image.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/downloads/download_controller.dart';
import 'package:melody/features/library/collection_actions.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/player_controller.dart';

/// Opens the "…" menu of [track]: play next, add to queue, go to album or
/// artist.
Future<void> showTrackMenu(
  BuildContext context,
  WidgetRef ref,
  Track track,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  // From the full player, leave it and open the page in the current tab.
  final inPlayer = AppRoutes.isInPlayer(context);
  void open(String location) =>
      inPlayer ? router.go(location) : unawaited(router.push(location));
  final albumId = track.albumId;
  final artistId = track.artists.firstOrNull?.id;
  final albumRoute = albumId == null ? null : AppRoutes.album(context, albumId);
  final artistRoute = artistId == null
      ? null
      : AppRoutes.artist(context, artistId);
  final player = ref.read(playerControllerProvider.notifier);
  final capabilities = ref.read(activeSourceProvider)?.capabilities;
  final canFavorite = capabilities?.favorites ?? false;
  final canEditPlaylists = capabilities?.editablePlaylists ?? false;
  final downloads = ref.read(downloadControllerProvider.notifier);
  final isDownloaded = ref.read(downloadControllerProvider)[track.id] != null;
  final outer = context;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: ArtworkImage(
              artwork: track.artwork,
              size: 48,
              radius: 6,
              icon: Icons.music_note_outlined,
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
          ),
          const Divider(),
          if (canFavorite)
            ListTile(
              leading: Icon(
                track.isFavorite ? Icons.favorite : Icons.favorite_border,
              ),
              title: Text(
                track.isFavorite ? l10n.favoriteRemove : l10n.favoriteAdd,
              ),
              onTap: () {
                Navigator.pop(context);
                unawaited(toggleTrackFavorite(outer, ref, track));
              },
            ),
          if (canEditPlaylists)
            ListTile(
              leading: const Icon(Icons.playlist_add_check),
              title: Text(l10n.addToPlaylist),
              onTap: () {
                Navigator.pop(context);
                unawaited(showAddToPlaylistSheet(outer, ref, [track]));
              },
            ),
          ListTile(
            leading: Icon(
              isDownloaded
                  ? Icons.download_done_rounded
                  : Icons.download_outlined,
            ),
            title: Text(isDownloaded ? l10n.downloadRemove : l10n.download),
            onTap: () {
              Navigator.pop(context);
              unawaited(
                isDownloaded
                    ? downloads.remove([track.id])
                    : downloads.enqueue([track]),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_play),
            title: Text(l10n.playNext),
            onTap: () {
              Navigator.pop(context);
              unawaited(player.playNext([track]));
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.addedToQueue)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: Text(l10n.addToQueue),
            onTap: () {
              Navigator.pop(context);
              unawaited(player.addToQueue([track]));
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.addedToQueue)),
              );
            },
          ),
          if (albumRoute != null)
            ListTile(
              leading: const Icon(Icons.album_outlined),
              title: Text(l10n.goToAlbum),
              onTap: () {
                Navigator.pop(context);
                open(albumRoute);
              },
            ),
          if (artistRoute != null)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(l10n.goToArtist),
              onTap: () {
                Navigator.pop(context);
                open(artistRoute);
              },
            ),
        ],
      ),
    ),
  );
}

/// Big "Play" and "Shuffle" buttons side by side.
class PlayShuffleButtons extends ConsumerWidget {
  /// Creates the buttons for [tracks].
  const PlayShuffleButtons({
    required this.tracks,
    this.albumInOrder = false,
    super.key,
  });

  /// What to play.
  final List<Track> tracks;

  /// Whether [tracks] is one album in order (for volume normalisation).
  final bool albumInOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final player = ref.read(playerControllerProvider.notifier);
    final enabled = tracks.isNotEmpty;
    final accent = scheme.primary;
    final playStyle = FilledButton.styleFrom(
      backgroundColor: accent,
      foregroundColor: scheme.onPrimary,
      minimumSize: const Size.fromHeight(48),
    );
    final style = FilledButton.styleFrom(
      backgroundColor: accent.withValues(alpha: 0.16),
      foregroundColor: accent,
      minimumSize: const Size.fromHeight(48),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              style: playStyle,
              onPressed: enabled
                  ? () => player.playTracks(tracks, albumInOrder: albumInOrder)
                  : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l10n.play),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              style: style,
              onPressed: enabled
                  ? () => player.playTracks(tracks, shuffle: true)
                  : null,
              icon: const Icon(Icons.shuffle_rounded),
              label: Text(l10n.shuffle),
            ),
          ),
        ],
      ),
    );
  }
}
