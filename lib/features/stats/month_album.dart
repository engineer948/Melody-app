import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:melody/core/widgets/artwork_image.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/stats/listening_stats.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/share/picture_share.dart';
import 'package:melody/features/stats/life_cards.dart';
import 'package:melody/features/stats/stats_providers.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/history_recorder.dart';
import 'package:melody/player/player_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'month_album.g.dart';

/// A month of listening as an album.
@immutable
class MonthAlbum {
  /// Creates the album.
  const MonthAlbum({
    required this.month,
    required this.stats,
    required this.firsts,
    required this.places,
    required this.photos,
  });

  /// First day of the month.
  final DateTime month;

  /// Its statistics (top 10).
  final ListeningStats stats;

  /// Songs heard for the first time that month.
  final int firsts;

  /// Places music was played at, most first.
  final List<String> places;

  /// Small pictures of up to four photos of the month.
  final List<Uint8List> photos;

  /// The ten songs of the album.
  List<Track> get songs => [for (final t in stats.topTracks) t.item];
}

/// Songs a month needs to make an album.
const monthAlbumMinSongs = 5;

/// The album of the month starting at [month] (its first day).
@riverpod
Future<MonthAlbum?> monthAlbum(Ref ref, DateTime month) async {
  ref.watch(historyRevisionProvider);
  final accountId = ref.watch(
    sessionControllerProvider.select((s) => s.activeId),
  );
  if (accountId == null) return null;
  final store = ref.watch(historyStoreProvider);
  final bridge = ref.watch(placesBridgeProvider);
  final end = DateTime(month.year, month.month + 1);
  final events = await store.events(accountId, from: month, to: end);
  final stats = ListeningStats.of(events, now: end);
  if (stats.topTracks.length < monthAlbumMinSongs) return null;
  final firstPlays = await store.firstPlays(accountId);
  final firsts = firstPlays.values
      .where((t) => !t.isBefore(month) && t.isBefore(end))
      .length;
  final placeCounts = <String, int>{};
  for (final e in events) {
    if (e.place case final p?) {
      placeCounts[p.label] = (placeCounts[p.label] ?? 0) + 1;
    }
  }
  final places = placeCounts.keys.toList()
    ..sort((a, b) => placeCounts[b]!.compareTo(placeCounts[a]!));
  final photos = <Uint8List>[];
  try {
    if (bridge.supported && await bridge.hasPhotos()) {
      // A few photos spread over the month.
      for (final week in [0, 8, 16, 24]) {
        final from = month.add(Duration(days: week));
        if (!from.isBefore(end)) break;
        final found = await bridge.photos(
          from,
          from.add(const Duration(days: 8)),
          limit: 1,
        );
        if (found.isEmpty) continue;
        final bytes = await bridge.thumbnail(found.first.id, size: 540);
        if (bytes != null) photos.add(bytes);
      }
    }
  } on Object {
    // No photos then.
  }
  return MonthAlbum(
    month: month,
    stats: stats,
    firsts: firsts,
    places: places,
    photos: photos,
  );
}

/// Last month, the one shown on Home.
DateTime lastMonth([DateTime? now]) {
  final n = now ?? DateTime.now();
  return DateTime(n.year, n.month - 1);
}

/// "The album of October" on the home shelf.
class MonthAlbumCard extends ConsumerWidget {
  /// Creates the card.
  const MonthAlbumCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final month = lastMonth();
    final album = ref.watch(monthAlbumProvider(month)).value;
    if (album == null) return const SizedBox.shrink();
    return LifePictureCard(
      label: l10n.monthAlbum,
      title: DateFormat.yMMMM(locale).format(month),
      subtitle: l10n.monthAlbumSongs(album.songs.length),
      artwork: album.songs.first.artwork,
      icon: Icons.album_rounded,
      onTap: () => unawaited(showMonthAlbum(context, month)),
    );
  }
}

/// Opens the album of [month].
Future<void> showMonthAlbum(BuildContext context, DateTime month) =>
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(builder: (_) => MonthAlbumScreen(month: month)),
    );

/// A month as an album: a sleeve made of its photos, its ten songs as
/// sides A and B, and liner notes.
class MonthAlbumScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const MonthAlbumScreen({required this.month, super.key});

  /// First day of the month shown first.
  final DateTime month;

  @override
  ConsumerState<MonthAlbumScreen> createState() => _MonthAlbumScreenState();
}

class _MonthAlbumScreenState extends ConsumerState<MonthAlbumScreen> {
  late DateTime _month = widget.month;
  final GlobalKey _poster = GlobalKey();

  void _move(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  Future<void> _share(BuildContext button) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.l10n.shareFailed;
    try {
      await sharePicture(
        _poster,
        name: 'melody-month',
        origin: shareOrigin(button),
      );
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final album = ref.watch(monthAlbumProvider(_month));
    final now = DateTime.now();
    final isCurrent = _month.year == now.year && _month.month == now.month;
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat.yMMMM(locale).format(_month)),
        actions: [
          IconButton(
            tooltip: l10n.monthPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => _move(-1),
          ),
          IconButton(
            tooltip: l10n.monthNext,
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: isCurrent ? null : () => _move(1),
          ),
          if (album.value != null)
            Builder(
              builder: (button) => IconButton(
                tooltip: l10n.share,
                icon: const Icon(Icons.ios_share_rounded),
                onPressed: () => unawaited(_share(button)),
              ),
            ),
        ],
      ),
      body: switch (album) {
        AsyncData(value: null) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(l10n.monthAlbumEmpty, textAlign: TextAlign.center),
          ),
        ),
        AsyncData(:final value?) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            RepaintBoundary(
              key: _poster,
              child: _AlbumPoster(album: value),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => unawaited(
                ref
                    .read(playerControllerProvider.notifier)
                    .playTracks(value.songs),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l10n.play),
            ),
          ],
        ),
        AsyncError() => Center(child: Text(l10n.errorGenericTitle)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _AlbumPoster extends StatelessWidget {
  const _AlbumPoster({required this.album});

  final MonthAlbum album;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final theme = Theme.of(context);
    final songs = album.songs;
    final half = (songs.length / 2).ceil();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF15131A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.25,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final side = box.maxHeight;
                    return Stack(
                      children: [
                        // The record sliding out of the sleeve.
                        Positioned(
                          left: side * 0.28,
                          top: side * 0.04,
                          child: _Record(size: side * 0.92),
                        ),
                        SizedBox.square(
                          dimension: side,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: _Sleeve(album: album),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Text(
                DateFormat.yMMMM(locale).format(album.month).toUpperCase(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                [
                  formatListened(l10n, album.stats.listened),
                  if (album.firsts > 0) l10n.monthAlbumFirsts(album.firsts),
                  if (album.places.isNotEmpty) '📍 ${album.places.first}',
                ].join(' · '),
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              for (final (i, song) in songs.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text(
                          i < half ? 'A${i + 1}' : 'B${i - half + 1}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${song.title} — ${song.artistLine}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              const Text(
                'Melody',
                style: TextStyle(color: Colors.white38, letterSpacing: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The sleeve: the month's photos (or covers of its songs) in a grid.
class _Sleeve extends StatelessWidget {
  const _Sleeve({required this.album});

  final MonthAlbum album;

  @override
  Widget build(BuildContext context) {
    final photos = album.photos;
    final tiles = <Widget>[
      for (final p in photos) Image.memory(p, fit: BoxFit.cover),
      for (final song in album.songs)
        if (song.artwork != null)
          ArtworkImage(artwork: song.artwork, radius: 0),
    ].take(4).toList();
    if (tiles.isEmpty) {
      return ColoredBox(color: Theme.of(context).colorScheme.primary);
    }
    if (tiles.length < 4) return SizedBox.expand(child: tiles.first);
    return GridView.count(
      crossAxisCount: 2,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: tiles,
    );
  }
}

class _Record extends StatelessWidget {
  const _Record({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          Color(0xFFE8505B),
          Color(0xFFE8505B),
          Color(0xFF111111),
          Color(0xFF2A2A2A),
          Color(0xFF111111),
        ],
        stops: [0, 0.3, 0.31, 0.7, 1],
      ),
    ),
  );
}
