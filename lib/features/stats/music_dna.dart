import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/domain/stats/listening_stats.dart';
import 'package:melody/features/share/picture_share.dart';
import 'package:melody/features/stats/stats_providers.dart';
import 'package:melody/l10n/l10n.dart';

/// A stable colour for [name] (a genre or artist).
Color dnaColor(String name) {
  var hash = 7;
  for (final unit in name.toLowerCase().codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return HSLColor.fromAHSL(1, (hash % 360).toDouble(), 0.75, 0.6).toColor();
}

/// Opens the music DNA poster of [period].
Future<void> showMusicDna(BuildContext context, StatsPeriod period) =>
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => MusicDnaScreen(period: period),
      ),
    );

/// "Your music DNA": a picture drawn from the listening statistics, the
/// same for the same listening and different for everyone.
class MusicDnaScreen extends ConsumerStatefulWidget {
  /// Creates the screen for [period].
  const MusicDnaScreen({required this.period, super.key});

  /// Which statistics.
  final StatsPeriod period;

  @override
  ConsumerState<MusicDnaScreen> createState() => _MusicDnaScreenState();
}

class _MusicDnaScreenState extends ConsumerState<MusicDnaScreen> {
  final GlobalKey _poster = GlobalKey();
  var _busy = false;

  Future<void> _share(BuildContext button) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.l10n.shareFailed;
    setState(() => _busy = true);
    try {
      await sharePicture(
        _poster,
        name: 'melody-dna',
        origin: shareOrigin(button),
      );
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stats = ref.watch(listeningStatsProvider(widget.period)).value;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l10n.dnaTitle),
        actions: [
          Builder(
            builder: (button) => IconButton(
              tooltip: l10n.share,
              icon: const Icon(Icons.ios_share_rounded),
              onPressed: _busy || stats == null || stats.isEmpty
                  ? null
                  : () => unawaited(_share(button)),
            ),
          ),
        ],
      ),
      body: stats == null
          ? const Center(child: CircularProgressIndicator())
          : stats.isEmpty
          ? Center(
              child: Text(
                l10n.statsEmptyTitle,
                style: const TextStyle(color: Colors.white70),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: FittedBox(
                    child: RepaintBoundary(
                      key: _poster,
                      child: SizedBox(
                        width: 360,
                        height: 640,
                        child: DnaPoster(stats: stats),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/// The poster: the drawing, then what it is made of.
class DnaPoster extends StatelessWidget {
  /// Creates the poster of [stats].
  const DnaPoster({required this.stats, super.key});

  /// What it is drawn from.
  final ListeningStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hour = stats.busiestHour;
    final artist = stats.topArtists.firstOrNull?.item.name;
    return ColoredBox(
      color: const Color(0xFF0B0B12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white, fontSize: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dnaTitle.toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  letterSpacing: 3,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatListened(l10n, stats.listened),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Expanded(
                child: CustomPaint(
                  painter: DnaPainter(stats),
                  size: Size.infinite,
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  for (final g in stats.topGenres.take(5))
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: dnaColor(g.item),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(g.item),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (artist != null) Text('♥ $artist'),
              if (hour != null)
                Text(
                  l10n.dnaHour(hour.toString().padLeft(2, '0')),
                  style: const TextStyle(color: Colors.white70),
                ),
              const SizedBox(height: 8),
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

/// Draws the statistics as a double helix wound around a 24-hour clock:
/// the rungs are the hours (longer when more was played then), coloured
/// by genre share; the beads are the top songs, bigger when played more.
class DnaPainter extends CustomPainter {
  /// Creates the painter.
  DnaPainter(this.stats);

  /// What is drawn.
  final ListeningStats stats;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = min(size.width, size.height) / 2 * 0.9;
    final seed = stats.plays * 31 + stats.listened.inMinutes;
    final random = Random(seed);

    // Genre colours by share, used around the circle.
    final genres = stats.topGenres.take(6).toList();
    final total = genres.fold<int>(0, (n, g) => n + g.plays);
    final palette = <Color>[];
    for (final g in genres) {
      final n = total == 0 ? 1 : max(1, (g.plays * 48 / total).round());
      palette.addAll(List.filled(n, dnaColor(g.item)));
    }
    if (palette.isEmpty) palette.add(const Color(0xFF8E9BFF));

    // Hours: rays from an inner ring.
    final most = stats.byHour.isEmpty
        ? Duration.zero
        : stats.byHour.reduce((a, b) => a > b ? a : b);
    for (var h = 0; h < 24; h++) {
      final share = most == Duration.zero || stats.byHour.length < 24
          ? 0.0
          : stats.byHour[h].inSeconds / most.inSeconds;
      final angle = -pi / 2 + h * 2 * pi / 24;
      final dir = Offset(cos(angle), sin(angle));
      final from = center + dir * radius * 0.28;
      final to = center + dir * radius * (0.3 + 0.35 * share);
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = palette[h * palette.length ~/ 24].withValues(alpha: 0.8)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }

    // The helix: two strands winding around the circle.
    const turns = 5;
    const steps = 240;
    final strandA = Path();
    final strandB = Path();
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final angle = -pi / 2 + t * 2 * pi;
      final wave = sin(t * turns * 2 * pi);
      final r1 = radius * (0.78 + 0.1 * wave);
      final r2 = radius * (0.78 - 0.1 * wave);
      final p1 = center + Offset(cos(angle), sin(angle)) * r1;
      final p2 = center + Offset(cos(angle), sin(angle)) * r2;
      if (i == 0) {
        strandA.moveTo(p1.dx, p1.dy);
        strandB.moveTo(p2.dx, p2.dy);
      } else {
        strandA.lineTo(p1.dx, p1.dy);
        strandB.lineTo(p2.dx, p2.dy);
      }
      if (i % 4 == 0) {
        canvas.drawLine(
          p1,
          p2,
          Paint()
            ..color = palette[i * palette.length ~/ (steps + 1)].withValues(
              alpha: 0.55,
            )
            ..strokeWidth = 1.5,
        );
      }
    }
    final strand = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white70;
    canvas
      ..drawPath(strandA, strand)
      ..drawPath(strandB, strand);

    // Beads: the top songs, scattered on the helix.
    final tracks = stats.topTracks.take(10).toList();
    final mostPlays = tracks.isEmpty ? 1 : tracks.first.plays;
    for (final (i, t) in tracks.indexed) {
      final angle = -pi / 2 + (i + random.nextDouble() * 0.6) * 2 * pi / 10;
      final r = radius * (0.78 + (random.nextBool() ? 0.1 : -0.1));
      final p = center + Offset(cos(angle), sin(angle)) * r;
      final size = 3 + 7 * sqrt(t.plays / max(1, mostPlays));
      canvas
        ..drawCircle(
          p,
          size * 2.2,
          Paint()
            ..color = palette[i * palette.length ~/ 10].withValues(alpha: 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        )
        ..drawCircle(p, size, Paint()..color = Colors.white);
    }

    // The heart: streak days as a small ring of dots.
    final days = min(stats.longestStreak, 60);
    for (var d = 0; d < days; d++) {
      final angle = -pi / 2 + d * 2 * pi / max(days, 1);
      canvas.drawCircle(
        center + Offset(cos(angle), sin(angle)) * radius * 0.16,
        1.6,
        Paint()..color = Colors.white54,
      );
    }
  }

  @override
  bool shouldRepaint(DnaPainter old) => old.stats != stats;
}
