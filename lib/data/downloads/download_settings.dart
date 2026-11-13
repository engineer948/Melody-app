import 'dart:convert';

import 'package:melody/core/settings/preferences.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'download_settings.g.dart';

/// Preferences for offline downloads.
@immutable
class DownloadSettings {
  /// Creates the settings.
  const DownloadSettings({
    this.wifiOnly = true,
    this.parallel = 2,
    this.bitrate,
    this.format = StreamFormat.original,
    this.autoFavorites = false,
    this.syncedPlaylists = const {},
    this.syncLibrary = false,
    this.libraryLimitGb,
  });

  /// Restores settings saved with [toJson].
  factory DownloadSettings.fromJson(Map<String, dynamic> json) =>
      DownloadSettings(
        wifiOnly: json['wifiOnly'] as bool? ?? true,
        parallel: (json['parallel'] as int? ?? 2).clamp(1, 4),
        bitrate: json['bitrate'] as int?,
        format:
            StreamFormat.values.asNameMap()[json['format']] ??
            StreamFormat.original,
        autoFavorites: json['autoFavorites'] as bool? ?? false,
        syncedPlaylists: (json['syncedPlaylists'] as List<dynamic>? ?? const [])
            .cast<String>()
            .toSet(),
        syncLibrary: json['syncLibrary'] as bool? ?? false,
        libraryLimitGb: json['libraryLimitGb'] as int?,
      );

  /// Whether downloads wait for Wi-Fi.
  final bool wifiOnly;

  /// Number of files fetched at the same time (1–4).
  final int parallel;

  /// Bitrate limit in kbps; `null` keeps the original file.
  final int? bitrate;

  /// Wanted format.
  final StreamFormat format;

  /// Whether favourite songs are downloaded automatically.
  final bool autoFavorites;

  /// Playlists kept in sync, as `<account id>|<playlist id>`.
  final Set<String> syncedPlaylists;

  /// Whether the whole library is downloaded (newest first) and new songs
  /// follow automatically.
  final bool syncLibrary;

  /// Space the library download may use, in GB; `null` means no limit.
  final int? libraryLimitGb;

  /// Choices for [libraryLimitGb].
  static const libraryLimitChoices = <int?>[null, 2, 5, 10, 20, 50];

  /// Quality the files are requested in.
  StreamOptions get options =>
      StreamOptions(maxBitrateKbps: bitrate, format: format);

  /// Key of a playlist in [syncedPlaylists].
  static String playlistKey(String accountId, String playlistId) =>
      '$accountId|$playlistId';

  /// Returns a copy with the given fields replaced; [clearBitrate] goes
  /// back to the original quality.
  DownloadSettings copyWith({
    bool? wifiOnly,
    int? parallel,
    int? bitrate,
    bool clearBitrate = false,
    StreamFormat? format,
    bool? autoFavorites,
    Set<String>? syncedPlaylists,
    bool? syncLibrary,
    int? libraryLimitGb,
    bool clearLibraryLimit = false,
  }) => DownloadSettings(
    wifiOnly: wifiOnly ?? this.wifiOnly,
    parallel: parallel ?? this.parallel,
    bitrate: clearBitrate ? null : bitrate ?? this.bitrate,
    format: format ?? this.format,
    autoFavorites: autoFavorites ?? this.autoFavorites,
    syncedPlaylists: syncedPlaylists ?? this.syncedPlaylists,
    syncLibrary: syncLibrary ?? this.syncLibrary,
    libraryLimitGb: clearLibraryLimit
        ? null
        : libraryLimitGb ?? this.libraryLimitGb,
  );

  /// Serialises the settings.
  Map<String, dynamic> toJson() => {
    'wifiOnly': wifiOnly,
    'parallel': parallel,
    'bitrate': bitrate,
    'format': format.name,
    'autoFavorites': autoFavorites,
    'syncedPlaylists': syncedPlaylists.toList(),
    'syncLibrary': syncLibrary,
    'libraryLimitGb': libraryLimitGb,
  };
}

/// Holds and persists [DownloadSettings].
@Riverpod(keepAlive: true)
class DownloadSettingsController extends _$DownloadSettingsController {
  /// Preference key.
  static const key = 'downloads.settings';

  @override
  DownloadSettings build() {
    final raw = ref.watch(preferencesProvider).getString(key);
    if (raw == null) return const DownloadSettings();
    try {
      return DownloadSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return const DownloadSettings();
    }
  }

  /// Applies [change] and saves the result.
  Future<void> update(
    DownloadSettings Function(DownloadSettings current) change,
  ) async {
    state = change(state);
    await ref.read(preferencesProvider).setString(key, jsonEncode(state));
  }
}
