import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/core/widgets/empty_state.dart';
import 'package:melody/core/widgets/failure_view.dart';
import 'package:melody/core/widgets/large_title_page.dart';
import 'package:melody/core/widgets/shelf_header.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/features/library/library_providers.dart';
import 'package:melody/features/library/widgets/media_tiles.dart';
import 'package:melody/features/shell/app_shell.dart';
import 'package:melody/features/stats/stats_providers.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/player_controller.dart';

const _recentlyAdded = AlbumQuery(sort: AlbumSort.dateAdded, limit: 20);
const _randomAlbums = AlbumQuery(sort: AlbumSort.random, limit: 20);
const _recentlyPlayed = TrackQuery(sort: TrackSort.recentlyPlayed, limit: 20);
const _mostPlayed = TrackQuery(sort: TrackSort.mostPlayed, limit: 20);

/// Greeting for the time of day.
String greeting(AppLocalizations l10n, DateTime now) => switch (now.hour) {
  >= 5 && < 12 => l10n.greetingMorning,
  >= 12 && < 18 => l10n.greetingAfternoon,
  >= 18 && < 23 => l10n.greetingEvening,
  _ => l10n.greetingNight,
};

/// Landing tab: a greeting, large featured albums and shelves.
class HomeScreen extends ConsumerWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  void _refresh(WidgetRef ref) {
    ref
      ..invalidate(albumListProvider(_recentlyAdded))
      ..invalidate(albumListProvider(_randomAlbums))
      ..invalidate(trackListProvider(_recentlyPlayed))
      ..invalidate(trackListProvider(_mostPlayed))
      ..invalidate(suggestionsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final added = ref.watch(albumListProvider(_recentlyAdded));
    final random = ref.watch(albumListProvider(_randomAlbums));
    final played = ref.watch(trackListProvider(_recentlyPlayed));
    final most = ref.watch(trackListProvider(_mostPlayed));
    final suggested = ref.watch(suggestionsProvider).value;
    final now = DateTime.now();

    final empty =
        added.items.isEmpty &&
        random.items.isEmpty &&
        played.items.isEmpty &&
        most.items.isEmpty;
    final loading =
        added.isLoading ||
        random.isLoading ||
        played.isLoading ||
        most.isLoading;
    final failure =
        added.failure ?? random.failure ?? played.failure ?? most.failure;

    final List<Widget> slivers;
    if (empty) {
      slivers = [
        SliverFillRemaining(
          hasScrollBody: false,
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : failure != null
              ? FailureView(failure: failure, onRetry: () => _refresh(ref))
              : EmptyState(
                  icon: Icons.library_music_outlined,
                  title: l10n.emptyList,
                  message: l10n.homeEmptyBody,
                  actionLabel: l10n.retry,
                  onAction: () => _refresh(ref),
                ),
        ),
      ];
    } else {
      slivers = [
        if (failure != null) const SliverToBoxAdapter(child: OfflineBanner()),
        // The year in review is put forward in December.
        if (now.month == 12 && (suggested?.mix.isNotEmpty ?? false))
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: FilledButton.icon(
                onPressed: () =>
                    context.push(AppRoutes.wrapIn(context, now.year)),
                icon: const Icon(Icons.auto_awesome),
                label: Text(l10n.wrapBanner(now.year)),
              ),
            ),
          ),
        if (added.items.isNotEmpty)
          SliverToBoxAdapter(
            child: _AlbumShelf(
              title: l10n.homeRecentlyAdded,
              albums: added.items,
              cardWidth: 240,
            ),
          ),
        if (suggested != null && suggested.mix.isNotEmpty)
          SliverToBoxAdapter(
            child: _TrackShelf(
              title: l10n.homeMixForYou,
              tracks: suggested.mix,
            ),
          ),
        if (played.items.isNotEmpty)
          SliverToBoxAdapter(
            child: _TrackShelf(
              title: l10n.homeRecentlyPlayed,
              tracks: played.items,
            ),
          ),
        if (most.items.isNotEmpty)
          SliverToBoxAdapter(
            child: _TrackShelf(title: l10n.homeMostPlayed, tracks: most.items),
          ),
        if (suggested != null && suggested.forgotten.isNotEmpty)
          SliverToBoxAdapter(
            child: _TrackShelf(
              title: l10n.homeForgotten,
              tracks: suggested.forgotten,
            ),
          ),
        if (random.items.isNotEmpty)
          SliverToBoxAdapter(
            child: _AlbumShelf(
              title: l10n.homeRandomAlbums,
              albums: random.items,
            ),
          ),
        if (suggested != null && suggested.discover.isNotEmpty)
          SliverToBoxAdapter(
            child: _TrackShelf(
              title: l10n.homeDiscover,
              tracks: suggested.discover,
            ),
          ),
      ];
    }

    return Scaffold(
      body: LargeTitlePage(
        title: greeting(l10n, now),
        automaticallyImplyLeading: false,
        actions: const [SettingsButton()],
        onRefresh: () async => _refresh(ref),
        slivers: slivers,
      ),
    );
  }
}

class _AlbumShelf extends StatelessWidget {
  const _AlbumShelf({
    required this.title,
    required this.albums,
    this.cardWidth = 156,
  });

  final String title;
  final List<Album> albums;
  final double cardWidth;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ShelfHeader(title),
      SizedBox(
        height: cardWidth + AlbumCard.textHeight(context),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          clipBehavior: Clip.none,
          itemCount: albums.length,
          separatorBuilder: (_, _) => const SizedBox(width: 16),
          itemBuilder: (context, index) => SizedBox(
            width: cardWidth,
            child: AlbumCard(album: albums[index]),
          ),
        ),
      ),
    ],
  );
}

class _TrackShelf extends ConsumerWidget {
  const _TrackShelf({required this.title, required this.tracks});

  final String title;
  final List<Track> tracks;

  static const _width = 156.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShelfHeader(title),
        SizedBox(
          height: _width + AlbumCard.textHeight(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            clipBehavior: Clip.none,
            itemCount: tracks.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final track = tracks[index];
              return SizedBox(
                width: _width,
                child: Semantics(
                  button: true,
                  label: '${track.title}, ${track.artistLine}',
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => ref
                        .read(playerControllerProvider.notifier)
                        .playTracks(tracks, start: index),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CoverArt(
                          artwork: track.artwork,
                          icon: Icons.music_note_outlined,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          track.artistLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
