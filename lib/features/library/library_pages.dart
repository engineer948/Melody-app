import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/widgets/empty_state.dart';
import 'package:melody/core/widgets/failure_view.dart';
import 'package:melody/core/widgets/large_title_page.dart';
import 'package:melody/data/repositories/library_repository.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/library/collection_actions.dart';
import 'package:melody/features/library/library_providers.dart';
import 'package:melody/features/library/track_selection.dart';
import 'package:melody/features/library/widgets/media_tiles.dart';
import 'package:melody/features/library/widgets/paged_scroll_view.dart';
import 'package:melody/features/player/track_actions.dart';
import 'package:melody/features/playlist/m3u_actions.dart';
import 'package:melody/features/playlist/smart_playlists.dart';
import 'package:melody/l10n/l10n.dart';

/// Locations of the library categories.
abstract final class LibraryRoutes {
  /// All albums.
  static const albums = '/library/albums';

  /// All album artists.
  static const artists = '/library/artists';

  /// All songs.
  static const songs = '/library/songs';

  /// All playlists.
  static const playlists = '/library/playlists';

  /// All genres.
  static const genres = '/library/genres';

  /// Favourite songs.
  static const favorites = '/library/favorites';

  /// Songs available offline.
  static const downloads = '/library/downloads';
}

/// Every album, sortable.
class AlbumsPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const AlbumsPage({super.key});

  @override
  ConsumerState<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends ConsumerState<AlbumsPage> {
  AlbumSort _sort = AlbumSort.name;

  static String _label(AppLocalizations l10n, AlbumSort sort) => switch (sort) {
    AlbumSort.name => l10n.sortName,
    AlbumSort.artist => l10n.sortArtist,
    AlbumSort.year => l10n.sortYear,
    AlbumSort.dateAdded => l10n.sortDateAdded,
    AlbumSort.random => l10n.sortRandom,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = albumListProvider(AlbumQuery(sort: _sort));
    return Scaffold(
      body: PagedScrollView<Album>(
        title: l10n.libraryAlbums,
        state: ref.watch(provider),
        onRefresh: () => ref.invalidate(provider),
        onLoadMore: () => ref.read(provider.notifier).loadMore(),
        actions: [
          PopupMenuButton<AlbumSort>(
            icon: const Icon(Icons.sort),
            tooltip: l10n.sortBy,
            initialValue: _sort,
            onSelected: (sort) => setState(() => _sort = sort),
            itemBuilder: (context) => [
              for (final sort in AlbumSort.values)
                PopupMenuItem(value: sort, child: Text(_label(l10n, sort))),
            ],
          ),
        ],
        sliverBuilder: (albums) => AlbumSliverGrid(albums: albums),
      ),
    );
  }
}

/// Every album artist.
class ArtistsPage extends ConsumerWidget {
  /// Creates the page.
  const ArtistsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: PagedScrollView<Artist>(
      title: context.l10n.libraryArtists,
      state: ref.watch(artistListProvider),
      emptyIcon: Icons.person_outline,
      onRefresh: () => ref.invalidate(artistListProvider),
      onLoadMore: () => ref.read(artistListProvider.notifier).loadMore(),
      sliverBuilder: (artists) => SliverFixedExtentList.builder(
        itemExtent: 64,
        itemCount: artists.length,
        itemBuilder: (context, index) => ArtistTile(artist: artists[index]),
      ),
    ),
  );
}

/// Every song, or only favourites.
class SongsPage extends ConsumerWidget {
  /// Creates the page.
  const SongsPage({this.favoritesOnly = false, super.key});

  /// Restricts to favourites.
  final bool favoritesOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = trackListProvider(
      TrackQuery(favoritesOnly: favoritesOnly),
    );
    final state = ref.watch(provider);
    return Scaffold(
      body: TrackSelectionScope(
        tracks: state.items,
        child: PagedScrollView<Track>(
          title: favoritesOnly ? l10n.libraryFavorites : l10n.librarySongs,
          state: state,
          emptyIcon: favoritesOnly
              ? Icons.favorite_border
              : Icons.music_note_outlined,
          onRefresh: () => ref.invalidate(provider),
          onLoadMore: () => ref.read(provider.notifier).loadMore(),
          headers: [
            if (state.items.isNotEmpty)
              SliverToBoxAdapter(
                child: PlayShuffleButtons(tracks: state.items),
              ),
          ],
          sliverBuilder: (tracks) => TrackSliverList(tracks: tracks),
        ),
      ),
    );
  }
}

/// A list loaded in one go, with cache status.
class _LoadedListPage<T> extends StatelessWidget {
  const _LoadedListPage({
    required this.title,
    required this.value,
    required this.onRefresh,
    required this.itemBuilder,
    required this.emptyIcon,
    this.actions = const [],
    this.headers = const [],
  });

  /// Slivers shown above the list, also when it is empty.
  final List<Widget> headers;

  final List<Widget> actions;
  final String title;
  final AsyncValue<Loaded<List<T>>> value;
  final VoidCallback onRefresh;
  final Widget Function(T item) itemBuilder;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LargeTitlePage(
      title: title,
      actions: actions,
      onRefresh: () async => onRefresh(),
      slivers: loadedSlivers(
        value: value,
        onRetry: onRefresh,
        builder: (loaded) => [
          if (loaded.refreshFailure != null)
            const SliverToBoxAdapter(child: OfflineBanner()),
          ...headers,
          if (loaded.value.isEmpty && headers.isNotEmpty)
            const SliverToBoxAdapter()
          else if (loaded.value.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(icon: emptyIcon, title: context.l10n.emptyList),
            )
          else
            SliverList.builder(
              itemCount: loaded.value.length,
              itemBuilder: (context, index) => itemBuilder(loaded.value[index]),
            ),
        ],
      ),
    ),
  );
}

enum _NewPlaylist { plain, smart, import }

/// All playlists, smart playlists first.
class PlaylistsPage extends ConsumerWidget {
  /// Creates the page.
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final editable =
        ref.watch(activeSourceProvider)?.capabilities.editablePlaylists ??
        false;
    final smart = ref.watch(smartPlaylistsProvider);
    return _LoadedListPage<Playlist>(
      title: l10n.libraryPlaylists,
      actions: [
        PopupMenuButton<_NewPlaylist>(
          icon: const Icon(Icons.add),
          tooltip: l10n.newPlaylist,
          onSelected: (choice) => unawaited(switch (choice) {
            _NewPlaylist.plain => createPlaylist(context, ref),
            _NewPlaylist.smart => createSmartPlaylist(context, ref),
            _NewPlaylist.import => importM3u(context, ref),
          }),
          itemBuilder: (context) => [
            if (editable)
              PopupMenuItem(
                value: _NewPlaylist.plain,
                child: ListTile(
                  leading: const Icon(Icons.queue_music_outlined),
                  title: Text(l10n.newPlaylist),
                ),
              ),
            PopupMenuItem(
              value: _NewPlaylist.smart,
              child: ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: Text(l10n.smartNew),
              ),
            ),
            if (editable)
              PopupMenuItem(
                value: _NewPlaylist.import,
                child: ListTile(
                  leading: const Icon(Icons.file_open_outlined),
                  title: Text(l10n.m3uImport),
                ),
              ),
          ],
        ),
      ],
      headers: [
        if (smart.isNotEmpty) ...[
          SliverList.builder(
            itemCount: smart.length,
            itemBuilder: (context, i) => SmartPlaylistTile(playlist: smart[i]),
          ),
          const SliverToBoxAdapter(child: Divider(indent: 16, endIndent: 16)),
        ],
      ],
      value: ref.watch(playlistsProvider),
      onRefresh: () => ref.invalidate(playlistsProvider),
      emptyIcon: Icons.queue_music_outlined,
      itemBuilder: (playlist) => PlaylistTile(playlist: playlist),
    );
  }
}

/// All genres.
class GenresPage extends ConsumerWidget {
  /// Creates the page.
  const GenresPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _LoadedListPage<Genre>(
    title: context.l10n.libraryGenres,
    value: ref.watch(genresProvider),
    onRefresh: () => ref.invalidate(genresProvider),
    emptyIcon: Icons.sell_outlined,
    itemBuilder: (genre) => GenreTile(genre: genre),
  );
}
