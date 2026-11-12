import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/widgets/failure_view.dart';
import 'package:melody/core/widgets/large_title_page.dart';
import 'package:melody/core/widgets/shelf_header.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/features/library/library_providers.dart';
import 'package:melody/features/library/widgets/media_tiles.dart';
import 'package:melody/features/library/widgets/paged_scroll_view.dart';
import 'package:melody/features/player/track_actions.dart';
import 'package:melody/features/share/share_screen.dart';
import 'package:melody/features/share/share_subject.dart';
import 'package:melody/l10n/l10n.dart';

/// Artist page: portrait, name, popular songs, albums and biography.
class ArtistScreen extends ConsumerWidget {
  /// Creates the page of artist [id].
  const ArtistScreen({required this.id, super.key});

  /// Artist id.
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(artistDetailProvider(id));
    final detail = value.value?.value;
    return Scaffold(
      body: LargeTitlePage(
        title: detail?.artist.name ?? '',
        header: detail == null
            ? const SizedBox(height: 1)
            : _ArtistHeader(detail: detail),
        actions: [
          if (detail != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: context.l10n.share,
              onPressed: () =>
                  showShareScreen(context, ShareSubject.artist(detail.artist)),
            ),
        ],
        slivers: loadedSlivers(
          value: value,
          onRetry: () => ref.invalidate(artistDetailProvider(id)),
          builder: (loaded) =>
              _body(context, loaded.value, loaded.refreshFailure != null),
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context, ArtistDetail detail, bool offline) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final overview = detail.artist.overview;
    return [
      if (offline) const SliverToBoxAdapter(child: OfflineBanner()),
      if (detail.topTracks.isNotEmpty) ...[
        SliverToBoxAdapter(child: ShelfHeader(l10n.artistTopTracks)),
        TrackSliverList(tracks: detail.topTracks),
      ],
      if (detail.albums.isNotEmpty) ...[
        SliverToBoxAdapter(child: ShelfHeader(l10n.libraryAlbums)),
        AlbumSliverGrid(albums: detail.albums),
      ],
      if (overview != null) ...[
        SliverToBoxAdapter(child: ShelfHeader(l10n.artistAbout)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              overview,
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ],
      if (detail.albums.isEmpty && detail.topTracks.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(l10n.emptyList, textAlign: TextAlign.center),
          ),
        ),
    ];
  }
}

class _ArtistHeader extends StatelessWidget {
  const _ArtistHeader({required this.detail});

  final ArtistDetail detail;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(height: 8),
      CoverArt(
        artwork: detail.artist.artwork,
        size: 180,
        circular: true,
        icon: Icons.person_outline,
      ),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          detail.artist.name,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 8),
      PlayShuffleButtons(tracks: detail.topTracks),
    ],
  );
}
