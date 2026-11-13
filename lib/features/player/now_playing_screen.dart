import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/core/widgets/artwork_image.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/library/collection_actions.dart';
import 'package:melody/features/lyrics/lyrics_view.dart';
import 'package:melody/features/player/track_actions.dart';
import 'package:melody/features/player/widgets/output_sheet.dart';
import 'package:melody/features/player/widgets/player_sheets.dart';
import 'package:melody/features/player/widgets/seek_bar.dart';
import 'package:melody/features/share/share_screen.dart';
import 'package:melody/features/share/share_subject.dart';
import 'package:melody/features/social/listen_together_screen.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/play_queue.dart';
import 'package:melody/player/player_controller.dart';
import 'package:melody/player/player_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'now_playing_screen.g.dart';

/// Whether the now playing screen shows lyrics instead of the cover.
@riverpod
class NowPlayingLyrics extends _$NowPlayingLyrics {
  @override
  bool build() => false;

  /// Switches between cover and lyrics.
  void toggle() => state = !state;
}

/// Full-screen player over a blurred copy of the artwork.
///
/// Swipe the cover sideways to change tracks, swipe down to close.
class NowPlayingScreen extends ConsumerWidget {
  /// Creates the screen.
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(playerControllerProvider);
    final showLyrics = ref.watch(nowPlayingLyricsProvider);
    final track = state.current;
    if (track == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && context.canPop()) context.pop();
      });
      return const Scaffold();
    }
    const fg = Colors.white;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 300) context.pop();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Transform.scale(
                scale: 1.4,
                child: ArtworkImage(artwork: track.artwork, radius: 0),
              ),
            ),
            const ColoredBox(color: Color(0x8C000000)),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cover = (constraints.maxWidth - 64).clamp(
                    120.0,
                    constraints.maxHeight * 0.45,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              color: fg,
                              tooltip: l10n.playerClose,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 32,
                              ),
                              onPressed: () => context.pop(),
                            ),
                            const Spacer(),
                            IconButton(
                              color: fg,
                              tooltip: l10n.socialFeatureListen,
                              icon: const Icon(Icons.headphones_rounded),
                              onPressed: () =>
                                  ListenTogetherScreen.open(context),
                            ),
                            IconButton(
                              color: fg,
                              tooltip: l10n.share,
                              icon: const Icon(Icons.share_outlined),
                              onPressed: () => showShareScreen(
                                context,
                                ShareSubject.track(track),
                              ),
                            ),
                            IconButton(
                              color: fg,
                              tooltip: l10n.moreOptions,
                              icon: const Icon(Icons.more_horiz),
                              onPressed: () =>
                                  showTrackMenu(context, ref, track),
                            ),
                          ],
                        ),
                        if (showLyrics)
                          Expanded(child: LyricsView(track: track))
                        else ...[
                          const Spacer(),
                          _SwipeableCover(state: state, size: cover),
                          const Spacer(),
                        ],
                        _TitleRow(state: state),
                        const SizedBox(height: 12),
                        SeekBar(
                          duration: state.duration ?? track.duration,
                          color: fg,
                        ),
                        const SizedBox(height: 8),
                        _Transport(state: state),
                        const SizedBox(height: 16),
                        _BottomRow(state: state),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (state.error != null)
              Positioned(
                left: 24,
                right: 24,
                top: MediaQuery.paddingOf(context).top + 56,
                child: Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(l10n.playbackError),
                  ),
                ),
              ),
            // Keep the player reachable for screen readers.
            Semantics(label: l10n.nowPlaying, child: const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class _SwipeableCover extends ConsumerWidget {
  const _SwipeableCover({required this.state, required this.size});

  final PlayerState state;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerControllerProvider.notifier);
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v.abs() > 300) unawaited(HapticFeedback.selectionClick());
        if (v < -300) unawaited(player.next());
        if (v > 300) unawaited(player.previous());
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        scale: state.playing ? 1 : 0.86,
        child: Hero(
          tag: 'now-playing-artwork',
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 30,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: ArtworkImage(
              artwork: state.current?.artwork,
              size: size,
              radius: 14,
              icon: Icons.music_note_outlined,
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleRow extends ConsumerWidget {
  const _TitleRow({required this.state});

  final PlayerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final canFavorite =
        ref.watch(activeSourceProvider)?.capabilities.favorites ?? false;
    final track = state.current!;
    final albumId = track.albumId;
    final format = track.container?.toUpperCase();
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: albumId == null
                ? null
                : () => context.go(AppRoutes.album(context, albumId)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
                Text(
                  track.artistLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (canFavorite)
          IconButton(
            color: Colors.white,
            tooltip: track.isFavorite ? l10n.favoriteRemove : l10n.favoriteAdd,
            icon: Icon(
              track.isFavorite ? Icons.favorite : Icons.favorite_border,
            ),
            onPressed: () => toggleTrackFavorite(context, ref, track),
          ),
        if (format != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white54),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              format,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
      ],
    );
  }
}

class _Transport extends ConsumerWidget {
  const _Transport({required this.state});

  final PlayerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final player = ref.read(playerControllerProvider.notifier);
    const fg = Colors.white;
    const dim = Colors.white54;
    final repeat = state.queue.repeat;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          tooltip: l10n.shuffle,
          isSelected: state.queue.shuffled,
          color: state.queue.shuffled ? fg : dim,
          icon: const Icon(Icons.shuffle_rounded),
          onPressed: player.toggleShuffle,
        ),
        IconButton(
          tooltip: l10n.previous,
          color: fg,
          iconSize: 44,
          icon: const Icon(Icons.skip_previous_rounded),
          onPressed: () {
            unawaited(HapticFeedback.selectionClick());
            unawaited(player.previous());
          },
        ),
        IconButton(
          tooltip: state.playing ? l10n.pause : l10n.play,
          color: fg,
          iconSize: 72,
          icon: state.buffering
              ? const SizedBox.square(
                  dimension: 56,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(color: fg),
                  ),
                )
              : Icon(
                  state.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
          onPressed: () {
            unawaited(HapticFeedback.selectionClick());
            unawaited(player.togglePlay());
          },
        ),
        IconButton(
          tooltip: l10n.next,
          color: fg,
          iconSize: 44,
          icon: const Icon(Icons.skip_next_rounded),
          onPressed: () {
            unawaited(HapticFeedback.selectionClick());
            unawaited(player.next());
          },
        ),
        IconButton(
          tooltip: switch (repeat) {
            QueueRepeat.off => l10n.repeatOff,
            QueueRepeat.all => l10n.repeatAll,
            QueueRepeat.one => l10n.repeatOne,
          },
          color: repeat == QueueRepeat.off ? dim : fg,
          icon: Icon(
            repeat == QueueRepeat.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
          ),
          onPressed: player.cycleRepeat,
        ),
      ],
    );
  }
}

class _BottomRow extends ConsumerWidget {
  const _BottomRow({required this.state});

  final PlayerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    const fg = Colors.white70;
    final showLyrics = ref.watch(nowPlayingLyricsProvider);
    final sleep = state.sleepTimer;
    final endsAt = sleep?.endsAt;
    final sleepLabel = sleep == null
        ? l10n.sleepTimer
        : sleep.endOfTrack
        ? l10n.sleepAfterSong
        : l10n.sleepUntil(
            DateFormat.Hm(Localizations.localeOf(context).toLanguageTag())
                .format(endsAt!),
          );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: fg),
          onPressed: () => showSpeedSheet(context, ref),
          child: Text(
            l10n.speedValue(formatSpeed(state.speed)),
            semanticsLabel: l10n.playbackSpeed,
          ),
        ),
        IconButton(
          color: showLyrics ? Colors.white : fg,
          isSelected: showLyrics,
          tooltip: l10n.lyrics,
          icon: Icon(showLyrics ? Icons.lyrics_rounded : Icons.lyrics_outlined),
          onPressed: ref.read(nowPlayingLyricsProvider.notifier).toggle,
        ),
        IconButton(
          color: sleep == null ? fg : Colors.white,
          tooltip: sleepLabel,
          icon: Icon(
            sleep == null ? Icons.bedtime_outlined : Icons.bedtime_rounded,
          ),
          onPressed: () => showSleepSheet(context, ref),
        ),
        const OutputButton(color: fg),
        IconButton(
          color: fg,
          tooltip: l10n.queue,
          icon: const Icon(Icons.queue_music_rounded),
          onPressed: () => context.push(AppRoutes.queue),
        ),
      ],
    );
  }
}
