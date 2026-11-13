import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/data/downloads/download_settings.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/streaming_settings.dart';

/// Offline downloads: network, quality and automatic downloads.
class DownloadsSection extends ConsumerWidget {
  /// Creates the section.
  const DownloadsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(downloadSettingsControllerProvider);
    final c = ref.read(downloadSettingsControllerProvider.notifier);
    String format(StreamFormat f) => switch (f) {
      StreamFormat.original => l10n.streamOriginal,
      StreamFormat.opus => 'Opus',
      StreamFormat.aac => 'AAC',
      StreamFormat.mp3 => 'MP3',
    };
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.wifi),
          title: Text(l10n.downloadWifiOnly),
          value: s.wifiOnly,
          onChanged: (v) => unawaited(c.update((s) => s.copyWith(wifiOnly: v))),
        ),
        ListTile(
          leading: const Icon(Icons.high_quality_outlined),
          title: Text(l10n.downloadQuality),
          subtitle: Text(l10n.downloadQualityBody),
          trailing: DropdownButton<int?>(
            value: s.bitrate,
            underline: const SizedBox.shrink(),
            onChanged: (v) => unawaited(
              c.update(
                (s) => s.copyWith(
                  bitrate: v,
                  clearBitrate: v == null,
                  // A bitrate limit needs a format to convert to.
                  format: v == null
                      ? StreamFormat.original
                      : s.format == StreamFormat.original
                      ? StreamFormat.mp3
                      : s.format,
                ),
              ),
            ),
            items: [
              for (final b in bitrateChoices)
                DropdownMenuItem(
                  value: b,
                  child: Text(
                    b == null ? l10n.streamOriginal : l10n.kbpsValue(b),
                  ),
                ),
            ],
          ),
        ),
        if (s.bitrate != null)
          ListTile(
            leading: const SizedBox(width: 24),
            title: Text(l10n.streamFormat),
            trailing: DropdownButton<StreamFormat>(
              value: s.format == StreamFormat.original
                  ? StreamFormat.mp3
                  : s.format,
              underline: const SizedBox.shrink(),
              onChanged: (f) {
                if (f != null) {
                  unawaited(c.update((s) => s.copyWith(format: f)));
                }
              },
              items: [
                for (final f in StreamFormat.values)
                  if (f != StreamFormat.original)
                    DropdownMenuItem(value: f, child: Text(format(f))),
              ],
            ),
          ),
        ListTile(
          leading: const Icon(Icons.downloading_outlined),
          title: Text(l10n.downloadParallel),
          trailing: DropdownButton<int>(
            value: s.parallel.clamp(1, 4),
            underline: const SizedBox.shrink(),
            onChanged: (n) {
              if (n != null) {
                unawaited(c.update((s) => s.copyWith(parallel: n)));
              }
            },
            items: [
              for (var n = 1; n <= 4; n++)
                DropdownMenuItem(value: n, child: Text('$n')),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.compress_rounded),
          title: Text(l10n.downloadSaveSpace),
          subtitle: Text(l10n.downloadSaveSpaceBody),
          trailing: s.bitrate == 128 && s.format == StreamFormat.opus
              ? const Icon(Icons.check_rounded)
              : null,
          onTap: () => unawaited(
            c.update(
              (s) => s.copyWith(bitrate: 128, format: StreamFormat.opus),
            ),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.library_music_outlined),
          title: Text(l10n.downloadSyncLibrary),
          subtitle: Text(l10n.downloadSyncLibraryBody),
          value: s.syncLibrary,
          onChanged: (v) =>
              unawaited(c.update((s) => s.copyWith(syncLibrary: v))),
        ),
        if (s.syncLibrary)
          ListTile(
            leading: const SizedBox(width: 24),
            title: Text(l10n.downloadLibraryLimit),
            trailing: DropdownButton<int?>(
              value: s.libraryLimitGb,
              underline: const SizedBox.shrink(),
              onChanged: (v) => unawaited(
                c.update(
                  (s) => s.copyWith(
                    libraryLimitGb: v,
                    clearLibraryLimit: v == null,
                  ),
                ),
              ),
              items: [
                for (final gb in DownloadSettings.libraryLimitChoices)
                  DropdownMenuItem(
                    value: gb,
                    child: Text(
                      gb == null ? l10n.downloadNoLimit : l10n.gbValue(gb),
                    ),
                  ),
              ],
            ),
          ),
        SwitchListTile(
          secondary: const Icon(Icons.favorite_border),
          title: Text(l10n.downloadAutoFavorites),
          value: s.autoFavorites,
          onChanged: (v) =>
              unawaited(c.update((s) => s.copyWith(autoFavorites: v))),
        ),
      ],
    );
  }
}
