import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/utils/formatters.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/player_controller.dart';

/// Progress slider; while dragging it previews the target time.
class SeekBar extends ConsumerStatefulWidget {
  /// Creates the bar for a track lasting [duration].
  const SeekBar({required this.duration, required this.color, super.key});

  /// Length of the current track.
  final Duration? duration;

  /// Foreground color on the artwork background.
  final Color color;

  @override
  ConsumerState<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends ConsumerState<SeekBar> {
  double? _dragMs;

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(playerPositionProvider).value ?? Duration.zero;
    final total = widget.duration?.inMilliseconds ?? 0;
    final max = total <= 0 ? 1.0 : total.toDouble();
    final valueMs = (_dragMs ?? position.inMilliseconds.toDouble()).clamp(
      0.0,
      max,
    );
    final shown = Duration(milliseconds: valueMs.round());
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: widget.color.withValues(alpha: 0.7),
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: _dragMs == null ? 4 : 8,
            activeTrackColor: widget.color,
            inactiveTrackColor: widget.color.withValues(alpha: 0.25),
            thumbColor: widget.color,
            overlayShape: SliderComponentShape.noOverlay,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            label: context.l10n.seekPosition,
            value: valueMs,
            max: max,
            onChanged: total <= 0 ? null : (v) => setState(() => _dragMs = v),
            onChangeEnd: (v) {
              unawaited(
                ref
                    .read(playerControllerProvider.notifier)
                    .seek(Duration(milliseconds: v.round())),
              );
              setState(() => _dragMs = null);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(formatDuration(shown), style: style),
              const Spacer(),
              Text(
                total <= 0
                    ? '--:--'
                    : '-${formatDuration(widget.duration! - shown)}',
                style: style,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
