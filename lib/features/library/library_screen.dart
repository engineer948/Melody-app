import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/widgets/large_title_page.dart';
import 'package:melody/core/widgets/shelf_header.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/library/library_pages.dart';
import 'package:melody/features/library/library_providers.dart';
import 'package:melody/features/library/widgets/media_tiles.dart';
import 'package:melody/features/library/widgets/paged_scroll_view.dart';
import 'package:melody/features/shell/app_shell.dart';
import 'package:melody/l10n/l10n.dart';

/// Albums shown under "Recently added" in the library.
const recentlyAddedQuery = AlbumQuery(sort: AlbumSort.dateAdded, limit: 24);

/// Library tab: categories on top, recently added albums below.
class LibraryScreen extends ConsumerWidget {
  /// Creates the library screen.
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final capabilities = ref.watch(activeSourceProvider)?.capabilities;
    final categories = <(IconData, String, String)>[
      if (capabilities?.playlists ?? false)
        (
          Icons.queue_music_rounded,
          l10n.libraryPlaylists,
          LibraryRoutes.playlists,
        ),
      (
        Icons.mic_external_on_rounded,
        l10n.libraryArtists,
        LibraryRoutes.artists,
      ),
      (Icons.album_rounded, l10n.libraryAlbums, LibraryRoutes.albums),
      (Icons.music_note_rounded, l10n.librarySongs, LibraryRoutes.songs),
      if (capabilities?.genres ?? false)
        (Icons.sell_rounded, l10n.libraryGenres, LibraryRoutes.genres),
      if (capabilities?.favorites ?? false)
        (
          Icons.favorite_rounded,
          l10n.libraryFavorites,
          LibraryRoutes.favorites,
        ),
      (
        Icons.download_for_offline_rounded,
        l10n.libraryDownloads,
        LibraryRoutes.downloads,
      ),
    ];
    final recent = ref.watch(albumListProvider(recentlyAddedQuery));
    return Scaffold(
      body: LargeTitlePage(
        title: l10n.navLibrary,
        automaticallyImplyLeading: false,
        actions: const [SettingsButton()],
        onRefresh: () async =>
            ref.invalidate(albumListProvider(recentlyAddedQuery)),
        slivers: [
          SliverList.list(
            children: [
              for (final (icon, label, route) in categories) ...[
                ListTile(
                  leading: Icon(icon, color: scheme.primary),
                  title: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(route),
                ),
                const Divider(indent: 56),
              ],
            ],
          ),
          SliverToBoxAdapter(child: ShelfHeader(l10n.homeRecentlyAdded)),
          ...pagedSlivers(
            context,
            state: recent,
            onRetry: () =>
                ref.invalidate(albumListProvider(recentlyAddedQuery)),
            sliverBuilder: (albums) => AlbumSliverGrid(albums: albums),
          ),
        ],
      ),
    );
  }
}
