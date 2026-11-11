import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/core/utils/formatters.dart';
import 'package:melody/core/widgets/artwork_image.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/features/downloads/download_widgets.dart';
import 'package:melody/features/player/track_actions.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/player_controller.dart';

/// Rounded cover with a soft shadow.
class CoverArt extends StatelessWidget {
  /// Creates the cover.
  const CoverArt({
    required this.artwork,
    this.size,
    this.radius = 10,
    this.icon = Icons.album_outlined,
    this.circular = false,
    super.key,
  });

  /// Image to show.
  final Artwork? artwork;

  /// Edge length; `null` fills the width.
  final double? size;

  /// Corner radius.
  final double radius;

  /// Placeholder icon.
  final IconData icon;

  /// Clips to a circle (artists).
  final bool circular;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      shape: circular ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circular ? null : BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ArtworkImage(
      artwork: artwork,
      size: size,
      radius: radius,
      icon: icon,
      circular: circular,
    ),
  );
}

/// Cover with title and artist, used in grids and shelves.
class AlbumCard extends StatelessWidget {
  /// Creates the card.
  const AlbumCard({required this.album, super.key});

  /// Album to show.
  final Album album;

  /// Height of the two text lines below the cover.
  static double textHeight(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(14) * 2.9 + 14;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '${album.title}, ${album.artistLine}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push(AppRoutes.album(context, album.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoverArt(artwork: album.artwork),
            const SizedBox(height: 8),
            Text(
              album.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              album.artistLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Responsive grid of [AlbumCard]s, as a sliver.
class AlbumSliverGrid extends StatelessWidget {
  /// Creates the grid.
  const AlbumSliverGrid({required this.albums, super.key});

  /// Albums to show.
  final List<Album> albums;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    sliver: SliverLayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final width = constraints.crossAxisExtent;
        final columns = (width / 190).ceil().clamp(2, 12);
        final tile = (width - spacing * (columns - 1)) / columns;
        return SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: 20,
            mainAxisExtent: tile + AlbumCard.textHeight(context),
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) => AlbumCard(album: albums[index]),
        );
      },
    ),
  );
}

/// List row of an artist.
class ArtistTile extends StatelessWidget {
  /// Creates the tile.
  const ArtistTile({required this.artist, super.key});

  /// Artist to show.
  final Artist artist;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: ArtworkImage(
      artwork: artist.artwork,
      size: 48,
      circular: true,
      icon: Icons.person_outline,
    ),
    title: Text(artist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => context.push(AppRoutes.artist(context, artist.id)),
  );
}

/// List row of a track. Tapping plays [queue] from this track.
class TrackTile extends ConsumerWidget {
  /// Creates the tile.
  const TrackTile({
    required this.track,
    this.queue,
    this.index = 0,
    this.showNumber = false,
    this.albumInOrder = false,
    super.key,
  });

  /// Track to show.
  final Track track;

  /// Tracks to queue when tapped; defaults to just [track].
  final List<Track>? queue;

  /// Position of [track] in [queue].
  final int index;

  /// Shows the track number instead of the cover.
  final bool showNumber;

  /// Whether [queue] is one album in order.
  final bool albumInOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isCurrent = ref.watch(
      playerControllerProvider.select((s) => s.current?.id == track.id),
    );
    final duration = track.duration;
    final subtitle = track.artistLine;
    final leading = showNumber
        ? SizedBox(
            width: 32,
            child: Center(
              child: isCurrent
                  ? Icon(Icons.graphic_eq, color: scheme.primary, size: 20)
                  : Text(
                      '${track.trackNumber ?? '–'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
            ),
          )
        : ArtworkImage(
            artwork: track.artwork,
            size: 48,
            radius: 6,
            icon: Icons.music_note_outlined,
          );
    return ListTile(
      leading: leading,
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: isCurrent ? TextStyle(color: scheme.primary) : null,
      ),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DownloadedBadge(trackId: track.id),
          if (duration != null)
            Text(
              formatDuration(duration),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.more_horiz),
            tooltip: context.l10n.moreOptions,
            onPressed: () => showTrackMenu(context, ref, track),
          ),
        ],
      ),
      onTap: () => ref
          .read(playerControllerProvider.notifier)
          .playTracks(
            queue ?? [track],
            start: queue == null ? 0 : index,
            albumInOrder: albumInOrder,
          ),
      onLongPress: () => showTrackMenu(context, ref, track),
    );
  }
}

/// Sliver list of tracks that play as one queue.
class TrackSliverList extends StatelessWidget {
  /// Creates the list.
  const TrackSliverList({
    required this.tracks,
    this.showNumber = false,
    this.albumInOrder = false,
    super.key,
  });

  /// Tracks to show.
  final List<Track> tracks;

  /// Shows track numbers.
  final bool showNumber;

  /// Whether [tracks] is one album in order.
  final bool albumInOrder;

  @override
  Widget build(BuildContext context) => SliverList.builder(
    itemCount: tracks.length,
    itemBuilder: (context, index) => TrackTile(
      track: tracks[index],
      queue: tracks,
      index: index,
      showNumber: showNumber,
      albumInOrder: albumInOrder,
    ),
  );
}

/// List row of a playlist.
class PlaylistTile extends StatelessWidget {
  /// Creates the tile.
  const PlaylistTile({required this.playlist, super.key});

  /// Playlist to show.
  final Playlist playlist;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: ArtworkImage(
      artwork: playlist.artwork,
      size: 48,
      radius: 6,
      icon: Icons.queue_music_outlined,
    ),
    title: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: const Icon(Icons.chevron_right),
    onTap: () =>
        context.push(AppRoutes.playlist(context, playlist.id, playlist.name)),
  );
}

/// List row of a genre.
class GenreTile extends StatelessWidget {
  /// Creates the tile.
  const GenreTile({required this.genre, super.key});

  /// Genre to show.
  final Genre genre;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.sell_outlined),
    title: Text(genre.name, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => context.push(AppRoutes.genre(context, genre.id, genre.name)),
  );
}
