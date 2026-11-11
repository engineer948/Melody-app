import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/config/app_config.dart';
import 'package:melody/features/settings/app_info.dart';
import 'package:melody/features/settings/widgets/account_section.dart';
import 'package:melody/features/settings/widgets/appearance_section.dart';
import 'package:melody/features/settings/widgets/auto_dj_section.dart';
import 'package:melody/features/settings/widgets/downloads_section.dart';
import 'package:melody/features/settings/widgets/language_section.dart';
import 'package:melody/features/settings/widgets/media_sections.dart';
import 'package:melody/features/settings/widgets/playback_section.dart';
import 'package:melody/features/settings/widgets/privacy_section.dart';
import 'package:melody/features/settings/widgets/section_header.dart';
import 'package:melody/l10n/l10n.dart';

/// Application settings.
class SettingsScreen extends ConsumerWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final version = ref.watch(appVersionProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 16,
        ),
        children: [
          SectionHeader(l10n.settingsAccounts),
          const AccountSection(),
          SectionHeader(l10n.settingsAppearance),
          const AppearanceSection(),
          SectionHeader(l10n.settingsPlayback),
          const PlaybackSection(),
          const AutoDjSection(),
          SectionHeader(l10n.settingsStreaming),
          const StreamingSection(),
          SectionHeader(l10n.settingsDownloads),
          const DownloadsSection(),
          SectionHeader(l10n.settingsLyrics),
          const LyricsSection(),
          SectionHeader(l10n.settingsStorage),
          const StorageSection(),
          SectionHeader(l10n.settingsPrivacy),
          const PrivacySection(),
          SectionHeader(l10n.settingsLanguage),
          const LanguageSection(),
          SectionHeader(l10n.settingsAbout),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.aboutVersion),
            subtitle: version == null ? null : Text(version),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.aboutLicenses),
            onTap: () => showLicensePage(
              context: context,
              applicationName: AppConfig.appName,
              applicationVersion: version,
            ),
          ),
        ],
      ),
    );
  }
}
