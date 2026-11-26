import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/features/home/home_shelves.dart';
import 'package:melody/features/settings/widgets/media_sections.dart';
import 'package:melody/l10n/l10n.dart';

/// Preference: the welcome card was closed.
const welcomeDoneKey = 'welcome.done';

/// First steps on Home after signing in: sound quality and the shelves.
class WelcomeCard extends ConsumerStatefulWidget {
  /// Creates the card.
  const WelcomeCard({super.key});

  @override
  ConsumerState<WelcomeCard> createState() => _WelcomeCardState();
}

class _WelcomeCardState extends ConsumerState<WelcomeCard> {
  Future<void> _done() async {
    await ref.read(preferencesProvider).setBool(welcomeDoneKey, true);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(preferencesProvider).getBool(welcomeDoneKey) ?? false) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(l10n.welcomeTitle, style: theme.textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(l10n.welcomeBody),
            ),
            const QualityPresetTile(),
            ListTile(
              leading: const Icon(Icons.view_agenda_outlined),
              title: Text(l10n.homeShelves),
              subtitle: Text(l10n.homeShelvesSubtitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HomeShelvesScreen(),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton(
                  onPressed: _done,
                  child: Text(l10n.welcomeDone),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
