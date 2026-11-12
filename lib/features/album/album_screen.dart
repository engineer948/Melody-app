import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/core/theme/artwork_palette.dart';
import 'package:melody/core/utils/formatters.dart';
import 'package:melody/core/widgets/failure_view.dart';
import 'package:melody/core/widgets/large_title_page.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/downloads/download_widgets.dart';
import 'package:melody/features/library/library_providers.dart';
import 'package:melody/features/library/widgets/media_tiles.dart';
import 'package:melody/features/library/widgets/paged_scroll_view.dart';
import 'package:melody/features/player/track_actions.dart';
import 'package:melody/features/settings/widgets/section_header.dart';
import 'package:melody/l10n/l10n.dart';

/// Album page: centred cover, title, Play / Shuffle and the track list.
class AlbumScreen extends ConsumerWidget {
  /// Creates the page of album [id].
  const AlbumScreen({required this.id, super.key});

  /// Album id.
  final String id;

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    Album album,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final result = await ref
        .read(libraryRepositoryProvider)
        ?.setAlbumFavorite(album.id, value: !album.isFavorite);
    final failure = result?.failureOrNull;
    if (failure != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, failure))),
      );
    }
    ref.invalidate(albumDetailProvider(id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final value = ref.watch(albumDetailProvider(id));
    final loaded = value.value;
    final album = loaded?.value.album;
    final canFavorite =
        ref.watch(activeSourceProvider)?.capabilities.favorites ?? false;
    return Scaffold(
      body: LargeTitlePage(
        title: album?.title ?? '',
        colors: ref.watch(artworkPaletteProvider(album?.artwork)).value?.colors,
        header: loaded == null
            ? const SizedBox(height: 1)
            : _AlbumHeader(detail: loaded.value),
        actions: [
          if (loaded != null && loaded.value.tracks.isNotEmpty)
            DownloadButton(tracks: loaded.value.tracks),
          if (album != null && canFavorite)
            IconButton(
              icon: Icon(
                album.isFavorite ? Icons.favorite : Icons.favorite_border,
              ),
              tooltip: album.isFavorite
                  ? l10n.favoriteRemove
                  : l10n.favoriteAdd,
              onPressed: () => _toggleFavorite(context, ref, album),
            ),
        ],
        slivers: loadedSlivers(
          value: value,
          onRetry: () => ref.invalidate(albumDetailProvider(id)),
          builder: (loaded) => [
            if (loaded.refreshFailure != null)
              const SliverToBoxAdapter(child: OfflineBanner()),
            ..._trackSlivers(context, loaded.value),
          ],
        ),
      ),
    );
  }

  List<Widget> _trackSlivers(BuildContext context, AlbumDetail detail) {
    final l10n = context.l10n;
    final tracks = detail.tracks;
    final discs = {for (final t in tracks) t.discNumber ?? 1}.toList()..sort();
    final gain = detail.album.gainDb;
    final queue = [
      for (final t in tracks)
        if (gain == null) t else t.copyWith(albumGainDb: t.albumGainDb ?? gain),
    ];
    return [
      for (final disc in discs) ...[
        if (discs.length > 1)
          SliverToBoxAdapter(child: SectionHeader(l10n.discNumber(disc))),
        SliverList.list(
          children: [
            for (var i = 0; i < queue.length; i++)
              if ((queue[i].discNumber ?? 1) == disc)
                TrackTile(
                  track: queue[i],
                  queue: queue,
                  index: i,
                  showNumber: true,
                  albumInOrder: true,
                ),
          ],
        ),
      ],
    ];
  }
}

class _AlbumHeader extends StatelessWidget {
  const _AlbumHeader({required this.detail});

  final AlbumDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final album = detail.album;
    final tracks = detail.tracks;
    final total = tracks.fold(
      Duration.zero,
      (sum, t) => sum + (t.duration ?? Duration.zero),
    );
    final facts = [
      if (album.genres.isNotEmpty) album.genres.first,
      if (album.year != null) '${album.year}',
      l10n.trackCount(tracks.length),
      if (total > Duration.zero) formatDuration(total),
    ].join(' · ');
    final artistId = album.artists.firstOrNull?.id;
    final width = MediaQuery.sizeOf(context).width;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 8, 32, 16),
          child: CoverArt(
            artwork: album.artwork,
            size: (width * 0.62).clamp(160, 300),
            radius: 12,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            album.title,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
        if (album.artistLine.isNotEmpty)
          TextButton(
            onPressed: artistId == null
                ? null
                : () => context.push(AppRoutes.artist(context, artistId)),
            child: Text(
              album.artistLine,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        Text(
          facts,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        PlayShuffleButtons(tracks: tracks, albumInOrder: true),
        const Divider(indent: 16, endIndent: 16),
      ],
    );
  }
}
