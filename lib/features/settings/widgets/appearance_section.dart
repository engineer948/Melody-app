import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/core/settings/theme_controller.dart';
import 'package:melody/core/theme/app_fonts.dart';
import 'package:melody/core/theme/system_colors.dart';
import 'package:melody/core/theme/theme_settings.dart';
import 'package:melody/features/settings/widgets/color_wheel.dart';
import 'package:melody/l10n/l10n.dart';

/// Theme, colors, transparency and font.
class AppearanceSection extends ConsumerWidget {
  /// Creates the section.
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);
    final systemAvailable = ref.watch(systemSeedColorProvider).value != null;
    final usesSystem = systemAvailable && settings.useSystemColors;
    final darkPossible = settings.mode != AppThemeMode.light;
    final isPreset = accentPresets.contains(settings.accent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<AppThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: AppThemeMode.system,
                  label: Text(l10n.themeSystem),
                  icon: const Icon(Icons.brightness_auto_outlined),
                ),
                ButtonSegment(
                  value: AppThemeMode.light,
                  label: Text(l10n.themeLight),
                  icon: const Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: AppThemeMode.dark,
                  label: Text(l10n.themeDark),
                  icon: const Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {settings.mode},
              onSelectionChanged: (s) => controller.setMode(s.first),
            ),
          ),
        ),
        if (darkPossible)
          SwitchListTile(
            secondary: const Icon(Icons.contrast),
            title: Text(l10n.settingsPureBlack),
            subtitle: Text(l10n.settingsPureBlackBody),
            value: settings.pureBlack,
            onChanged: (v) => controller.setPureBlack(value: v),
          ),
        SwitchListTile(
          secondary: const Icon(Icons.wallpaper_outlined),
          title: Text(l10n.colorSourceSystem),
          subtitle: systemAvailable
              ? null
              : Text(l10n.colorSourceSystemUnavailable),
          value: usesSystem,
          onChanged: systemAvailable
              ? (v) => controller.setUseSystemColors(value: v)
              : null,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            l10n.settingsAccentColor,
            style: theme.textTheme.bodyLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            children: [
              for (final color in accentPresets)
                _Swatch(
                  color: color,
                  label: l10n.colorSwatch(hexOf(color)),
                  selected: !usesSystem && settings.accent == color,
                  onTap: () => controller.setAccent(color),
                ),
              _Swatch(
                color: settings.accent,
                label: l10n.colorCustom,
                custom: true,
                selected: !usesSystem && !isPreset,
                onTap: () async {
                  final picked = await showColorWheel(context, settings.accent);
                  if (picked != null) await controller.setAccent(picked);
                },
              ),
            ],
          ),
        ),
        _SliderTile(
          icon: Icons.format_color_fill,
          label: l10n.settingsTint,
          value: settings.tint,
          onChanged: controller.setTint,
        ),
        _SliderTile(
          icon: Icons.blur_on,
          label: l10n.settingsBarTransparency,
          // Stored as opacity, shown as transparency.
          value: (1 - settings.barOpacity) / 0.7,
          onChanged: (v) => controller.setBarOpacity(1 - v * 0.7),
        ),
        ListTile(
          leading: const Icon(Icons.text_fields),
          title: Text(l10n.settingsFont),
          subtitle: Text(
            settings.font == AppFont.system
                ? l10n.fontSystem
                : settings.font.displayName,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.fontPickerIn(context)),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton.icon(
              icon: const Icon(Icons.restart_alt),
              label: Text(l10n.settingsResetAppearance),
              onPressed: controller.reset,
            ),
          ),
        ),
      ],
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    subtitle: Slider(
      value: value.clamp(0.0, 1.0),
      label: '${(value * 100).round()}%',
      divisions: 20,
      onChanged: onChanged,
    ),
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
    this.custom = false,
  });

  final Color color;
  final String label;
  final bool selected;
  final bool custom;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: custom ? null : color,
                  gradient: custom
                      ? const SweepGradient(
                          colors: [
                            Colors.red,
                            Colors.yellow,
                            Colors.green,
                            Colors.cyan,
                            Colors.blue,
                            Colors.purple,
                            Colors.red,
                          ],
                        )
                      : null,
                  shape: BoxShape.circle,
                  border: selected
                      ? Border.all(color: outline, width: 3)
                      : null,
                ),
                child: custom
                    ? const Icon(Icons.colorize, color: Colors.white, size: 18)
                    : selected
                    ? Icon(
                        Icons.check,
                        color:
                            ThemeData.estimateBrightnessForColor(color) ==
                                Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        size: 18,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
