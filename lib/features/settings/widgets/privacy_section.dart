import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/features/stats/stats_providers.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/history_recorder.dart';
import 'package:melody/player/listening_settings.dart';

/// Listening history, suggestions and statistics.
class PrivacySection extends ConsumerWidget {
  /// Creates the section.
  const PrivacySection({super.key});

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.privacyClearHistoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(historyStoreProvider).clear();
    ref.read(historyRevisionProvider.notifier).bump();
    ref.invalidate(suggestionsProvider);
    messenger.showSnackBar(SnackBar(content: Text(l10n.privacyHistoryCleared)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(listeningSettingsControllerProvider);
    final c = ref.read(listeningSettingsControllerProvider.notifier);
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.insights_outlined),
          title: Text(l10n.statsTitle),
          subtitle: Text(l10n.statsBody),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.statsIn(context)),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.history),
          title: Text(l10n.privacyHistory),
          subtitle: Text(l10n.privacyHistoryBody),
          value: s.history,
          onChanged: (v) => unawaited(c.update((s) => s.copyWith(history: v))),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.recommend_outlined),
          title: Text(l10n.privacySuggestions),
          value: s.suggestions,
          onChanged: (v) =>
              unawaited(c.update((s) => s.copyWith(suggestions: v))),
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: Text(l10n.privacyClearHistory),
          onTap: () => _clear(context, ref),
        ),
      ],
    );
  }
}
