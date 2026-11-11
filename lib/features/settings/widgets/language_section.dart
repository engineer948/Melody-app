import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/l10n/l10n.dart';

/// Lets the user override the app language.
class LanguageSection extends ConsumerWidget {
  /// Creates the section.
  const LanguageSection({super.key});

  static const _system = '';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(localeControllerProvider);
    final labels = {
      _system: l10n.languageSystem,
      'tr': l10n.languageTurkish,
      'en': l10n.languageEnglish,
      'az': l10n.languageAzerbaijani,
    };
    return RadioGroup<String>(
      groupValue: current?.languageCode ?? _system,
      onChanged: (code) async {
        if (code == null) return;
        await ref
            .read(localeControllerProvider.notifier)
            .setLocale(code == _system ? null : Locale(code));
      },
      child: Column(
        children: [
          for (final MapEntry(key: code, value: label) in labels.entries)
            RadioListTile<String>(value: code, title: Text(label)),
        ],
      ),
    );
  }
}
