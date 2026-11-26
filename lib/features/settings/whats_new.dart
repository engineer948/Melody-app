import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'whats_new.g.dart';

/// Preference: the build number whose notes were last seen.
const whatsNewKey = 'whatsNew.seen';

/// Notes of this version after an update, in the app's language; `null`
/// on a fresh install, when they were seen, or when there are none.
@riverpod
Future<({String version, String notes})?> whatsNew(
  Ref ref,
  String language,
) async {
  final prefs = ref.watch(preferencesProvider);
  final info = await PackageInfo.fromPlatform();
  final code = int.tryParse(info.buildNumber);
  if (code == null) return null;
  final seen = prefs.getInt(whatsNewKey);
  if (seen == null) {
    // A fresh install: nothing is new yet.
    await prefs.setInt(whatsNewKey, code);
    return null;
  }
  if (seen >= code) return null;
  final notes = await loadChangelog(code, language);
  if (notes == null) return null;
  return (version: info.version, notes: notes);
}

/// The changelog of build [code] in [language] (`en`, `tr`, `az`), or in
/// English when there is none in that language.
Future<String?> loadChangelog(int code, String language) async {
  const folders = {'tr': 'tr-TR', 'az': 'az-AZ'};
  for (final folder in [?folders[language], 'en-US']) {
    try {
      final text = await rootBundle.loadString(
        'fastlane/metadata/android/$folder/changelogs/$code.txt',
      );
      if (text.trim().isNotEmpty) return text.trim();
    } on Object {
      // Not bundled in this language.
    }
  }
  return null;
}

/// "What's new" card on Home, shown once after an update.
class WhatsNewBanner extends ConsumerWidget {
  /// Creates the card.
  const WhatsNewBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = Localizations.localeOf(context).languageCode;
    final news = ref.watch(whatsNewProvider(language)).value;
    if (news == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.celebration_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.whatsNewTitle(news.version),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(news.notes),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  final info = await PackageInfo.fromPlatform();
                  final code = int.tryParse(info.buildNumber);
                  if (code != null) {
                    await ref
                        .read(preferencesProvider)
                        .setInt(whatsNewKey, code);
                  }
                  ref.invalidate(whatsNewProvider);
                },
                child: Text(l10n.whatsNewDismiss),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
