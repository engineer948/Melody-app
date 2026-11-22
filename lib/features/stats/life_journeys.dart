import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:melody/core/widgets/artwork_image.dart';
import 'package:melody/core/widgets/shelf_header.dart';
import 'package:melody/data/places/places_bridge.dart';
import 'package:melody/domain/stats/life_places.dart';
import 'package:melody/domain/stats/play_event.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/stats/life_cards.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/history_recorder.dart';
import 'package:melody/player/player_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'life_journeys.g.dart';

/// Every play of the active account with a place.
@riverpod
Future<List<PlayEvent>> placedEvents(Ref ref) async {
  ref.watch(historyRevisionProvider);
  final accountId = ref.watch(
    sessionControllerProvider.select((s) => s.activeId),
  );
  if (accountId == null) return const [];
  return await ref.watch(historyStoreProvider).placedEvents(accountId);
}

/// Trips away from home, newest first.
@riverpod
Future<List<Trip>> trips(Ref ref) async =>
    findTrips(await ref.watch(placedEventsProvider.future));

/// Places music was played at, in the order first visited.
@riverpod
Future<List<PlaceStar>> stars(Ref ref) async =>
    placeStars(await ref.watch(placedEventsProvider.future));

/// A big picture of photo [id] for the replay.
@riverpod
Future<Uint8List?> photoLarge(Ref ref, int id) =>
    ref.watch(placesBridgeProvider).thumbnail(id, size: 1080);

/// Plays the days [from]–[to] again in their order, with their photos.
Future<void> showReplay(
  BuildContext context, {
  required DateTime from,
  required DateTime to,
  required String title,
}) => Navigator.of(context, rootNavigator: true).push(
  MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => ReplayScreen(from: from, to: to, title: title),
  ),
);

/// "Live this day again": the songs of the days in order, the photos of
/// those days slowly passing behind them.
class ReplayScreen extends ConsumerStatefulWidget {
  /// Creates the screen for the days [from] to [to] (midnights).
  const ReplayScreen({
    required this.from,
    required this.to,
    required this.title,
    super.key,
  });

  /// First day.
  final DateTime from;

  /// Last day.
  final DateTime to;

  /// Shown at the top.
  final String title;

  @override
  ConsumerState<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends ConsumerState<ReplayScreen> {
  List<GalleryPhoto> _photos = const [];
  Map<String, PlayEvent> _firstEvent = const {};
  var _photo = 0;
  var _loaded = false;
  var _empty = false;
  Timer? _timer;

  DateTime get _end => widget.to.add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final accountId = ref.read(sessionControllerProvider).activeId;
    if (accountId == null) return;
    final events = await ref
        .read(historyStoreProvider)
        .events(accountId, from: widget.from, to: _end);
    final songs = playedInOrder(events);
    final bridge = ref.read(placesBridgeProvider);
    var photos = const <GalleryPhoto>[];
    try {
      if (bridge.supported && await bridge.hasPhotos()) {
        photos = await bridge.photos(widget.from, _end, limit: 40);
      }
    } on Object {
      // No photos then.
    }
    if (!mounted) return;
    setState(() {
      _loaded = true;
      _empty = songs.isEmpty;
      _photos = photos;
      _firstEvent = {for (final e in events.reversed) e.track.id: e};
    });
    if (photos.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 7), (_) {
        if (mounted) setState(() => _photo = (_photo + 1) % _photos.length);
      });
    }
    if (songs.isNotEmpty) {
      await ref.read(playerControllerProvider.notifier).playTracks(songs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final track = ref.watch(playerControllerProvider.select((s) => s.current));
    final event = track == null ? null : _firstEvent[track.id];
    final photo = _photos.isEmpty ? null : _photos[_photo];
    final bytes = photo == null
        ? null
        : ref.watch(photoLargeProvider(photo.id)).value;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 1600),
            child: bytes != null
                ? _SlowZoom(
                    key: ValueKey(photo!.id),
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                  )
                : track?.artwork != null
                ? _SlowZoom(
                    key: ValueKey(track!.id),
                    child: Opacity(
                      opacity: 0.6,
                      child: ArtworkImage(artwork: track.artwork, radius: 0),
                    ),
                  )
                : const SizedBox.expand(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x88000000),
                  Color(0x00000000),
                  Color(0xDD000000),
                ],
                stops: [0, 0.4, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 20, 24),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          color: Colors.white,
                          tooltip: MaterialLocalizations.of(context)
                              .closeButtonTooltip,
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (!_loaded)
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    else if (_empty)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(l10n.replayEmpty),
                      )
                    else if (track != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (event != null)
                              Text(
                                [
                                  DateFormat.MMMMEEEEd(locale)
                                      .add_Hm()
                                      .format(event.startedAt),
                                  ?event.place?.label,
                                ].join(' · '),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            const SizedBox(height: 6),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 600),
                              child: Text(
                                track.title,
                                key: ValueKey(track.id),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              track.artistLine,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slowly zooms into its child (a "Ken Burns" effect).
class _SlowZoom extends StatefulWidget {
  const _SlowZoom({required this.child, super.key});

  final Widget child;

  @override
  State<_SlowZoom> createState() => _SlowZoomState();
}

class _SlowZoomState extends State<_SlowZoom>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: Tween<double>(
      begin: 1,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
    child: widget.child,
  );
}

/// Trips on the soundtrack screen.
class TripsShelf extends ConsumerWidget {
  /// Creates the shelf.
  const TripsShelf({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final trips = ref.watch(tripsProvider).value ?? const [];
    if (trips.isEmpty) return const SizedBox.shrink();
    final dates = DateFormat.MMMd(locale);
    final year = DateFormat.y(locale);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShelfHeader(l10n.tripsTitle),
        SizedBox(
          height: 170,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final trip in trips.take(20))
                LifePictureCard(
                  artwork: trip.songs.firstOrNull?.artwork,
                  label: trip.days == 1
                      ? '${dates.format(trip.from)} ${year.format(trip.from)}'
                      : '${dates.format(trip.from)} – '
                            '${dates.format(trip.to)} ${year.format(trip.to)}',
                  title: '📍 ${trip.place}',
                  subtitle:
                      '${l10n.tripDays(trip.days)} · '
                      '${l10n.tripSongCount(trip.songs.length)}',
                  icon: Icons.play_circle_outline_rounded,
                  onTap: () => unawaited(
                    showReplay(
                      context,
                      from: trip.from,
                      to: trip.to,
                      title: trip.place,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Opens the star map of places.
Future<void> showStarMap(BuildContext context) => Navigator.of(
  context,
  rootNavigator: true,
).push(MaterialPageRoute<void>(builder: (_) => const StarMapScreen()));

/// Every place music was played at as a star; lines join them in the
/// order they were first visited, like a constellation.
class StarMapScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const StarMapScreen({super.key});

  @override
  ConsumerState<StarMapScreen> createState() => _StarMapScreenState();
}

class _StarMapScreenState extends ConsumerState<StarMapScreen>
    with SingleTickerProviderStateMixin {
  late final _twinkle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _twinkle.dispose();
    super.dispose();
  }

  void _open(PlaceStar star) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(star.name, style: Theme.of(context).textTheme.titleLarge),
                Text(
                  l10n.starFirst(
                    DateFormat.yMMMMd(locale).format(star.firstVisit),
                    star.plays,
                  ),
                ),
                const SizedBox(height: 8),
                for (final song in star.songs.take(5))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ArtworkImage(
                      artwork: song.artwork,
                      size: 40,
                      radius: 6,
                      icon: Icons.music_note_outlined,
                    ),
                    title: Text(song.title, maxLines: 1),
                    subtitle: Text(song.artistLine, maxLines: 1),
                  ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: star.songs.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context);
                          unawaited(
                            ref
                                .read(playerControllerProvider.notifier)
                                .playTracks(star.songs),
                          );
                        },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.placePlay),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stars = ref.watch(starsProvider).value;
    return Scaffold(
      backgroundColor: const Color(0xFF070B1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(l10n.starMap),
      ),
      body: switch (stars) {
        null => const Center(child: CircularProgressIndicator()),
        [] => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              l10n.starEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
        final stars => LayoutBuilder(
          builder: (context, box) {
            final size = box.biggest;
            final points = starPositions(stars, size);
            return InteractiveViewer(
              maxScale: 8,
              child: GestureDetector(
                onTapUp: (d) {
                  var best = -1;
                  var bestDist = 28.0;
                  for (var i = 0; i < points.length; i++) {
                    final dist = (points[i] - d.localPosition).distance;
                    if (dist < bestDist) {
                      best = i;
                      bestDist = dist;
                    }
                  }
                  if (best >= 0) _open(stars[best]);
                },
                child: AnimatedBuilder(
                  animation: _twinkle,
                  builder: (context, _) => CustomPaint(
                    size: size,
                    painter: _StarsPainter(
                      stars: stars,
                      points: points,
                      phase: _twinkle.value,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      },
    );
  }
}

/// Positions of [stars] inside [size]: longitude and latitude stretched
/// to fill it. Places very close together are spread on a small circle
/// so each stays visible.
List<Offset> starPositions(List<PlaceStar> stars, Size size) {
  if (stars.isEmpty) return const [];
  final meanLat =
      stars.map((s) => s.latitude).reduce((a, b) => a + b) / stars.length;
  final k = cos(meanLat * pi / 180);
  final xs = [for (final s in stars) s.longitude * k];
  final ys = [for (final s in stars) -s.latitude];
  final minX = xs.reduce(min);
  final maxX = xs.reduce(max);
  final minY = ys.reduce(min);
  final maxY = ys.reduce(max);
  const pad = 48.0;
  final w = size.width - 2 * pad;
  final h = size.height - 2 * pad;
  final spanX = max(maxX - minX, 1e-6);
  final spanY = max(maxY - minY, 1e-6);
  final scale = min(w / spanX, h / spanY);
  final offX = pad + (w - spanX * scale) / 2;
  final offY = pad + (h - spanY * scale) / 2;
  final points = <Offset>[];
  for (var i = 0; i < stars.length; i++) {
    var p = stars.length == 1
        ? Offset(size.width / 2, size.height / 2)
        : Offset(offX + (xs[i] - minX) * scale, offY + (ys[i] - minY) * scale);
    // Keep stars apart.
    for (var tries = 0; tries < 12; tries++) {
      if (points.every((q) => (q - p).distance >= 14)) break;
      final angle = (i * 2.4) + tries;
      p = p + Offset(cos(angle), sin(angle)) * 14;
    }
    points.add(p);
  }
  return points;
}

class _StarsPainter extends CustomPainter {
  _StarsPainter({
    required this.stars,
    required this.points,
    required this.phase,
  });

  final List<PlaceStar> stars;
  final List<Offset> points;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    // Faint background stars.
    final rnd = Random(7);
    final dust = Paint()..color = const Color(0x33FFFFFF);
    for (var i = 0; i < 120; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        rnd.nextDouble() * 1.2,
        dust,
      );
    }
    // The constellation, in the order the places were found.
    final line = Paint()
      ..color = const Color(0x55A7C4FF)
      ..strokeWidth = 1;
    for (var i = 1; i < points.length; i++) {
      canvas.drawLine(points[i - 1], points[i], line);
    }
    final most = stars.map((s) => s.plays).reduce(max);
    for (var i = 0; i < stars.length; i++) {
      final r = 2.5 + 7 * sqrt(stars[i].plays / most);
      final glow = 0.6 + 0.4 * sin((phase + i * 0.37) * 2 * pi);
      canvas
        ..drawCircle(
          points[i],
          r * 3,
          Paint()
            ..color = Color.fromRGBO(167, 196, 255, 0.12 * glow)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        )
        ..drawCircle(
          points[i],
          r,
          Paint()..color = Color.fromRGBO(255, 255, 255, 0.7 + 0.3 * glow),
        );
    }
    // Names of the brightest places.
    final order = List.generate(stars.length, (i) => i)
      ..sort((a, b) => stars[b].plays.compareTo(stars[a].plays));
    for (final i in order.take(8)) {
      TextPainter(
          text: TextSpan(
            text: stars[i].name,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )
        ..layout(maxWidth: 140)
        ..paint(canvas, points[i] + const Offset(10, -6));
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) =>
      old.phase != phase || old.stars != stars;
}
