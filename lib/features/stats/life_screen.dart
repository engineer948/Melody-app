import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/core/widgets/artwork_image.dart';
import 'package:melody/core/widgets/empty_state.dart';
import 'package:melody/core/widgets/large_title_page.dart';
import 'package:melody/core/widgets/shelf_header.dart';
import 'package:melody/data/places/places_bridge.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/stats/life_days.dart';
import 'package:melody/domain/stats/place_memory.dart';
import 'package:melody/domain/stats/play_event.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/library/widgets/media_tiles.dart';
import 'package:melody/features/library/widgets/paged_scroll_view.dart';
import 'package:melody/features/stats/stats_providers.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/history_recorder.dart';
import 'package:melody/player/listening_settings.dart';
import 'package:melody/player/player_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'life_screen.g.dart';

/// Days shown on the "soundtrack of your life" screen.
const lifeSpan = Duration(days: 180);

/// The last [lifeSpan] of the active account, day by day.
@riverpod
Future<List<LifeDay>> lifeTimeline(Ref ref) async {
  ref.watch(historyRevisionProvider);
  final accountId = ref.watch(
    sessionControllerProvider.select((s) => s.activeId),
  );
  if (accountId == null) return const [];
  final store = ref.watch(historyStoreProvider);
  final from = DateTime.now().subtract(lifeSpan);
  final events = await store.events(accountId, from: from);
  return lifeDays(events, await store.firstPlays(accountId));
}

/// The same calendar day 1 to 5 years ago, when music was played then,
/// as (years ago, day), most recent first.
@riverpod
Future<List<(int, LifeDay)>> onThisDay(Ref ref) async {
  ref.watch(historyRevisionProvider);
  final accountId = ref.watch(
    sessionControllerProvider.select((s) => s.activeId),
  );
  if (accountId == null) return const [];
  final store = ref.watch(historyStoreProvider);
  final now = DateTime.now();
  Map<String, DateTime>? firsts;
  final found = <(int, LifeDay)>[];
  for (var years = 1; years <= 5; years++) {
    final day = DateTime(now.year - years, now.month, now.day);
    // 29 February does not exist every year.
    if (day.month != now.month) continue;
    final events = await store.events(
      accountId,
      from: day,
      to: day.add(const Duration(days: 1)),
    );
    if (events.isEmpty) continue;
    firsts ??= await store.firstPlays(accountId);
    found.add((years, lifeDays(events, firsts).single));
  }
  return found;
}

/// Preference prefix: when a place was last brought up.
const placeReminderKey = 'life.placeReminder.';

/// How long a place stays quiet after being brought up.
const placeReminderPause = Duration(days: 7);

/// What was played the last time at the place the phone is now, when the
/// user is back after a while; `null` otherwise. Asked again when the app
/// comes back to the foreground.
@riverpod
Future<PlaceMemory?> placeMemory(Ref ref) async {
  final settings = ref.watch(listeningSettingsControllerProvider);
  if (!settings.places || !settings.placeReminders) return null;
  final accountId = ref.watch(
    sessionControllerProvider.select((s) => s.activeId),
  );
  final bridge = ref.watch(placesBridgeProvider);
  if (accountId == null || !bridge.supported) return null;
  if (!await bridge.hasLocation()) return null;
  ({double latitude, double longitude})? here;
  try {
    here = await bridge.location().timeout(const Duration(seconds: 8));
  } on Object {
    return null;
  }
  if (here == null) return null;
  final events = await ref
      .read(historyStoreProvider)
      .eventsNear(accountId, here.latitude, here.longitude);
  final now = DateTime.now();
  final memory = findPlaceMemory(
    events,
    latitude: here.latitude,
    longitude: here.longitude,
    now: now,
  );
  if (memory == null) return null;
  final prefs = ref.read(preferencesProvider);
  final shown = DateTime.tryParse(
    prefs.getString('$placeReminderKey${memory.key}') ?? '',
  );
  if (shown != null && now.difference(shown) < placeReminderPause) {
    return null;
  }
  // Brought up once: quiet for a week from now on.
  await prefs.setString(
    '$placeReminderKey${memory.key}',
    now.toIso8601String(),
  );
  return memory;
}

/// Hides the place reminder until the app is opened again.
@Riverpod(keepAlive: true)
class PlaceMemoryDismissed extends _$PlaceMemoryDismissed {
  @override
  bool build() => false;

  /// Hides it.
  void dismiss() => state = true;

  /// Shows it again when there is one (the app came back).
  void reset() => state = false;
}

/// "You are back here: last time you played …" at the top of Home.
class PlaceMemoryBanner extends ConsumerWidget {
  /// Creates the banner.
  const PlaceMemoryBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(placeMemoryDismissedProvider)) return const SizedBox.shrink();
    final memory = ref.watch(placeMemoryProvider).value;
    if (memory == null || memory.songs.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final song = memory.songs.first;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primaryContainer, scheme.tertiaryContainer],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.placeBack(memory.place.label),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context)
                        .closeButtonTooltip,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => ref
                        .read(placeMemoryDismissedProvider.notifier)
                        .dismiss(),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  l10n.placeLastTime(
                    DateFormat.yMMMMd(locale).format(memory.day),
                    song.title,
                    song.artistLine,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ArtworkImage(
                    artwork: song.artwork,
                    size: 40,
                    radius: 6,
                    icon: Icons.music_note_outlined,
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () {
                      ref.read(placeMemoryDismissedProvider.notifier).dismiss();
                      unawaited(
                        ref
                            .read(playerControllerProvider.notifier)
                            .playTracks(memory.songs),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(l10n.placePlay),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// First play of a song and how often it was played.
@riverpod
Future<({PlayEvent first, int plays})?> trackMemory(
  Ref ref,
  String trackId,
) async {
  ref.watch(historyRevisionProvider);
  final accountId = ref.watch(
    sessionControllerProvider.select((s) => s.activeId),
  );
  if (accountId == null) return null;
  return await ref.watch(historyStoreProvider).memoryOf(accountId, trackId);
}

/// Photos taken on [day] (only when allowed).
@riverpod
Future<List<GalleryPhoto>> dayPhotos(Ref ref, DateTime day) async {
  final bridge = ref.watch(placesBridgeProvider);
  if (!bridge.supported || !await bridge.hasPhotos()) return const [];
  return await bridge.photos(day, day.add(const Duration(days: 1)), limit: 10);
}

/// A small picture of photo [id].
@riverpod
Future<Uint8List?> photoThumb(Ref ref, int id) =>
    ref.watch(placesBridgeProvider).thumbnail(id, size: 240);

/// Whether photos may be shown.
@riverpod
Future<bool> photosAllowed(Ref ref) async {
  final bridge = ref.watch(placesBridgeProvider);
  return bridge.supported && await bridge.hasPhotos();
}

/// Turns "soundtrack of your life" on (asking for rough location) or off.
Future<void> setLifeSoundtrack(
  BuildContext context,
  WidgetRef ref, {
  required bool on,
}) async {
  final settings = ref.read(listeningSettingsControllerProvider.notifier);
  if (!on) {
    await settings.update((s) => s.copyWith(places: false));
    return;
  }
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final allowed = await ref.read(placesBridgeProvider).requestLocation();
  if (!allowed) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.lifeNoLocation)));
    return;
  }
  await settings.update((s) => s.copyWith(places: true, history: true));
}

/// "Soundtrack of your life": every day with its places, songs, first
/// listens and the photos taken that day.
class LifeScreen extends ConsumerWidget {
  /// Creates the screen.
  const LifeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final enabled = ref.watch(
      listeningSettingsControllerProvider.select((s) => s.places),
    );
    final supported = ref.watch(placesBridgeProvider).supported;
    final photos = ref.watch(photosAllowedProvider).value ?? false;
    final days = ref.watch(lifeTimelineProvider);
    return Scaffold(
      body: LargeTitlePage(
        title: l10n.lifeTitle,
        onRefresh: () async => ref
          ..invalidate(lifeTimelineProvider)
          ..invalidate(dayPhotosProvider),
        slivers: [
          SliverToBoxAdapter(
            child: _Intro(
              enabled: enabled,
              supported: supported,
              photos: photos,
            ),
          ),
          ...loadedSlivers(
            value: days,
            onRetry: () => ref.invalidate(lifeTimelineProvider),
            builder: (days) => [
              if (days.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.auto_stories_outlined,
                    title: l10n.lifeEmpty,
                  ),
                )
              else
                SliverList.builder(
                  itemCount: days.length,
                  itemBuilder: (context, i) =>
                      _DayCard(day: days[i], photos: photos),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Intro extends ConsumerWidget {
  const _Intro({
    required this.enabled,
    required this.supported,
    required this.photos,
  });

  final bool enabled;
  final bool supported;
  final bool photos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.lifeBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (supported) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.place_outlined),
              title: Text(l10n.lifePlaces),
              subtitle: Text(l10n.lifePlacesBody),
              value: enabled,
              onChanged: (on) =>
                  unawaited(setLifeSoundtrack(context, ref, on: on)),
            ),
            if (!photos)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.lifePhotos),
                subtitle: Text(l10n.lifePhotosBody),
                onTap: () async {
                  await ref.read(placesBridgeProvider).requestPhotos();
                  ref
                    ..invalidate(photosAllowedProvider)
                    ..invalidate(dayPhotosProvider);
                },
              ),
          ],
        ],
      ),
    );
  }
}

class _DayCard extends ConsumerWidget {
  const _DayCard({required this.day, required this.photos});

  final LifeDay day;
  final bool photos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final shown = day.songs.take(5).toList();
    final queue = [for (final (t, _) in day.songs) t];
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                DateFormat.yMMMMEEEEd(locale).format(day.day),
                style: theme.textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
              child: Text(
                formatListened(l10n, day.listened),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (day.places.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final place in day.places.take(4))
                      Chip(
                        avatar: const Icon(Icons.place_rounded, size: 16),
                        label: Text(place),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
            if (photos) _DayPhotos(day: day.day),
            const SizedBox(height: 4),
            for (final (track, plays) in shown)
              TrackTile(
                track: track,
                queue: queue,
                index: queue.indexOf(track),
                badge: day.firsts.contains(track.id)
                    ? l10n.lifeFirst
                    : (plays > 1 ? l10n.lifePlays(plays) : null),
              ),
            if (day.songs.length > shown.length)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.mixtapeMore(day.songs.length - shown.length),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayPhotos extends ConsumerWidget {
  const _DayPhotos({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(dayPhotosProvider(day)).value ?? const [];
    if (photos.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        itemCount: photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) => _Thumb(id: photos[i].id),
      ),
    );
  }
}

class _Thumb extends ConsumerWidget {
  const _Thumb({required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = ref.watch(photoThumbProvider(id)).value;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(
        dimension: 86,
        child: bytes == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
              )
            : Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
      ),
    );
  }
}

/// When and where [track] was first heard, with the photos of that day.
Future<void> showTrackMemory(BuildContext context, Track track) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => _TrackMemorySheet(track: track),
    );

class _TrackMemorySheet extends ConsumerWidget {
  const _TrackMemorySheet({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final memory = ref.watch(trackMemoryProvider(track.id));
    final photos = ref.watch(photosAllowedProvider).value ?? false;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: switch (memory) {
          AsyncData(value: null) => Text(l10n.lifeNeverHeard),
          AsyncData(:final value?) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(track.title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.auto_awesome_rounded),
                title: Text(
                  l10n.lifeFirstHeard(
                    DateFormat.yMMMMd(locale).format(value.first.startedAt),
                  ),
                ),
                subtitle: Text(value.first.place?.label ?? l10n.lifeNoPlace),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.repeat_rounded),
                title: Text(l10n.lifeTimesPlayed(value.plays)),
              ),
              if (photos)
                _DayPhotos(
                  day: DateTime(
                    value.first.startedAt.year,
                    value.first.startedAt.month,
                    value.first.startedAt.day,
                  ),
                ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  unawaited(context.push(AppRoutes.lifeIn(context)));
                },
                icon: const Icon(Icons.auto_stories_outlined),
                label: Text(l10n.lifeTitle),
              ),
            ],
          ),
          AsyncError() => Text(l10n.lifeNeverHeard),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

/// A small "first heard 2 years ago in Baku" line for the full player,
/// shown for songs first heard at least a month ago when places are kept.
class TrackMemoryLine extends ConsumerWidget {
  /// Creates the line for [track].
  const TrackMemoryLine({required this.track, super.key});

  /// Song playing.
  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      listeningSettingsControllerProvider.select((s) => s.places),
    );
    if (!enabled) return const SizedBox.shrink();
    final memory = ref.watch(trackMemoryProvider(track.id)).value;
    final first = memory?.first;
    if (first == null ||
        DateTime.now().difference(first.startedAt) < const Duration(days: 30)) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final when = DateFormat.yMMMd(locale).format(first.startedAt);
    final place = first.place?.name;
    return GestureDetector(
      onTap: () => unawaited(showTrackMemory(context, track)),
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            const Icon(Icons.history_rounded, size: 14, color: Colors.white60),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                place == null
                    ? l10n.lifeMemoryLine(when)
                    : l10n.lifeMemoryLinePlace(when, place),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Days of listening before the home screen asks about the shelf.
const lifeAskAfterDays = 3;

/// Home screen shelf: "on this day" years ago, then the latest days. Off
/// until the user says yes to the one-time question (or in Settings).
class LifeShelf extends ConsumerWidget {
  /// Creates the shelf.
  const LifeShelf({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(listeningSettingsControllerProvider);
    if (!settings.lifeAsked) {
      final days = ref.watch(lifeTimelineProvider).value ?? const [];
      if (!settings.history || days.length < lifeAskAfterDays) {
        return const SizedBox.shrink();
      }
      return const _LifeInvite();
    }
    if (!settings.lifeShelf) return const SizedBox.shrink();
    final past = ref.watch(onThisDayProvider).value ?? const [];
    final today = DateTime.now();
    final days = [
      for (final d in ref.watch(lifeTimelineProvider).value ?? <LifeDay>[])
        // Today is still being written.
        if (d.day.isBefore(DateTime(today.year, today.month, today.day))) d,
    ].take(10).toList();
    if (past.isEmpty && days.isEmpty) return const SizedBox.shrink();
    final photos = ref.watch(photosAllowedProvider).value ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            children: [
              Expanded(child: ShelfHeader(l10n.lifeTitle)),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.lifeIn(context)),
                  child: Text(l10n.lifeAll),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final (years, day) in past)
                _LifeDayCard(
                  day: day,
                  photos: photos,
                  label: l10n.lifeYearsAgo(years),
                  highlight: true,
                ),
              for (final day in days) _LifeDayCard(day: day, photos: photos),
            ],
          ),
        ),
      ],
    );
  }
}

/// A day as a picture card: its first photo (or the cover of its song),
/// the date, the place and the song of the day.
class _LifeDayCard extends ConsumerWidget {
  const _LifeDayCard({
    required this.day,
    required this.photos,
    this.label,
    this.highlight = false,
  });

  final LifeDay day;
  final bool photos;
  final String? label;
  final bool highlight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final top = day.songs.isEmpty ? null : day.songs.first.$1;
    final photoList = photos
        ? ref.watch(dayPhotosProvider(day.day)).value ?? const []
        : const <GalleryPhoto>[];
    final photo = photoList.isEmpty
        ? null
        : ref.watch(photoThumbProvider(photoList.first.id)).value;
    final firsts = day.firsts.length;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.lifeIn(context)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 250,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photo != null)
                  Image.memory(photo, fit: BoxFit.cover)
                else if (top?.artwork != null)
                  ArtworkImage(artwork: top!.artwork, radius: 0)
                else
                  ColoredBox(color: scheme.primaryContainer),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x33000000), Color(0xCC000000)],
                    ),
                  ),
                ),
                if (highlight)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.primary, width: 3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(color: Colors.white),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (label != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              label!,
                              style: TextStyle(
                                color: scheme.onPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Text(
                          DateFormat.MMMMEEEEd(locale).format(day.day),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (day.places.isNotEmpty)
                          Text(
                            '📍 ${day.places.first}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        if (top != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '♪ ${top.title} · ${top.artistLine}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                        if (firsts > 0)
                          Text(
                            l10n.lifeNewSongs(firsts),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The one-time question on the home screen.
class _LifeInvite extends ConsumerWidget {
  const _LifeInvite();

  Future<void> _answer(BuildContext context, WidgetRef ref, bool yes) async {
    // Every question is asked before the answer is saved: saving removes
    // this card (and its context) from the screen.
    final settings = ref.read(listeningSettingsControllerProvider.notifier);
    var places = false;
    if (yes &&
        ref.read(placesBridgeProvider).supported &&
        !ref.read(listeningSettingsControllerProvider).places) {
      final l10n = context.l10n;
      final wanted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.place_outlined),
          title: Text(l10n.lifePlaces),
          content: Text(l10n.lifeAskPlaces),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.lifeNoThanks),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.lifeTurnOn),
            ),
          ],
        ),
      );
      if (wanted == true && context.mounted) {
        await setLifeSoundtrack(context, ref, on: true);
        places = true;
      }
    }
    await settings.update(
      (s) => s.copyWith(
        lifeAsked: true,
        lifeShelf: yes,
        places: places ? null : s.places,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.lifeTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.lifeAsk),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => unawaited(_answer(context, ref, false)),
                  child: Text(l10n.lifeNoThanks),
                ),
                FilledButton(
                  onPressed: () => unawaited(_answer(context, ref, true)),
                  child: Text(l10n.lifeTurnOn),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
