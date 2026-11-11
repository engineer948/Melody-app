import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/features/lyrics/lyrics_providers.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/player_controller.dart';
import 'package:melody/player/streaming_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_sections.g.dart';

/// Cache size limits offered (MB); 0 turns the cache off.
const cacheChoices = [0, 256, 512, 1024, 2048, 4096];

/// Bytes currently used by the stream cache.
@riverpod
Future<int> streamCacheSize(Ref ref) => ref.watch(streamCacheProvider).size();

/// Formats [bytes] as MB or GB.
String formatBytes(AppLocalizations l10n, int bytes) {
  final mb = bytes / (1024 * 1024);
  return mb >= 1024
      ? l10n.gbValue((mb / 1024).round())
      : l10n.mbValue(mb.round());
}

/// Wi-Fi and mobile quality, format and data saver.
class StreamingSection extends ConsumerWidget {
  /// Creates the section.
  const StreamingSection({super.key});

  static String _bitrate(AppLocalizations l10n, int? kbps) =>
      kbps == null ? l10n.streamOriginal : l10n.kbpsValue(kbps);

  static String _format(AppLocalizations l10n, StreamFormat f) => switch (f) {
    StreamFormat.original => l10n.streamOriginal,
    StreamFormat.opus => 'Opus',
    StreamFormat.aac => 'AAC',
    StreamFormat.mp3 => 'MP3',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(streamingSettingsControllerProvider);
    final c = ref.read(streamingSettingsControllerProvider.notifier);
    Widget bitrateTile(
      IconData icon,
      String title,
      int? value,
      StreamingSettings Function(int? v) apply,
    ) => ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: DropdownButton<int?>(
        value: value,
        underline: const SizedBox.shrink(),
        onChanged: (v) => unawaited(c.update((_) => apply(v))),
        items: [
          for (final b in bitrateChoices)
            DropdownMenuItem(value: b, child: Text(_bitrate(l10n, b))),
        ],
      ),
    );
    return Column(
      children: [
        bitrateTile(
          Icons.wifi,
          l10n.streamWifi,
          s.wifiBitrate,
          (v) => s.copyWith(wifiBitrate: v, clearWifi: v == null),
        ),
        bitrateTile(
          Icons.signal_cellular_alt,
          l10n.streamMobile,
          s.mobileBitrate,
          (v) => s.copyWith(mobileBitrate: v, clearMobile: v == null),
        ),
        ListTile(
          leading: const Icon(Icons.audio_file_outlined),
          title: Text(l10n.streamFormat),
          trailing: DropdownButton<StreamFormat>(
            value: s.format,
            underline: const SizedBox.shrink(),
            onChanged: (f) {
              if (f != null) unawaited(c.update((s) => s.copyWith(format: f)));
            },
            items: [
              for (final f in StreamFormat.values)
                DropdownMenuItem(value: f, child: Text(_format(l10n, f))),
            ],
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.data_saver_on_outlined),
          title: Text(l10n.dataSaver),
          subtitle: Text(l10n.dataSaverBody),
          value: s.dataSaver,
          onChanged: (v) =>
              unawaited(c.update((s) => s.copyWith(dataSaver: v))),
        ),
      ],
    );
  }
}

/// Size limit and clearing of the song cache.
class StorageSection extends ConsumerWidget {
  /// Creates the section.
  const StorageSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(streamingSettingsControllerProvider);
    final c = ref.read(streamingSettingsControllerProvider.notifier);
    final used = ref.watch(streamCacheSizeProvider).value;
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.sd_storage_outlined),
          title: Text(l10n.cacheLimit),
          subtitle: Text(
            [
              if (used != null) l10n.cacheUsed(formatBytes(l10n, used)),
              l10n.cacheOnlyOriginal,
            ].join('\n'),
          ),
          isThreeLine: used != null,
          trailing: DropdownButton<int>(
            value: cacheChoices.contains(s.cacheMb) ? s.cacheMb : 512,
            underline: const SizedBox.shrink(),
            onChanged: (v) {
              if (v != null) unawaited(c.update((s) => s.copyWith(cacheMb: v)));
            },
            items: [
              for (final mb in cacheChoices)
                DropdownMenuItem(
                  value: mb,
                  child: Text(
                    mb == 0 ? l10n.cacheOff : formatBytes(l10n, mb << 20),
                  ),
                ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.delete_sweep_outlined),
          title: Text(l10n.cacheClear),
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            await ref.read(streamCacheProvider).clear();
            ref.invalidate(streamCacheSizeProvider);
            messenger.showSnackBar(SnackBar(content: Text(l10n.cacheCleared)));
          },
        ),
      ],
    );
  }
}

/// Lyrics source, alignment and size.
class LyricsSection extends ConsumerWidget {
  /// Creates the section.
  const LyricsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(lyricsSettingsControllerProvider);
    final c = ref.read(lyricsSettingsControllerProvider.notifier);
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.travel_explore),
          title: Text(l10n.lyricsUseLrclib),
          subtitle: Text(l10n.lyricsUseLrclibBody),
          isThreeLine: true,
          value: s.useLrclib,
          onChanged: (v) =>
              unawaited(c.update((s) => s.copyWith(useLrclib: v))),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.format_align_center),
          title: Text(l10n.lyricsAlignCenter),
          value: s.alignCenter,
          onChanged: (v) =>
              unawaited(c.update((s) => s.copyWith(alignCenter: v))),
        ),
        ListTile(
          leading: const Icon(Icons.format_size),
          title: Text(l10n.lyricsFontSize),
          subtitle: Slider(
            value: s.fontScale.clamp(0.8, 1.6),
            min: 0.8,
            max: 1.6,
            divisions: 8,
            label: '${(s.fontScale * 100).round()}%',
            onChanged: (v) =>
                unawaited(c.update((s) => s.copyWith(fontScale: v))),
          ),
        ),
      ],
    );
  }
}
