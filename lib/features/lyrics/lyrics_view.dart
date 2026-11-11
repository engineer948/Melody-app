import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/features/lyrics/lyrics_providers.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/player_controller.dart';

/// Lyrics of [track] on the now playing screen.
///
/// Synced lyrics follow the song; tapping a line jumps there. After the user
/// scrolls, following pauses for a few seconds.
class LyricsView extends ConsumerStatefulWidget {
  /// Creates the view.
  const LyricsView({required this.track, super.key});

  /// Track whose lyrics are shown.
  final Track track;

  @override
  ConsumerState<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<LyricsView> {
  final _keys = <int, GlobalKey>{};
  DateTime _userScrolledAt = DateTime.fromMillisecondsSinceEpoch(0);
  int _shown = -2;

  GlobalKey _key(int i) => _keys.putIfAbsent(i, GlobalKey.new);

  void _follow(int line) {
    if (line == _shown) return;
    _shown = line;
    if (DateTime.now().difference(_userScrolledAt) <
        const Duration(seconds: 4)) {
      return;
    }
    final context = _keys[line < 0 ? 0 : line]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.35,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final value = ref.watch(trackLyricsProvider(widget.track));
    final settings = ref.watch(lyricsSettingsControllerProvider);
    final lyrics = value.value;
    if (lyrics == null) {
      return Center(
        child: value.isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                l10n.lyricsNone,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
      );
    }
    final offset = settings.offsetOf(widget.track.id);
    final position = ref.watch(playerPositionProvider).value ?? Duration.zero;
    final current = lyrics.lineAt(position - offset);
    if (lyrics.synced) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _follow(current));
    }
    final align = settings.alignCenter ? TextAlign.center : TextAlign.start;
    final base = theme.textTheme.headlineSmall?.copyWith(
      fontSize:
          (theme.textTheme.headlineSmall?.fontSize ?? 24) * settings.fontScale,
      fontWeight: FontWeight.w800,
      height: 1.25,
    );
    return Column(
      children: [
        Expanded(
          child: NotificationListener<ScrollStartNotification>(
            onNotification: (n) {
              if (n.dragDetails != null) _userScrolledAt = DateTime.now();
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 120),
              itemCount: lyrics.lines.length,
              itemBuilder: (context, i) {
                final line = lyrics.lines[i];
                final active = !lyrics.synced || i == current;
                final start = line.start;
                return InkWell(
                  key: _key(i),
                  borderRadius: BorderRadius.circular(8),
                  onTap: start == null
                      ? null
                      : () {
                          _userScrolledAt = DateTime.fromMillisecondsSinceEpoch(
                            0,
                          );
                          unawaited(
                            ref
                                .read(playerControllerProvider.notifier)
                                .seek(start + offset),
                          );
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      textAlign: align,
                      style: base!.copyWith(
                        color: active ? Colors.white : Colors.white38,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(line.text.isEmpty ? '♪' : line.text),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        _Footer(track: widget.track, lyrics: lyrics, offset: offset),
      ],
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({
    required this.track,
    required this.lyrics,
    required this.offset,
  });

  final Track track;
  final Lyrics lyrics;
  final Duration offset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final style = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: Colors.white60);
    final controller = ref.read(lyricsSettingsControllerProvider.notifier);
    const step = Duration(milliseconds: 500);
    final seconds = offset.inMilliseconds / 1000;
    return Row(
      children: [
        if (lyrics.origin == LyricsOrigin.lrclib)
          Expanded(child: Text(l10n.lyricsFromLrclib, style: style))
        else
          const Spacer(),
        if (lyrics.synced) ...[
          IconButton(
            color: Colors.white70,
            tooltip: l10n.lyricsEarlier,
            icon: const Icon(Icons.fast_rewind_rounded, size: 18),
            onPressed: () => controller.shift(track.id, -step),
          ),
          Text(
            l10n.lyricsOffset(
              '${seconds > 0 ? '+' : ''}${seconds.toStringAsFixed(1)}',
            ),
            style: style,
          ),
          IconButton(
            color: Colors.white70,
            tooltip: l10n.lyricsLater,
            icon: const Icon(Icons.fast_forward_rounded, size: 18),
            onPressed: () => controller.shift(track.id, step),
          ),
        ],
      ],
    );
  }
}
