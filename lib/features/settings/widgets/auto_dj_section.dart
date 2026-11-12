import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/listening_settings.dart';

/// Auto DJ: switch, where songs come from and when they are added.
class AutoDjSection extends ConsumerWidget {
  /// Creates the section.
  const AutoDjSection({super.key});

  static String _label(AppLocalizations l10n, AutoDjMode mode) =>
      switch (mode) {
        AutoDjMode.similar => l10n.autoDjSimilar,
        AutoDjMode.artist => l10n.autoDjArtist,
        AutoDjMode.genre => l10n.autoDjGenre,
        AutoDjMode.random => l10n.autoDjRandom,
        AutoDjMode.smart => l10n.autoDjSmart,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(listeningSettingsControllerProvider);
    final c = ref.read(listeningSettingsControllerProvider.notifier);
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.all_inclusive),
          title: Text(l10n.autoDj),
          subtitle: Text(l10n.autoDjBody),
          value: s.autoDj,
          onChanged: (v) => unawaited(c.update((s) => s.copyWith(autoDj: v))),
        ),
        if (s.autoDj) ...[
          ListTile(
            leading: const SizedBox(width: 24),
            title: Text(l10n.autoDjMode),
            trailing: DropdownButton<AutoDjMode>(
              value: s.autoDjMode,
              underline: const SizedBox.shrink(),
              onChanged: (mode) {
                if (mode != null) {
                  unawaited(c.update((s) => s.copyWith(autoDjMode: mode)));
                }
              },
              items: [
                for (final mode in AutoDjMode.values)
                  DropdownMenuItem(
                    value: mode,
                    child: Text(_label(l10n, mode)),
                  ),
              ],
            ),
          ),
          ListTile(
            leading: const SizedBox(width: 24),
            title: Text(l10n.autoDjThreshold),
            trailing: DropdownButton<int>(
              value: s.autoDjThreshold.clamp(0, 5),
              underline: const SizedBox.shrink(),
              onChanged: (n) {
                if (n != null) {
                  unawaited(c.update((s) => s.copyWith(autoDjThreshold: n)));
                }
              },
              items: [
                for (var n = 0; n <= 5; n++)
                  DropdownMenuItem(value: n, child: Text('$n')),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
