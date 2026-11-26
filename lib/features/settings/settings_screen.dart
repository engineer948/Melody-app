import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/config/app_config.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/features/home/home_shelves.dart';
import 'package:melody/features/settings/app_info.dart';
import 'package:melody/features/settings/legal_screen.dart';
import 'package:melody/features/settings/update_check.dart';
import 'package:melody/features/settings/widgets/account_section.dart';
import 'package:melody/features/settings/widgets/android_auto_section.dart';
import 'package:melody/features/settings/widgets/appearance_section.dart';
import 'package:melody/features/settings/widgets/auto_dj_section.dart';
import 'package:melody/features/settings/widgets/backup_section.dart';
import 'package:melody/features/settings/widgets/downloads_section.dart';
import 'package:melody/features/settings/widgets/language_section.dart';
import 'package:melody/features/settings/widgets/media_sections.dart';
import 'package:melody/features/settings/widgets/playback_section.dart';
import 'package:melody/features/settings/widgets/privacy_section.dart';
import 'package:melody/features/settings/widgets/section_header.dart';
import 'package:melody/features/tailnet/tailnet_section.dart';
import 'package:melody/l10n/l10n.dart';

/// A part of the settings, found by its title and the keywords of its
/// rows.
typedef _Section = ({String title, List<String> keywords, List<Widget> rows});

/// Application settings, with a search over their sections.
class SettingsScreen extends ConsumerStatefulWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _query;

  List<_Section> _sections(AppLocalizations l10n, String? version) => [
    (
      title: l10n.settingsAccounts,
      keywords: [l10n.accountAdd, l10n.accountLibrary, l10n.accountSignOut],
      rows: const [AccountSection()],
    ),
    (
      title: l10n.tailnetSection,
      keywords: ['Tailscale', l10n.tailnetJoin, l10n.tailnetInviteCreate],
      rows: const [TailnetSection()],
    ),
    (
      title: l10n.settingsAppearance,
      keywords: [
        l10n.themeDark,
        l10n.themeLight,
        l10n.settingsPureBlack,
        l10n.settingsFont,
        l10n.lookCassette,
        l10n.lookMovingLyrics,
      ],
      rows: const [AppearanceSection()],
    ),
    (
      title: l10n.settingsHome,
      keywords: [l10n.homeShelves, l10n.homeShelvesSubtitle],
      rows: [
        ListTile(
          leading: const Icon(Icons.view_agenda_outlined),
          title: Text(l10n.homeShelves),
          subtitle: Text(l10n.homeShelvesSubtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const HomeShelvesScreen()),
          ),
        ),
      ],
    ),
    (
      title: l10n.settingsPlayback,
      keywords: [
        l10n.crossfade,
        l10n.equalizer,
        l10n.replayGain,
        l10n.fadeLength,
        l10n.autoDj,
        l10n.autoDjMode,
      ],
      rows: const [PlaybackSection(), AutoDjSection()],
    ),
    (
      title: l10n.settingsStreaming,
      keywords: [
        l10n.qualityPreset,
        l10n.qualityBest,
        l10n.qualityBalanced,
        l10n.qualitySaver,
        l10n.streamWifi,
        l10n.streamMobile,
        l10n.streamFormat,
        l10n.dataSaver,
      ],
      rows: const [StreamingSection()],
    ),
    (
      title: l10n.settingsDownloads,
      keywords: [
        l10n.downloadWifiOnly,
        l10n.downloadQuality,
        l10n.downloadSaveSpace,
        l10n.downloadSyncLibrary,
        l10n.downloadAutoFavorites,
        l10n.downloadParallel,
      ],
      rows: const [DownloadsSection()],
    ),
    (
      title: l10n.settingsLyrics,
      keywords: [
        l10n.lyricsUseLrclib,
        l10n.lyricsAutoSync,
        l10n.lyricsAlignCenter,
        l10n.lyricsFontSize,
      ],
      rows: const [LyricsSection()],
    ),
    (
      title: l10n.settingsStorage,
      keywords: [l10n.cacheLimit, l10n.cacheClear],
      rows: const [StorageSection()],
    ),
    if (Platform.isAndroid)
      (
        title: l10n.settingsAndroidAuto,
        keywords: [l10n.androidAutoBody],
        rows: const [AndroidAutoSection()],
      ),
    (
      title: l10n.backupSection,
      keywords: [l10n.backupExport, l10n.backupRestore],
      rows: const [BackupSection()],
    ),
    (
      title: l10n.settingsPrivacy,
      keywords: [
        l10n.privacyHistory,
        l10n.privacyClearHistory,
        l10n.privacySuggestions,
        l10n.lifeSwitch,
        l10n.placeReminders,
        l10n.statsTitle,
      ],
      rows: const [PrivacySection()],
    ),
    (
      title: l10n.settingsLanguage,
      keywords: [
        l10n.languageEnglish,
        l10n.languageTurkish,
        l10n.languageAzerbaijani,
      ],
      rows: const [LanguageSection()],
    ),
    (
      title: l10n.settingsAbout,
      keywords: [l10n.aboutVersion, l10n.legalTitle, l10n.aboutLicenses],
      rows: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(l10n.aboutVersion),
          subtitle: version == null ? null : Text(version),
        ),
        const UpdateCheckTile(),
        if (kDebugMode)
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: Text(l10n.debugSourcesTitle),
            onTap: () =>
                context.push('${AppRoutes.settingsIn(context)}/debug-sources'),
          ),
        ListTile(
          leading: const Icon(Icons.gavel_outlined),
          title: Text(l10n.legalTitle),
          onTap: () => unawaited(showLegal(context)),
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
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final version = ref.watch(appVersionProvider).value;
    final query = _query?.trim().toLowerCase() ?? '';
    final sections = [
      for (final s in _sections(l10n, version))
        if (query.isEmpty ||
            [
              s.title,
              ...s.keywords,
            ].any((k) => k.toLowerCase().contains(query)))
          s,
    ];
    return Scaffold(
      appBar: AppBar(
        title: _query == null
            ? Text(l10n.settingsTitle)
            : TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.settingsSearch,
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
        actions: [
          IconButton(
            tooltip: _query == null
                ? l10n.settingsSearch
                : MaterialLocalizations.of(context).closeButtonTooltip,
            icon: Icon(
              _query == null ? Icons.search_rounded : Icons.close_rounded,
            ),
            onPressed: () =>
                setState(() => _query = _query == null ? '' : null),
          ),
        ],
      ),
      body: sections.isEmpty
          ? Center(child: Text(l10n.settingsSearchEmpty))
          : ListView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 16,
              ),
              children: [
                for (final s in sections) ...[
                  SectionHeader(s.title),
                  ...s.rows,
                ],
              ],
            ),
    );
  }
}
