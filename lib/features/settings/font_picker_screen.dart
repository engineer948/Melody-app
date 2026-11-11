import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/settings/theme_controller.dart';
import 'package:melody/core/theme/app_fonts.dart';
import 'package:melody/l10n/l10n.dart';

/// Lists every bundled font, each previewed in itself.
class FontPickerScreen extends ConsumerWidget {
  /// Creates the screen.
  const FontPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final selected = ref.watch(themeControllerProvider.select((s) => s.font));
    final controller = ref.read(themeControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsFont)),
      body: RadioGroup<AppFont>(
        groupValue: selected,
        onChanged: (font) {
          if (font != null) unawaited(controller.setFont(font));
        },
        child: ListView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + 16,
          ),
          children: [
            for (final font in AppFont.values)
              RadioListTile<AppFont>(
                value: font,
                title: Text(
                  font == AppFont.system ? l10n.fontSystem : font.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: font.family,
                  ),
                ),
                subtitle: Text(
                  l10n.fontSample,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: font.family),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
