import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/core/widgets/artwork_image.dart';
import 'package:melody/core/widgets/empty_state.dart';
import 'package:melody/core/widgets/failure_view.dart';
import 'package:melody/core/widgets/large_title_page.dart';
import 'package:melody/core/widgets/shelf_header.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/features/library/widgets/media_tiles.dart';
import 'package:melody/features/search/search_controller.dart';
import 'package:melody/features/settings/widgets/section_header.dart';
import 'package:melody/features/shell/app_shell.dart';
import 'package:melody/l10n/l10n.dart';

/// Tab for searching the active source.
class SearchScreen extends ConsumerStatefulWidget {
  /// Creates the search screen.
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _setText(String text) {
    _field.text = text;
    ref.read(searchQueryControllerProvider.notifier).setQuery(text);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(searchQueryControllerProvider);
    final controller = ref.read(searchQueryControllerProvider.notifier);
    final field = Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _field,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l10n.searchHint,
          filled: true,
          fillColor: scheme.surfaceContainerHigh,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _field.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.cancel),
                  tooltip: l10n.searchClear,
                  onPressed: () => _setText(''),
                ),
        ),
        onChanged: (text) {
          controller.setQuery(text);
          setState(() {});
        },
        onSubmitted: ref.read(recentSearchesProvider.notifier).add,
      ),
    );
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: LargeTitlePage(
          title: l10n.navSearch,
          automaticallyImplyLeading: false,
          actions: const [SettingsButton()],
          slivers: [
            SliverToBoxAdapter(child: field),
            if (state.isLoading)
              const SliverToBoxAdapter(
                child: LinearProgressIndicator(minHeight: 2),
              ),
            ..._results(context, state),
          ],
        ),
      ),
    );
  }

  List<Widget> _results(BuildContext context, SearchState state) {
    final l10n = context.l10n;
    if (state.query.isEmpty) return [_RecentSearches(onSelected: _setText)];
    final failure = state.failure;
    if (failure != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: FailureView(
            failure: failure,
            onRetry: ref.read(searchQueryControllerProvider.notifier).retry,
          ),
        ),
      ];
    }
    final loaded = state.result;
    if (loaded == null) return const [];
    final result = loaded.value;
    if (result.isEmpty) {
      if (state.isLoading) return const [];
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.search_off,
            title: l10n.searchNoResults(state.query),
          ),
        ),
      ];
    }
    return [
      if (loaded.fromCache) const SliverToBoxAdapter(child: OfflineBanner()),
      if (result.artists.isNotEmpty) ...[
        SliverToBoxAdapter(child: ShelfHeader(l10n.libraryArtists)),
        SliverList.list(
          children: [for (final a in result.artists) ArtistTile(artist: a)],
        ),
      ],
      if (result.albums.isNotEmpty) ...[
        SliverToBoxAdapter(child: ShelfHeader(l10n.libraryAlbums)),
        SliverList.list(
          children: [for (final a in result.albums) _AlbumTile(album: a)],
        ),
      ],
      if (result.tracks.isNotEmpty) ...[
        SliverToBoxAdapter(child: ShelfHeader(l10n.librarySongs)),
        TrackSliverList(tracks: result.tracks),
      ],
      if (result.playlists.isNotEmpty) ...[
        SliverToBoxAdapter(child: ShelfHeader(l10n.libraryPlaylists)),
        SliverList.list(
          children: [
            for (final p in result.playlists) PlaylistTile(playlist: p),
          ],
        ),
      ],
    ];
  }
}

class _AlbumTile extends StatelessWidget {
  const _AlbumTile({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: ArtworkImage(artwork: album.artwork, size: 48, radius: 6),
    title: Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: album.artistLine.isEmpty
        ? null
        : Text(album.artistLine, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => context.push(AppRoutes.album(context, album.id)),
  );
}

class _RecentSearches extends ConsumerWidget {
  const _RecentSearches({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final recent = ref.watch(recentSearchesProvider);
    if (recent.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.search,
          title: l10n.searchHint,
          message: l10n.searchEmptyBody,
        ),
      );
    }
    return SliverList.list(
      children: [
        Row(
          children: [
            Expanded(child: SectionHeader(l10n.searchRecent)),
            Padding(
              padding: const EdgeInsets.only(top: 12, right: 8),
              child: TextButton(
                onPressed: ref.read(recentSearchesProvider.notifier).clear,
                child: Text(l10n.searchClearRecent),
              ),
            ),
          ],
        ),
        for (final query in recent)
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(query),
            onTap: () => onSelected(query),
          ),
      ],
    );
  }
}
