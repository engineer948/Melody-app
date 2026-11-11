import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/config/app_config.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/core/widgets/frosted.dart';
import 'package:melody/features/player/mini_player.dart';
import 'package:melody/l10n/l10n.dart';

/// Frame around the top-level tabs.
///
/// Phones get a frosted bottom bar with the mini player floating above it;
/// wider windows get a navigation rail.
class AppShell extends StatelessWidget {
  /// Creates the shell for [navigationShell].
  const AppShell({required this.navigationShell, super.key});

  /// Branch container provided by the router.
  final StatefulNavigationShell navigationShell;

  void _select(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    AppRoutes.currentTab = AppRoutes.tabs[navigationShell.currentIndex];
    final l10n = context.l10n;
    final tabs = [
      (Icons.home_outlined, Icons.home_rounded, l10n.navHome),
      (Icons.search, Icons.search_rounded, l10n.navSearch),
      (
        Icons.library_music_outlined,
        Icons.library_music_rounded,
        l10n.navLibrary,
      ),
    ];
    final wide = MediaQuery.sizeOf(context).width >= AppConfig.railBreakpoint;

    if (!wide) {
      return Scaffold(
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayer(),
            Frosted(
              child: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _select,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                height: 64,
                destinations: [
                  for (final (icon, selectedIcon, label) in tabs)
                    NavigationDestination(
                      icon: Icon(icon),
                      selectedIcon: Icon(selectedIcon),
                      label: label,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: Row(
        children: [
          SafeArea(
            right: false,
            child: NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final (icon, selectedIcon, label) in tabs)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selectedIcon),
                    label: Text(label),
                  ),
              ],
            ),
          ),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: const SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomRight,
          heightFactor: 1,
          child: SizedBox(width: 480, child: MiniPlayer()),
        ),
      ),
    );
  }
}

/// App bar button that opens the settings screen.
class SettingsButton extends StatelessWidget {
  /// Creates the button.
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.account_circle_outlined),
    tooltip: context.l10n.settingsTitle,
    onPressed: () => context.push(AppRoutes.settingsIn(context)),
  );
}
