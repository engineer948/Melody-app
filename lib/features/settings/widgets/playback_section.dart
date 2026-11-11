import 'dart:async';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/playback_settings.dart';

/// Crossfade lengths offered, in seconds.
const crossfadeChoices = [0, 2, 4, 6, 8, 10, 12];

/// Fade lengths offered for pause and play.
const fadeChoices = [0, 150, 300, 600];

/// Volume normalisation, fades and the equaliser entry.
class PlaybackSection extends ConsumerWidget {
  /// Creates the section.
  const PlaybackSection({super.key});

  static String _modeLabel(AppLocalizations l10n, ReplayGainMode mode) =>
      switch (mode) {
        ReplayGainMode.off => l10n.replayGainOff,
        ReplayGainMode.track => l10n.replayGainTrack,
        ReplayGainMode.album => l10n.replayGainAlbum,
        ReplayGainMode.auto => l10n.replayGainAuto,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(playbackSettingsControllerProvider);
    final controller = ref.read(playbackSettingsControllerProvider.notifier);
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.equalizer_outlined),
          title: Text(l10n.replayGain),
          trailing: DropdownButton<ReplayGainMode>(
            value: settings.replayGain,
            underline: const SizedBox.shrink(),
            onChanged: (mode) {
              if (mode != null) {
                unawaited(
                  controller.update((s) => s.copyWith(replayGain: mode)),
                );
              }
            },
            items: [
              for (final mode in ReplayGainMode.values)
                DropdownMenuItem(
                  value: mode,
                  child: Text(_modeLabel(l10n, mode)),
                ),
            ],
          ),
        ),
        if (settings.replayGain != ReplayGainMode.off)
          ListTile(
            leading: const SizedBox(width: 24),
            title: Text(l10n.replayGainPreamp),
            subtitle: Slider(
              value: settings.preampDb,
              min: -12,
              max: 0,
              divisions: 24,
              label: l10n.dbValue(settings.preampDb.toStringAsFixed(1)),
              onChanged: (v) =>
                  controller.update((s) => s.copyWith(preampDb: v)),
            ),
            trailing: Text(l10n.dbValue(settings.preampDb.toStringAsFixed(1))),
          ),
        ListTile(
          leading: const Icon(Icons.graphic_eq),
          title: Text(l10n.fadeLength),
          trailing: DropdownButton<int>(
            value: fadeChoices.contains(settings.fadeMs) ? settings.fadeMs : 0,
            underline: const SizedBox.shrink(),
            onChanged: (ms) {
              if (ms != null) {
                unawaited(controller.update((s) => s.copyWith(fadeMs: ms)));
              }
            },
            items: [
              for (final ms in fadeChoices)
                DropdownMenuItem(
                  value: ms,
                  child: Text(ms == 0 ? l10n.fadeOff : l10n.msValue(ms)),
                ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.swap_horiz),
          title: Text(l10n.crossfade),
          subtitle: Text(l10n.crossfadeBody),
          isThreeLine: true,
          trailing: DropdownButton<int>(
            value: crossfadeChoices.contains(settings.crossfadeSeconds)
                ? settings.crossfadeSeconds
                : 0,
            underline: const SizedBox.shrink(),
            onChanged: (s) {
              if (s != null) {
                unawaited(
                  controller.update((x) => x.copyWith(crossfadeSeconds: s)),
                );
              }
            },
            items: [
              for (final s in crossfadeChoices)
                DropdownMenuItem(
                  value: s,
                  child: Text(
                    s == 0 ? l10n.crossfadeOff : l10n.secondsValue(s),
                  ),
                ),
            ],
          ),
        ),
        if (Platform.isAndroid)
          ListTile(
            leading: const Icon(Icons.tune),
            title: Text(l10n.equalizer),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.equalizerIn(context)),
          ),
      ],
    );
  }
}
