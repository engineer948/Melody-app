import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/player_controller.dart';

/// Speeds offered in the speed sheet.
const playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

/// Formats a speed like `1.25`.
String formatSpeed(double speed) =>
    speed == speed.roundToDouble() ? speed.toStringAsFixed(1) : '$speed';

/// Lets the user pick the playback speed.
Future<void> showSpeedSheet(BuildContext context, WidgetRef ref) {
  final l10n = context.l10n;
  final current = ref.read(playerControllerProvider).speed;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.playbackSpeed,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          RadioGroup<double>(
            groupValue: current,
            onChanged: (speed) {
              if (speed == null) return;
              unawaited(
                ref.read(playerControllerProvider.notifier).setSpeed(speed),
              );
              Navigator.pop(context);
            },
            child: Column(
              children: [
                for (final speed in playbackSpeeds)
                  RadioListTile<double>(
                    value: speed,
                    title: Text(l10n.speedValue(formatSpeed(speed))),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Minutes offered by the sleep timer.
const sleepMinutes = [5, 10, 15, 30, 45, 60, 90];

/// Lets the user start or stop the sleep timer.
Future<void> showSleepSheet(BuildContext context, WidgetRef ref) {
  final l10n = context.l10n;
  final player = ref.read(playerControllerProvider.notifier);
  final active = ref.read(playerControllerProvider).sleepTimer != null;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.sleepTimer,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final minutes in sleepMinutes)
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: Text(l10n.sleepMinutes(minutes)),
                onTap: () {
                  player.setSleepTimer(Duration(minutes: minutes));
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.music_off_outlined),
              title: Text(l10n.sleepEndOfTrack),
              onTap: () {
                player.setSleepTimer(null);
                Navigator.pop(context);
              },
            ),
            if (active)
              ListTile(
                leading: const Icon(Icons.timer_off_outlined),
                title: Text(l10n.sleepOff),
                onTap: () {
                  unawaited(player.cancelSleepTimer());
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    ),
  );
}
