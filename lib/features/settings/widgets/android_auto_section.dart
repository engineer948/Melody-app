import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/media_browser.dart';

/// Which sections Android Auto shows.
class AndroidAutoSection extends ConsumerWidget {
  /// Creates the section.
  const AndroidAutoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final visible = ref.watch(autoTabsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.androidAutoBody,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final tab in AutoTab.values)
                FilterChip(
                  label: Text(autoTabLabel(l10n, tab)),
                  selected: visible.contains(tab),
                  onSelected: (v) => unawaited(
                    ref
                        .read(autoTabsProvider.notifier)
                        .setVisible(tab, visible: v),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
