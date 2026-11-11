import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/widgets/empty_state.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/audio_engine.dart';
import 'package:melody/player/playback_settings.dart';
import 'package:melody/player/player_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'equalizer_screen.g.dart';

/// Bands of the platform equaliser.
@riverpod
Future<List<EqualizerBand>> equalizerBands(Ref ref) =>
    ref.watch(audioEngineProvider).equalizerBands();

/// Built-in equaliser presets, as gain curves over frequency.
enum EqualizerPreset {
  /// No change.
  flat,

  /// More low end.
  bass,

  /// More high end.
  treble,

  /// Brings voices forward.
  vocal,

  /// Scooped mids.
  rock,

  /// Gentle smile curve.
  pop,

  /// Warm, slightly bright.
  jazz,

  /// Wide and airy.
  classical;

  /// Gain in dB at [hz], before clamping to the band range.
  double gainAt(double hz) {
    final low = hz <= 250;
    final mid = hz > 250 && hz <= 4000;
    return switch (this) {
      flat => 0,
      bass => low ? 6 - hz / 100 : 0,
      treble =>
        hz >= 4000
            ? 5
            : hz >= 1000
            ? 2
            : 0,
      vocal =>
        mid
            ? 4
            : low
            ? -2
            : 1,
      rock =>
        low
            ? 4
            : mid
            ? -2
            : 4,
      pop =>
        low
            ? 2
            : mid
            ? 1
            : 2,
      jazz =>
        low
            ? 3
            : mid
            ? -1
            : 2,
      classical =>
        low
            ? 3
            : mid
            ? 0
            : 3,
    };
  }
}

/// Equaliser and loudness boost (Android only).
class EqualizerScreen extends ConsumerWidget {
  /// Creates the screen.
  const EqualizerScreen({super.key});

  static String _presetLabel(AppLocalizations l10n, EqualizerPreset p) =>
      switch (p) {
        EqualizerPreset.flat => l10n.presetFlat,
        EqualizerPreset.bass => l10n.presetBass,
        EqualizerPreset.treble => l10n.presetTreble,
        EqualizerPreset.vocal => l10n.presetVocal,
        EqualizerPreset.rock => l10n.presetRock,
        EqualizerPreset.pop => l10n.presetPop,
        EqualizerPreset.jazz => l10n.presetJazz,
        EqualizerPreset.classical => l10n.presetClassical,
      };

  static String _frequency(AppLocalizations l10n, double hz) => hz >= 1000
      ? l10n.khzValue((hz / 1000).toStringAsFixed(hz >= 10000 ? 0 : 1))
      : l10n.hzValue(hz.round());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(playbackSettingsControllerProvider);
    final controller = ref.read(playbackSettingsControllerProvider.notifier);
    final bands = ref.watch(equalizerBandsProvider).value ?? const [];
    List<double> gains() => [
      for (var i = 0; i < bands.length; i++)
        if (i < settings.equalizerGains.length)
          settings.equalizerGains[i]
        else
          0,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.equalizer)),
      body: bands.isEmpty
          ? EmptyState(icon: Icons.tune, title: l10n.equalizerUnavailable)
          : ListView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 16,
              ),
              children: [
                SwitchListTile(
                  title: Text(l10n.equalizerEnabled),
                  value: settings.equalizerEnabled,
                  onChanged: (v) =>
                      controller.update((s) => s.copyWith(equalizerEnabled: v)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final preset in EqualizerPreset.values)
                        ActionChip(
                          label: Text(_presetLabel(l10n, preset)),
                          onPressed: () => controller.update(
                            (s) => s.copyWith(
                              equalizerEnabled: true,
                              equalizerGains: [
                                for (final b in bands)
                                  preset
                                      .gainAt(b.centerHz)
                                      .clamp(b.minDb, b.maxDb),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                for (var i = 0; i < bands.length; i++)
                  ListTile(
                    enabled: settings.equalizerEnabled,
                    leading: SizedBox(
                      width: 64,
                      child: Text(_frequency(l10n, bands[i].centerHz)),
                    ),
                    title: Slider(
                      value: gains()[i].clamp(bands[i].minDb, bands[i].maxDb),
                      min: bands[i].minDb,
                      max: bands[i].maxDb,
                      label: l10n.dbValue(gains()[i].toStringAsFixed(1)),
                      onChanged: settings.equalizerEnabled
                          ? (v) => controller.update(
                              (s) => s.copyWith(
                                equalizerGains: [...gains()]..[i] = v,
                              ),
                            )
                          : null,
                    ),
                    trailing: Text(l10n.dbValue(gains()[i].toStringAsFixed(1))),
                  ),
                const Divider(),
                ListTile(
                  title: Text(l10n.loudnessBoost),
                  subtitle: Slider(
                    value: settings.loudnessBoostDb,
                    max: 10,
                    divisions: 20,
                    label: l10n.dbValue(
                      settings.loudnessBoostDb.toStringAsFixed(1),
                    ),
                    onChanged: (v) => controller.update(
                      (s) => s.copyWith(loudnessBoostDb: v),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
