import 'package:flutter/material.dart';
import 'package:melody/core/config/feature_flags.dart';
import 'package:melody/l10n/l10n.dart';

/// Name of a kind of source.
String sourceName(AppLocalizations l10n, SourceType type) => switch (type) {
  SourceType.jellyfin => 'Jellyfin',
  SourceType.emby => 'Emby',
  SourceType.subsonic => 'Subsonic / Navidrome',
  SourceType.local => l10n.sourceLocal,
  SourceType.radio => l10n.sourceRadio,
};

/// Explanation shown above the sign-in form for [type].
String sourceIntro(AppLocalizations l10n, SourceType type) => switch (type) {
  SourceType.jellyfin => l10n.connectIntro,
  SourceType.emby => l10n.connectIntroEmby,
  SourceType.subsonic => l10n.connectIntroSubsonic,
  SourceType.local => l10n.connectIntroLocal,
  SourceType.radio => l10n.connectIntroRadio,
};

/// Chips for choosing what to add; shown only when several sources are
/// enabled at build time.
class SourcePicker extends StatelessWidget {
  /// Creates the picker.
  const SourcePicker({
    required this.sources,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// Sources to offer.
  final Set<SourceType> sources;

  /// The current choice.
  final SourceType selected;

  /// Called with the new choice; `null` disables the chips.
  final ValueChanged<SourceType>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in SourceType.values)
          if (sources.contains(type))
            ChoiceChip(
              label: Text(sourceName(l10n, type)),
              selected: type == selected,
              onSelected: onChanged == null ? null : (_) => onChanged!(type),
            ),
      ],
    );
  }
}
