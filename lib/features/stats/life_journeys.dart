import 'dart:async';
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
