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
    this.autoSync = true,
    this.autoOffsetsMs = const {},
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
    autoSync: json['autoSync'] as bool? ?? true,
    autoOffsetsMs: {
      for (final e
          in (json['autoOffsets2'] as Map<String, dynamic>? ?? {}).entries)
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

  /// Per-track timing correction set by hand; positive shows lines later.
  final Map<String, int> offsetsMs;

  /// Whether synced lyrics are shifted by where the music really starts.
  final bool autoSync;

  /// Corrections found automatically, per track (kept so each song is
  /// measured once).
  final Map<String, int> autoOffsetsMs;

  /// Whether [trackId] was corrected by hand.
  bool isManual(String trackId) => offsetsMs.containsKey(trackId);

  /// Timing correction of [trackId]: by hand first, else the automatic one.
  Duration offsetOf(String trackId) => Duration(
    milliseconds:
        offsetsMs[trackId] ?? (autoSync ? autoOffsetsMs[trackId] ?? 0 : 0),
  );

  /// Returns a copy with the given fields replaced.
  LyricsSettings copyWith({
    bool? useLrclib,
    bool? alignCenter,
    double? fontScale,
    Map<String, int>? offsetsMs,
    bool? autoSync,
    Map<String, int>? autoOffsetsMs,
  }) => LyricsSettings(
    useLrclib: useLrclib ?? this.useLrclib,
    alignCenter: alignCenter ?? this.alignCenter,
    fontScale: fontScale ?? this.fontScale,
    offsetsMs: offsetsMs ?? this.offsetsMs,
    autoSync: autoSync ?? this.autoSync,
    autoOffsetsMs: autoOffsetsMs ?? this.autoOffsetsMs,
  );

  /// Serialises the settings.
  Map<String, dynamic> toJson() => {
    'useLrclib': useLrclib,
    'alignCenter': alignCenter,
    'fontScale': fontScale,
    'offsetsMs': offsetsMs,
    'autoSync': autoSync,
    // Renamed when the singing started to count: older measurements of
    // the silence alone are made again.
    'autoOffsets2': autoOffsetsMs,
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

  /// Shifts the lyrics of [trackId] by [delta]; from then on the hand
  /// correction counts, also when it is back at 0.
  Future<void> shift(String trackId, Duration delta) => update((s) {
    final next = s.offsetOf(trackId) + delta;
    final offsets = {...s.offsetsMs, trackId: next.inMilliseconds};
    if (next == Duration.zero && (s.autoOffsetsMs[trackId] ?? 0) == 0) {
      offsets.remove(trackId);
    }
    return s.copyWith(offsetsMs: offsets);
  });

  /// Keeps the automatic correction of [trackId]; only the latest
  /// [maxAutoOffsets] songs are remembered.
  Future<void> setAuto(String trackId, Duration offset) => update((s) {
    final autos = {...s.autoOffsetsMs}
      ..remove(trackId)
      ..[trackId] = offset.inMilliseconds;
    while (autos.length > maxAutoOffsets) {
      autos.remove(autos.keys.first);
    }
    return s.copyWith(autoOffsetsMs: autos);
  });

  /// Forgets the hand correction of [trackId] (back to automatic).
  Future<void> resetManual(String trackId) =>
      update((s) => s.copyWith(offsetsMs: {...s.offsetsMs}..remove(trackId)));
}

/// Songs whose automatic correction is remembered.
const maxAutoOffsets = 3000;

/// Music starting this late is shifted for; less is usual and already in
/// the timings of most lyrics.
const autoSyncMinSilence = Duration(milliseconds: 700);

/// The automatic correction for music that starts at [soundStart]: the
/// lyrics move later by the silence before it, when there is clearly some.
Duration autoLyricsOffset(Duration? soundStart) =>
    soundStart == null || soundStart < autoSyncMinSilence
    ? Duration.zero
    : soundStart;

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
  Lyrics? found;
  try {
    final cached = await cache.readItem(accountId, CacheKind.lyrics, track.id);
    if (cached != null) {
      // Plain lyrics may be upgraded to time-synced ones from LRCLIB.
      if (cached.lyrics.synced || !useLrclib) return cached.lyrics;
      found = cached.lyrics;
    }
  } on Object {
    // A broken cache only costs a network request.
  }
  if (found == null && source.capabilities.lyrics) {
    found = (await source.lyrics(track)).valueOrNull;
  }
  // Lyrics that follow the song: when the server has none, or only plain
  // text, LRCLIB is asked for time-synced lyrics (if allowed).
  if ((found == null || !found.synced) && useLrclib) {
    final online = (await ref.read(lrclibProvider).lookup(track)).valueOrNull;
    if (online != null && (found == null || online.synced)) found = online;
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
