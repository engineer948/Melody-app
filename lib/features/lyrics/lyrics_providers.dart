import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/device/client_identity.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/data/repositories/catalog_cache.dart';
import 'package:melody/data/sources/lrclib/lrclib_client.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lyrics_providers.g.dart';

/// How lyrics are fetched and shown.
@immutable
class LyricsSettings {
  /// Creates the settings.
  const LyricsSettings({
    this.useLrclib = false,
    this.alignCenter = false,
    this.fontScale = 1,
    this.offsetsMs = const {},
  });

  /// Restores settings saved with [toJson].
  factory LyricsSettings.fromJson(Map<String, dynamic> json) => LyricsSettings(
    useLrclib: json['useLrclib'] as bool? ?? false,
    alignCenter: json['alignCenter'] as bool? ?? false,
    fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1,
    offsetsMs: {
      for (final e
          in (json['offsetsMs'] as Map<String, dynamic>? ?? {}).entries)
        e.key: e.value as int,
    },
  );

  /// Whether LRCLIB is asked when the server has no lyrics. Off by default
  /// because it sends track details to a third party.
  final bool useLrclib;

  /// Whether lines are centred.
  final bool alignCenter;

  /// Text size factor, 0.8 to 1.6.
  final double fontScale;

  /// Per-track timing correction; positive shows lines later.
  final Map<String, int> offsetsMs;

  /// Timing correction of [trackId].
  Duration offsetOf(String trackId) =>
      Duration(milliseconds: offsetsMs[trackId] ?? 0);

  /// Returns a copy with the given fields replaced.
  LyricsSettings copyWith({
    bool? useLrclib,
    bool? alignCenter,
    double? fontScale,
    Map<String, int>? offsetsMs,
  }) => LyricsSettings(
    useLrclib: useLrclib ?? this.useLrclib,
    alignCenter: alignCenter ?? this.alignCenter,
    fontScale: fontScale ?? this.fontScale,
    offsetsMs: offsetsMs ?? this.offsetsMs,
  );

  /// Serialises the settings.
  Map<String, dynamic> toJson() => {
    'useLrclib': useLrclib,
    'alignCenter': alignCenter,
    'fontScale': fontScale,
    'offsetsMs': offsetsMs,
  };
}

/// Holds and persists [LyricsSettings].
@Riverpod(keepAlive: true)
class LyricsSettingsController extends _$LyricsSettingsController {
  /// Preference key.
  static const key = 'lyrics.settings';

  @override
  LyricsSettings build() {
    final raw = ref.watch(preferencesProvider).getString(key);
    if (raw == null) return const LyricsSettings();
    try {
      return LyricsSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return const LyricsSettings();
    }
  }

  /// Applies [change] and saves the result.
  Future<void> update(LyricsSettings Function(LyricsSettings s) change) async {
    state = change(state);
    await ref.read(preferencesProvider).setString(key, jsonEncode(state));
  }

  /// Shifts the lyrics of [trackId] by [delta].
  Future<void> shift(String trackId, Duration delta) => update((s) {
    final next = s.offsetOf(trackId) + delta;
    return s.copyWith(
      offsetsMs: {...s.offsetsMs, trackId: next.inMilliseconds}
        ..removeWhere((_, v) => v == 0),
    );
  });
}

/// LRCLIB client; overridden in tests.
@Riverpod(keepAlive: true)
LrclibClient lrclib(Ref ref) {
  final client = LrclibClient(
    version: ref.watch(clientIdentityProvider).version,
  );
  ref.onDispose(client.close);
  return client;
}

/// Lyrics of [track]: cache, then the server, then LRCLIB (when allowed).
/// `null` means there are none.
@riverpod
Future<Lyrics?> trackLyrics(Ref ref, Track track) async {
  final source = ref.watch(activeSourceProvider);
  final accountId = ref.watch(
    sessionControllerProvider.select((s) => s.activeId),
  );
  final useLrclib = ref.watch(
    lyricsSettingsControllerProvider.select((s) => s.useLrclib),
  );
  if (source == null || accountId == null) return null;
  final cache = ref.read(catalogCacheProvider);
  try {
    final cached = await cache.readItem(accountId, CacheKind.lyrics, track.id);
    if (cached != null) return cached.lyrics;
  } on Object {
    // A broken cache only costs a network request.
  }
  Lyrics? found;
  if (source.capabilities.lyrics) {
    found = (await source.lyrics(track)).valueOrNull;
  }
  if (found == null && useLrclib) {
    found = (await ref.read(lrclibProvider).lookup(track)).valueOrNull;
  }
  if (found != null) {
    try {
      await cache.writeItem(
        accountId,
        CacheKind.lyrics,
        TrackLyrics(trackId: track.id, lyrics: found),
      );
    } on Object {
      // Not cached; fetched again next time.
    }
  }
  return found;
}
