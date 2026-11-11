import 'package:flutter/material.dart';

/// Bar chart of listening time per hour of the day.
class HourChart extends StatelessWidget {
  /// Creates the chart from 24 values.
  const HourChart({required this.byHour, this.height = 120, super.key});

  /// Time listened in each hour, starting at midnight.
  final List<Duration> byHour;

  /// Height of the bars.
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    var peak = Duration.zero;
    for (final d in byHour) {
      if (d > peak) peak = d;
    }
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return ExcludeSemantics(
      child: Column(
        children: [
          SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final d in byHour)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: FractionallySizedBox(
                        heightFactor: peak == Duration.zero
                            ? 0.02
                            : (d.inSeconds / peak.inSeconds).clamp(0.02, 1.0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: d == peak && peak > Duration.zero
                                ? scheme.primary
                                : scheme.primary.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final h in const ['00', '06', '12', '18', '23'])
                Text(h, style: labelStyle),
            ],
          ),
        ],
      ),
    );
  }
}
