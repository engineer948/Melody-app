import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/l10n/l10n.dart';

/// Version of the terms below; raised when they change in substance, so
/// that sharing asks again.
const legalTermsVersion = 1;

/// Preference: the version of the terms the user accepted for sharing.
const termsAcceptedKey = 'legal.termsVersion';

/// Preference: when they were accepted (ISO 8601, on this phone only).
const termsAcceptedAtKey = 'legal.termsAcceptedAt';

/// Opens the terms of use, sharing rules and privacy notice.
Future<void> showLegal(BuildContext context) => Navigator.of(
  context,
  rootNavigator: true,
).push(MaterialPageRoute<void>(builder: (_) => const LegalScreen()));

/// Asks once (per version of the terms) whether the user accepts that
/// they alone are responsible for the music they share; `true` when they
/// do. The answer and its date are kept on the phone.
Future<bool> confirmShareTerms(BuildContext context, WidgetRef ref) async {
  final prefs = ref.read(preferencesProvider);
  if ((prefs.getInt(termsAcceptedKey) ?? 0) >= legalTermsVersion) return true;
  final l10n = context.l10n;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.copyright_rounded),
      title: Text(l10n.clipRightsTitle),
      content: SingleChildScrollView(child: Text(l10n.clipRightsBody)),
      actions: [
        TextButton(
          onPressed: () => unawaited(showLegal(context)),
          child: Text(l10n.legalRead),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.clipRightsAccept),
        ),
      ],
    ),
  );
  if (accepted != true) return false;
  await prefs.setInt(termsAcceptedKey, legalTermsVersion);
  await prefs.setString(
    termsAcceptedAtKey,
    DateTime.now().toUtc().toIso8601String(),
  );
  return true;
}

/// Terms of use, sharing and copyright, privacy and the licence's
/// disclaimer, in the app's language.
class LegalScreen extends StatelessWidget {
  /// Creates the screen.
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sections = [
      (l10n.legalWhatTitle, l10n.legalWhatBody),
      (l10n.legalSharingTitle, l10n.legalSharingBody),
      (l10n.legalPrivacyTitle, l10n.legalPrivacyBody),
      (l10n.legalServicesTitle, l10n.legalServicesBody),
      (l10n.legalWarrantyTitle, l10n.legalWarrantyBody),
      (l10n.legalComplaintsTitle, l10n.legalComplaintsBody),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.legalTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            l10n.legalVersion(legalTermsVersion),
            style: theme.textTheme.bodySmall,
          ),
          for (final (title, body) in sections) ...[
            const SizedBox(height: 20),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(body, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
