import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/core/widgets/artwork_image.dart';
import 'package:melody/core/widgets/frosted.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/player_controller.dart';

/// Floating bar above the navigation showing the current track.
///
/// Tap or swipe up to open the full player.
class MiniPlayer extends ConsumerWidget {
  /// Creates the mini player.
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(playerControllerProvider);
    final track = state.current;
    if (track == null) return const SizedBox.shrink();
    final player = ref.read(playerControllerProvider.notifier);
    final duration = state.duration ?? track.duration;
    void open() => context.push(AppRoutes.nowPlaying);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) < -200) open();
        },
        child: Material(
          color: Colors.transparent,
          child: Frosted(
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: open,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 4, 6),
                    child: Row(
                      children: [
                        Hero(
                          tag: 'now-playing-artwork',
                          child: ArtworkImage(
                            artwork: track.artwork,
                            size: 44,
                            icon: Icons.music_note_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Semantics(
                            label: '${l10n.nowPlaying}: ${track.title}',
                            excludeSemantics: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  track.artistLine,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          iconSize: 32,
                          tooltip: state.playing ? l10n.pause : l10n.play,
                          icon: Icon(
                            state.playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          onPressed: player.togglePlay,
                        ),
                        IconButton(
                          iconSize: 30,
                          tooltip: l10n.next,
                          icon: const Icon(Icons.skip_next_rounded),
                          onPressed: player.next,
                        ),
                      ],
                    ),
                  ),
                  _MiniProgress(duration: duration),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniProgress extends ConsumerWidget {
  const _MiniProgress({required this.duration});

  final Duration? duration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(playerPositionProvider).value ?? Duration.zero;
    final total = duration?.inMilliseconds ?? 0;
    final value = total <= 0
        ? 0.0
        : (position.inMilliseconds / total).clamp(0.0, 1.0);
    return ExcludeSemantics(
      child: LinearProgressIndicator(
        value: value,
        minHeight: 2,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
