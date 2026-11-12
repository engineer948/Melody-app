import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/config/feature_flags.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/core/widgets/empty_state.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/features/album/album_screen.dart';
import 'package:melody/features/artist/artist_screen.dart';
import 'package:melody/features/auth/add_server_screen.dart';
import 'package:melody/features/auth/login_screen.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/downloads/downloads_page.dart';
import 'package:melody/features/genre/genre_screen.dart';
import 'package:melody/features/home/home_screen.dart';
import 'package:melody/features/library/library_pages.dart';
import 'package:melody/features/library/library_screen.dart';
import 'package:melody/features/player/now_playing_screen.dart';
import 'package:melody/features/player/queue_screen.dart';
import 'package:melody/features/playlist/playlist_screen.dart';
import 'package:melody/features/search/search_screen.dart';
import 'package:melody/features/settings/debug_sources_screen.dart';
import 'package:melody/features/settings/equalizer_screen.dart';
import 'package:melody/features/settings/font_picker_screen.dart';
import 'package:melody/features/settings/settings_screen.dart';
import 'package:melody/features/shell/app_shell.dart';
import 'package:melody/features/stats/stats_screen.dart';
import 'package:melody/features/stats/wrap_screen.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Where to send the user for the given [session] and [location].
///
/// Returns `null` when [location] may be shown.
String? sessionRedirect(SessionState session, String location) {
  final connecting = location.startsWith(AppRoutes.connect);
  final active = session.active;
  if (active == null) return connecting ? null : AppRoutes.connect;
  if (session.activeExpired && !connecting) {
    return AppRoutes.loginFor(
      baseUrl: active.baseUrl,
      name: active.serverName,
      id: active.serverId,
      version: active.serverVersion,
      userName: active.userName,
      expired: true,
      type: active.type,
    );
  }
  return null;
}

/// Detail pages available below every tab.
List<RouteBase> _detailRoutes() => [
  GoRoute(
    path: 'settings',
    builder: (context, state) => const SettingsScreen(),
    routes: [
      _page('font', const FontPickerScreen()),
      _page('equalizer', const EqualizerScreen()),
      _page('debug-sources', const DebugSourcesScreen()),
    ],
  ),
  GoRoute(
    path: 'stats',
    builder: (context, state) => const StatsScreen(),
    routes: [
      GoRoute(
        path: 'wrap/:year',
        builder: (context, state) => WrapScreen(
          year:
              int.tryParse(state.pathParameters['year'] ?? '') ??
              DateTime.now().year,
        ),
      ),
    ],
  ),
  GoRoute(
    path: 'album/:id',
    builder: (context, state) => AlbumScreen(id: state.pathParameters['id']!),
  ),
  GoRoute(
    path: 'artist/:id',
    builder: (context, state) => ArtistScreen(id: state.pathParameters['id']!),
  ),
  GoRoute(
    path: 'genre/:id',
    builder: (context, state) => GenreScreen(
      id: state.pathParameters['id']!,
      name: state.uri.queryParameters['name'] ?? '',
    ),
  ),
  GoRoute(
    path: 'playlist/:id',
    builder: (context, state) => PlaylistScreen(
      id: state.pathParameters['id']!,
      name: state.uri.queryParameters['name'] ?? '',
    ),
  ),
];

StatefulShellBranch _tab(
  String path,
  Widget screen, [
  List<RouteBase> extra = const [],
]) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: path,
      builder: (context, state) => screen,
      routes: [..._detailRoutes(), ...extra],
    ),
  ],
);

GoRoute _page(String path, Widget screen) =>
    GoRoute(path: path, builder: (context, state) => screen);

/// Library categories, nested in the library tab.
final _libraryRoutes = <RouteBase>[
  _page('albums', const AlbumsPage()),
  _page('artists', const ArtistsPage()),
  _page('songs', const SongsPage()),
  _page('playlists', const PlaylistsPage()),
  _page('genres', const GenresPage()),
  _page('favorites', const SongsPage(favoritesOnly: true)),
  _page('downloads', const DownloadsPage()),
];

/// The player slides up from the bottom.
Page<void> _slideUp(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      child: child,
      transitionsBuilder: (context, animation, _, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );

/// The application's router.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final sessionChanged = ValueNotifier(0);
  ref
    ..listen(sessionControllerProvider, (_, _) => sessionChanged.value++)
    ..onDispose(sessionChanged.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: sessionChanged,
    redirect: (context, state) => sessionRedirect(
      ref.read(sessionControllerProvider),
      state.matchedLocation,
    ),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          _tab(AppRoutes.home, const HomeScreen()),
          _tab(AppRoutes.search, const SearchScreen()),
          _tab(AppRoutes.library, const LibraryScreen(), _libraryRoutes),
        ],
      ),
      // Old location of the settings, kept for links and saved state.
      GoRoute(path: '/settings', redirect: (_, _) => AppRoutes.settings),
      GoRoute(
        path: AppRoutes.nowPlaying,
        pageBuilder: (context, state) =>
            _slideUp(state, const NowPlayingScreen()),
        routes: [_page('queue', const QueueScreen())],
      ),
      GoRoute(
        path: AppRoutes.connect,
        builder: (context, state) => const AddServerScreen(),
        routes: [
          GoRoute(
            path: 'login',
            redirect: (context, state) =>
                Uri.tryParse(state.uri.queryParameters['url'] ?? '')
                        ?.host
                        .isNotEmpty ??
                    false
                ? null
                : AppRoutes.connect,
            builder: (context, state) {
              final query = state.uri.queryParameters;
              final baseUrl = Uri.parse(query['url']!);
              return LoginScreen(
                server: ServerInfo(
                  baseUrl: baseUrl,
                  name: query['name'] ?? baseUrl.host,
                  id: query['id'],
                  version: query['version'],
                  type:
                      SourceType.values.asNameMap()[query['type']] ??
                      SourceType.jellyfin,
                ),
                initialUserName: query['user'],
                expired: query['expired'] == '1',
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: EmptyState(
        icon: Icons.explore_off_outlined,
        title: context.l10n.errorPageNotFound,
        actionLabel: context.l10n.goHome,
        onAction: () => context.go(AppRoutes.home),
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
}
