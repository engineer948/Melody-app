import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where releases are published.
const releasesApi =
    'https://api.github.com/repos/engineer948/Melody-app/releases/latest';

/// A newer release than the installed one.
@immutable
class AvailableUpdate {
  /// Creates the entry.
  const AvailableUpdate({required this.version, required this.page});

  /// e.g. `0.13.0`.
  final String version;

  /// Release page with the APKs.
  final Uri page;
}

/// Whether [latest] (e.g. `0.13.0`) is newer than [current] (`0.12.0`).
bool isNewerVersion(String latest, String current) {
  List<int> parts(String v) => [
    for (final p in v.split('+').first.split('.'))
      int.tryParse(p.replaceAll(RegExp('[^0-9]'), '')) ?? 0,
  ];
  final a = parts(latest);
  final b = parts(current);
  for (var i = 0; i < 3; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}

/// Preference: look for new versions on GitHub (on by default).
class UpdateCheckSetting extends Notifier<bool> {
  /// Preference key.
  static const key = 'update.check';

  @override
  bool build() => ref.watch(preferencesProvider).getBool(key) ?? true;

  /// Turns the check on or off.
  Future<void> set({required bool on}) async {
    state = on;
    await ref.read(preferencesProvider).setBool(key, on);
  }
}

/// See [UpdateCheckSetting].
final updateCheckSettingProvider = NotifierProvider<UpdateCheckSetting, bool>(
  UpdateCheckSetting.new,
);

/// Fetches the newest release; overridden in tests.
final latestReleaseFetcherProvider =
    Provider<Future<(String, Uri)?> Function()>(
      (ref) => () async {
        // Never reach the network from tests.
        if (Platform.environment.containsKey('FLUTTER_TEST')) return null;
        final dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Accept': 'application/vnd.github+json'},
          ),
        );
        try {
          final response = await dio.get<Map<String, dynamic>>(releasesApi);
          final tag = response.data?['tag_name'];
          final page = response.data?['html_url'];
          if (tag is! String || page is! String) return null;
          return (tag.replaceFirst('v', ''), Uri.parse(page));
        } finally {
          dio.close();
        }
      },
    );

/// The installed version (e.g. `0.12.0`); overridden in tests.
final installedVersionProvider = FutureProvider<String?>((ref) async {
  try {
    return (await PackageInfo.fromPlatform()).version;
  } on Object {
    // Unknown (tests): never fail, so nothing is retried.
    return null;
  }
});

/// A newer release, checked once per app start; `null` when there is
/// none, the check is off or GitHub cannot be reached. Only the public
/// release list is read; nothing about the user is sent.
final availableUpdateProvider = FutureProvider<AvailableUpdate?>((ref) async {
  if (!ref.watch(updateCheckSettingProvider)) return null;
  try {
    final current = await ref.watch(installedVersionProvider.future);
    if (current == null) return null;
    final latest = await ref.read(latestReleaseFetcherProvider)();
    if (latest == null) return null;
    final (version, page) = latest;
    return isNewerVersion(version, current)
        ? AvailableUpdate(version: version, page: page)
        : null;
  } on Object {
    return null;
  }
});

/// Home screen banner: "Melody X is available".
class UpdateBanner extends ConsumerWidget {
  /// Creates the banner.
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(availableUpdateProvider).value;
    if (update == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ListTile(
        leading: const Icon(Icons.system_update_rounded),
        title: Text(l10n.updateAvailable(update.version)),
        subtitle: Text(l10n.updateAvailableBody),
        trailing: FilledButton.tonal(
          onPressed: () => unawaited(
            launchUrl(update.page, mode: LaunchMode.externalApplication),
          ),
          child: Text(l10n.updateDownload),
        ),
      ),
    );
  }
}

/// Settings switch for [UpdateCheckSetting].
class UpdateCheckTile extends ConsumerWidget {
  /// Creates the switch.
  const UpdateCheckTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SwitchListTile(
      secondary: const Icon(Icons.system_update_outlined),
      title: Text(l10n.updateCheck),
      subtitle: Text(l10n.updateCheckBody),
      value: ref.watch(updateCheckSettingProvider),
      onChanged: (on) =>
          ref.read(updateCheckSettingProvider.notifier).set(on: on),
    );
  }
}
