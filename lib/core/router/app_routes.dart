import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/config/feature_flags.dart';
import 'package:melody/domain/models/server.dart';

/// Route locations used across the app.
abstract final class AppRoutes {
  /// Home tab.
  static const home = '/home';

  /// Search tab.
  static const search = '/search';

  /// Library tab.
  static const library = '/library';

  /// Settings screen of the home tab; [settingsIn] keeps the current tab.
  static const settings = '/home/settings';

  /// Screen for adding a server.
  static const connect = '/connect';

  /// Sign-in screen of a server.
  static const login = '/connect/login';

  /// Joining a friend's server with a Tailscale invite code.
  static const joinTailnet = '/connect/tailnet';

  /// Full-screen player.
  static const nowPlaying = '/player';

  /// The queue.
  static const queue = '/player/queue';

  /// Tab roots; detail pages are nested below each of them.
  static const List<String> tabs = [home, search, library];

  /// Sign-in location for the server at [baseUrl].
  static String loginFor({
    required Uri baseUrl,
    required String name,
    String? id,
    String? version,
    String? userName,
    bool expired = false,
    SourceType type = SourceType.jellyfin,
  }) => Uri(
    path: login,
    queryParameters: {
      'url': baseUrl.toString(),
      'name': name,
      'id': ?id,
      'version': ?version,
      'user': ?userName,
      if (expired) 'expired': '1',
      if (type != SourceType.jellyfin) 'type': type.name,
    },
  ).toString();

  /// Sign-in location for [server].
  static String loginForServer(ServerInfo server) => loginFor(
    baseUrl: server.baseUrl,
    name: server.name,
    id: server.id,
    version: server.version,
    type: server.type,
  );

  /// Root of the tab shown in the tab bar; kept up to date by the shell.
  ///
  /// Pages outside the tabs (the full player, its queue) use it to open
  /// details in the right tab. Guessing "home" there used to push pages into
  /// the home tab while another tab was active, which broke the home tab.
  static String currentTab = home;

  static String _tab(BuildContext context) {
    final first = GoRouterState.of(context).uri.pathSegments.firstOrNull;
    final root = '/$first';
    return tabs.contains(root) ? root : currentTab;
  }

  /// Whether [context] is inside the full player (outside the tabs).
  static bool isInPlayer(BuildContext context) =>
      GoRouterState.of(context).uri.path.startsWith(nowPlaying);

  /// Settings inside the current tab, so the tab bar stays visible.
  static String settingsIn(BuildContext context) => '${_tab(context)}/settings';

  /// Font picker inside the current tab.
  static String fontPickerIn(BuildContext context) =>
      '${settingsIn(context)}/font';

  /// Equaliser inside the current tab.
  static String equalizerIn(BuildContext context) =>
      '${settingsIn(context)}/equalizer';

  /// Listening statistics inside the current tab.
  static String statsIn(BuildContext context) => '${_tab(context)}/stats';

  /// Year in review inside the current tab.
  static String wrapIn(BuildContext context, int year) =>
      '${statsIn(context)}/wrap/$year';

  /// Album page inside the current tab.
  static String album(BuildContext context, String id) =>
      '${_tab(context)}/album/${Uri.encodeComponent(id)}';

  /// Artist page inside the current tab.
  static String artist(BuildContext context, String id) =>
      '${_tab(context)}/artist/${Uri.encodeComponent(id)}';

  /// Genre page inside the current tab.
  static String genre(BuildContext context, String id, String name) => Uri(
    path: '${_tab(context)}/genre/${Uri.encodeComponent(id)}',
    queryParameters: {'name': name},
  ).toString();

  /// Playlist page inside the current tab.
  static String playlist(BuildContext context, String id, String name) => Uri(
    path: '${_tab(context)}/playlist/${Uri.encodeComponent(id)}',
    queryParameters: {'name': name},
  ).toString();
}
