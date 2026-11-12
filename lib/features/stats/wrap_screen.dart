import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:melody/core/config/app_config.dart';
import 'package:melody/core/widgets/artwork_image.dart';
import 'package:melody/core/widgets/empty_state.dart';
import 'package:melody/domain/stats/listening_stats.dart';
import 'package:melody/features/stats/stats_providers.dart';
import 'package:melody/l10n/l10n.dart';

/// The year in review: a few full-screen cards, flipped through like a story.
class WrapScreen extends ConsumerWidget {
  /// Creates the review of [year].
  const WrapScreen({required this.year, super.key});

  /// Calendar year shown.
  final int year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final stats = ref.watch(yearStatsProvider(year));
    return switch (stats) {
      AsyncData(:final value) when !value.isEmpty => _Story(
        year: year,
        stats: value,
      ),
      AsyncData() => Scaffold(
        appBar: AppBar(title: Text(l10n.wrapTitle(year))),
        body: EmptyState(
          icon: Icons.auto_awesome_outlined,
          title: l10n.statsEmptyTitle,
          message: l10n.wrapEmptyBody(year),
        ),
      ),
      AsyncError() => Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.error_outline,
          title: l10n.errorGenericTitle,
        ),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _Story extends StatefulWidget {
  const _Story({required this.year, required this.stats});

  final int year;
  final ListeningStats stats;

  @override
  State<_Story> createState() => _StoryState();
}

class _StoryState extends State<_Story> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int page, int count) {
    if (page < 0) return;
    if (page >= count) {
      Navigator.of(context).maybePop();
      return;
    }
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  List<Widget> _cards(BuildContext context) {
    final l10n = context.l10n;
    final stats = widget.stats;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final topArtist = stats.topArtists.firstOrNull;
    final topTrack = stats.topTracks.firstOrNull;
    final topAlbum = stats.topAlbums.firstOrNull;
    final busiestDay = stats.busiestDay;
    final hour = stats.busiestHour;
    return [
      _Card(
        kicker: AppConfig.appName,
        headline: l10n.wrapTitle(widget.year),
        body: l10n.wrapIntro,
        icon: Icons.auto_awesome,
      ),
      _Card(
        kicker: l10n.wrapListenedKicker,
        headline: l10n.minutesValue(stats.listened.inMinutes),
        body: l10n.wrapListenedBody(stats.plays, stats.activeDays),
        icon: Icons.headphones,
      ),
      if (topArtist != null)
        _Card(
          kicker: l10n.wrapTopArtistKicker,
          headline: topArtist.item.name,
          body: formatListened(l10n, topArtist.listened),
          icon: Icons.mic_external_on,
          lines: [
            for (final (i, a) in stats.topArtists.indexed.skip(1))
              '${i + 1}  ${a.item.name}',
          ],
        ),
      if (topTrack != null)
        _Card(
          kicker: l10n.wrapTopTrackKicker,
          headline: topTrack.item.title,
          body:
              '${topTrack.item.artistLine} · '
              '${l10n.playsValue(topTrack.plays)}',
          cover: ArtworkImage(
            artwork: topTrack.item.artwork,
            size: 160,
            radius: 16,
            icon: Icons.music_note_outlined,
          ),
          lines: [
            for (final (i, t) in stats.topTracks.indexed.skip(1))
              '${i + 1}  ${t.item.title}',
          ],
        ),
      if (topAlbum != null)
        _Card(
          kicker: l10n.wrapTopAlbumKicker,
          headline: topAlbum.item.name,
          body: formatListened(l10n, topAlbum.listened),
          cover: ArtworkImage(
            artwork: stats.albumArtwork[topAlbum.item.id],
            size: 160,
            radius: 16,
          ),
        ),
      if (stats.topGenres.isNotEmpty)
        _Card(
          kicker: l10n.wrapTopGenreKicker,
          headline: stats.topGenres.first.item,
          body: '',
          icon: Icons.sell,
          lines: [
            for (final (i, g) in stats.topGenres.indexed.skip(1))
              '${i + 1}  ${g.item}',
          ],
        ),
      if (busiestDay != null)
        _Card(
          kicker: l10n.statsBusiestDay,
          headline: DateFormat.MMMMd(locale).format(busiestDay),
          body: [
            formatListened(l10n, stats.busiestDayListened),
            if (hour != null)
              l10n.wrapBusiestHour(
                DateFormat.Hm(locale).format(DateTime(2024, 1, 1, hour)),
              ),
          ].join('\n'),
          icon: Icons.event,
        ),
      _Card(
        kicker: l10n.statsLongestStreak,
        headline: l10n.daysValue(stats.longestStreak),
        body: l10n.wrapOutro,
        icon: Icons.local_fire_department,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final cards = _cards(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary,
              Color.lerp(scheme.primary, Colors.black, 0.55)!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 4, 0),
                child: Row(
                  children: [
                    for (var i = 0; i < cards.length; i++)
                      Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: i <= _page ? 1 : 0.3,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: l10n.close,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    PageView(
                      controller: _controller,
                      onPageChanged: (p) => setState(() => _page = p),
                      children: cards,
                    ),
                    // Tap the right or left third to move, like a story.
                    Positioned.fill(
                      child: Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              button: true,
                              label: l10n.previous,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () => _go(_page - 1, cards.length),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Expanded(
                            child: Semantics(
                              button: true,
                              label: l10n.next,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () => _go(_page + 1, cards.length),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One card: small kicker, big headline, a line of detail; slides in.
class _Card extends StatelessWidget {
  const _Card({
    required this.kicker,
    required this.headline,
    required this.body,
    this.icon,
    this.cover,
    this.lines = const [],
  });

  final String kicker;
  final String headline;
  final String body;
  final IconData? icon;
  final Widget? cover;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const white = Colors.white;
    final faded = Colors.white.withValues(alpha: 0.8);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - t)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cover != null) ...[cover!, const SizedBox(height: 28)],
            if (icon != null && cover == null) ...[
              Icon(icon, color: white, size: 56),
              const SizedBox(height: 28),
            ],
            Text(
              kicker.toUpperCase(),
              style: text.labelLarge?.copyWith(
                color: faded,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              headline,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: text.displaySmall?.copyWith(
                color: white,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(body, style: text.titleMedium?.copyWith(color: faded)),
            ],
            if (lines.isNotEmpty) ...[
              const SizedBox(height: 24),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    line,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(color: white),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
