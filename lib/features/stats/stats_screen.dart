import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/core/widgets/artwork_image.dart';
import 'package:melody/core/widgets/empty_state.dart';
import 'package:melody/core/widgets/shelf_header.dart';
import 'package:melody/domain/stats/listening_stats.dart';
import 'package:melody/features/stats/stats_providers.dart';
import 'package:melody/features/stats/widgets/hour_chart.dart';
import 'package:melody/l10n/l10n.dart';

/// Listening statistics, computed on the device.
class StatsScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  StatsPeriod _period = StatsPeriod.month;

  static String _label(AppLocalizations l10n, StatsPeriod p) => switch (p) {
    StatsPeriod.month => l10n.statsPeriodMonth,
    StatsPeriod.halfYear => l10n.statsPeriodHalfYear,
    StatsPeriod.year => l10n.statsPeriodYear,
    StatsPeriod.all => l10n.statsPeriodAll,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stats = ref.watch(listeningStatsProvider(_period));
    final year = DateTime.now().year;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                for (final p in StatsPeriod.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_label(l10n, p)),
                      selected: p == _period,
                      onSelected: (_) => setState(() => _period = p),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: FilledButton.tonalIcon(
              onPressed: () => context.push(AppRoutes.wrapIn(context, year)),
              icon: const Icon(Icons.auto_awesome),
              label: Text(l10n.wrapOpen(year)),
            ),
          ),
          switch (stats) {
            AsyncData(:final value) when value.isEmpty => Padding(
              padding: const EdgeInsets.only(top: 48),
              child: EmptyState(
                icon: Icons.insights_outlined,
                title: l10n.statsEmptyTitle,
                message: l10n.statsEmptyBody,
              ),
            ),
            AsyncData(:final value) => _StatsBody(stats: value),
            AsyncError() => Padding(
              padding: const EdgeInsets.only(top: 48),
              child: EmptyState(
                icon: Icons.error_outline,
                title: l10n.errorGenericTitle,
              ),
            ),
            _ => const Padding(
              padding: EdgeInsets.only(top: 64),
              child: Center(child: CircularProgressIndicator()),
            ),
          },
        ],
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats});

  final ListeningStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final busiestDay = stats.busiestDay;
    final weekday = stats.busiestWeekday;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Figure(
                value: formatListened(l10n, stats.listened),
                label: l10n.statsListened,
              ),
              _Figure(value: '${stats.plays}', label: l10n.statsPlays),
              _Figure(
                value: l10n.daysValue(stats.currentStreak),
                label: l10n.statsCurrentStreak,
              ),
              _Figure(
                value: l10n.daysValue(stats.longestStreak),
                label: l10n.statsLongestStreak,
              ),
            ],
          ),
        ),
        if (stats.topArtists.isNotEmpty) ...[
          ShelfHeader(l10n.statsTopArtists),
          for (final (i, a) in stats.topArtists.indexed)
            _RankTile(
              rank: i + 1,
              title: a.item.name,
              subtitle: formatListened(l10n, a.listened),
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              onTap: a.item.id.isEmpty
                  ? null
                  : () => context.push(AppRoutes.artist(context, a.item.id)),
            ),
        ],
        if (stats.topTracks.isNotEmpty) ...[
          ShelfHeader(l10n.statsTopTracks),
          for (final (i, t) in stats.topTracks.indexed)
            _RankTile(
              rank: i + 1,
              title: t.item.title,
              subtitle: '${t.item.artistLine} · ${l10n.playsValue(t.plays)}',
              leading: ArtworkImage(
                artwork: t.item.artwork,
                size: 44,
                radius: 6,
                icon: Icons.music_note_outlined,
              ),
            ),
        ],
        if (stats.topAlbums.isNotEmpty) ...[
          ShelfHeader(l10n.statsTopAlbums),
          for (final (i, a) in stats.topAlbums.indexed)
            _RankTile(
              rank: i + 1,
              title: a.item.name,
              subtitle: formatListened(l10n, a.listened),
              leading: ArtworkImage(
                artwork: stats.albumArtwork[a.item.id],
                size: 44,
                radius: 6,
              ),
              onTap: () => context.push(AppRoutes.album(context, a.item.id)),
            ),
        ],
        if (stats.topGenres.isNotEmpty) ...[
          ShelfHeader(l10n.statsTopGenres),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in stats.topGenres) Chip(label: Text(g.item)),
              ],
            ),
          ),
        ],
        ShelfHeader(l10n.statsByHour),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: HourChart(byHour: stats.byHour),
        ),
        if (busiestDay != null)
          ListTile(
            leading: const Icon(Icons.event_outlined),
            title: Text(l10n.statsBusiestDay),
            subtitle: Text(
              '${DateFormat.yMMMMd(locale).format(busiestDay)} · '
              '${formatListened(l10n, stats.busiestDayListened)}',
            ),
          ),
        if (weekday != null)
          ListTile(
            leading: const Icon(Icons.calendar_view_week_outlined),
            title: Text(l10n.statsBusiestWeekday),
            // 2024-01-01 was a Monday.
            subtitle: Text(
              DateFormat.EEEE(locale).format(DateTime(2024, 1, weekday)),
            ),
          ),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({
    required this.rank,
    required this.title,
    required this.subtitle,
    required this.leading,
    this.onTap,
  });

  final int rank;
  final String title;
  final String subtitle;
  final Widget leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox.square(dimension: 44, child: leading),
        ],
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
