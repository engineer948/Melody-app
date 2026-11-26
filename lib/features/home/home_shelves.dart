import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_shelves.g.dart';

/// The shelves of the home screen, in their default order.
enum HomeShelf {
  /// "Soundtrack of your life" cards (only when that is turned on).
  life,

  /// Albums recently added to the library.
  recentlyAdded,

  /// The on-device mix.
  mix,

  /// Songs played lately.
  recentlyPlayed,

  /// Songs played the most.
  mostPlayed,

  /// Favourites not heard for a while.
  forgotten,

  /// Random albums.
  randomAlbums,

  /// Songs never played.
  discover,
}

/// Order and visibility of the home shelves.
@immutable
class HomeShelves {
  /// Creates the settings; by default every shelf, in the default order.
  const HomeShelves({this.order = HomeShelf.values, this.hidden = const {}});

  /// Restores settings saved with [toJson]. Unknown names are dropped and
  /// shelves missing from a saved order are added at the end.
  factory HomeShelves.fromJson(Map<String, dynamic> json) {
    final names = HomeShelf.values.asNameMap();
    final order = <HomeShelf>[
      for (final n in json['order'] as List<dynamic>? ?? const []) ?names[n],
    ];
    return HomeShelves(
      order: [
        ...order.toSet(),
        for (final s in HomeShelf.values)
          if (!order.contains(s)) s,
      ],
      hidden: {
        for (final n in json['hidden'] as List<dynamic>? ?? const []) ?names[n],
      },
    );
  }

  /// Shelves from top to bottom.
  final List<HomeShelf> order;

  /// Shelves turned off.
  final Set<HomeShelf> hidden;

  /// The shelves to show, in order.
  List<HomeShelf> get visible => [
    for (final s in order)
      if (!hidden.contains(s)) s,
  ];

  /// Moves the shelf at [from] so that it ends up at [to].
  HomeShelves move(int from, int to) {
    final list = [...order];
    final shelf = list.removeAt(from);
    list.insert(to.clamp(0, list.length), shelf);
    return HomeShelves(order: list, hidden: hidden);
  }

  /// Shows or hides [shelf].
  HomeShelves toggle(HomeShelf shelf, {required bool show}) => HomeShelves(
    order: order,
    hidden: show ? ({...hidden}..remove(shelf)) : {...hidden, shelf},
  );

  /// Serialises the settings.
  Map<String, dynamic> toJson() => {
    'order': [for (final s in order) s.name],
    'hidden': [for (final s in hidden) s.name],
  };
}

/// Holds and persists [HomeShelves].
@Riverpod(keepAlive: true)
class HomeShelvesController extends _$HomeShelvesController {
  /// Preference key.
  static const key = 'home.shelves';

  @override
  HomeShelves build() {
    final raw = ref.watch(preferencesProvider).getString(key);
    if (raw == null) return const HomeShelves();
    try {
      return HomeShelves.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return const HomeShelves();
    }
  }

  /// Applies [change] and saves the result.
  Future<void> update(HomeShelves Function(HomeShelves current) change) async {
    state = change(state);
    await ref.read(preferencesProvider).setString(key, jsonEncode(state));
  }
}

/// The name of [shelf] as shown on Home.
String homeShelfName(AppLocalizations l10n, HomeShelf shelf) => switch (shelf) {
  HomeShelf.life => l10n.lifeTitle,
  HomeShelf.recentlyAdded => l10n.homeRecentlyAdded,
  HomeShelf.mix => l10n.homeMixForYou,
  HomeShelf.recentlyPlayed => l10n.homeRecentlyPlayed,
  HomeShelf.mostPlayed => l10n.homeMostPlayed,
  HomeShelf.forgotten => l10n.homeForgotten,
  HomeShelf.randomAlbums => l10n.homeRandomAlbums,
  HomeShelf.discover => l10n.homeDiscover,
};

/// Settings → Home shelves: turn shelves on or off and drag them around.
class HomeShelvesScreen extends ConsumerWidget {
  /// Creates the screen.
  const HomeShelvesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(homeShelvesControllerProvider);
    final c = ref.read(homeShelvesControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeShelves),
        actions: [
          TextButton(
            onPressed: () => unawaited(c.update((_) => const HomeShelves())),
            child: Text(l10n.homeShelvesReset),
          ),
        ],
      ),
      body: ReorderableListView(
        header: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(l10n.homeShelvesBody),
        ),
        buildDefaultDragHandles: false,
        onReorderItem: (from, to) =>
            unawaited(c.update((s) => s.move(from, to))),
        children: [
          for (final (i, shelf) in s.order.indexed)
            SwitchListTile(
              key: ValueKey(shelf),
              secondary: ReorderableDragStartListener(
                index: i,
                child: Icon(
                  Icons.drag_handle_rounded,
                  semanticLabel: l10n.homeShelvesDrag,
                ),
              ),
              title: Text(homeShelfName(l10n, shelf)),
              subtitle: shelf == HomeShelf.life
                  ? Text(l10n.homeShelvesLifeNote)
                  : null,
              value: !s.hidden.contains(shelf),
              onChanged: (v) =>
                  unawaited(c.update((s) => s.toggle(shelf, show: v))),
            ),
        ],
      ),
    );
  }
}
