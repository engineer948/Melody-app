import 'dart:convert';
import 'dart:math';

import 'package:melody/core/settings/preferences.dart';
import 'package:melody/domain/models/media.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'playback_settings.g.dart';

/// Which loudness tag is applied.
enum ReplayGainMode {
  /// No adjustment.
  off,

  /// Per-track gain.
  track,

  /// Album gain, so the album's internal dynamics stay intact.
  album,

  /// Album gain when an album is played in order, track gain otherwise.
  auto,
}

/// User preferences of the player.
@immutable
class PlaybackSettings {
  /// Creates the settings.
  const PlaybackSettings({
    this.replayGain = ReplayGainMode.auto,
    this.preampDb = 0,
    this.untaggedGainDb = 0,
    this.fadeMs = 200,
    this.equalizerEnabled = false,
    this.equalizerGains = const [],
    this.loudnessBoostDb = 0,
    this.crossfadeSeconds = 0,
  });

  /// Restores settings saved with [toJson].
  factory PlaybackSettings.fromJson(Map<String, dynamic> json) =>
      PlaybackSettings(
        replayGain:
            ReplayGainMode.values.asNameMap()[json['replayGain']] ??
            ReplayGainMode.auto,
        preampDb: (json['preampDb'] as num?)?.toDouble() ?? 0,
        untaggedGainDb: (json['untaggedGainDb'] as num?)?.toDouble() ?? 0,
        fadeMs: json['fadeMs'] as int? ?? 200,
        equalizerEnabled: json['equalizerEnabled'] as bool? ?? false,
        equalizerGains: [
          for (final g in json['equalizerGains'] as List<dynamic>? ?? const [])
            (g as num).toDouble(),
        ],
        loudnessBoostDb: (json['loudnessBoostDb'] as num?)?.toDouble() ?? 0,
        crossfadeSeconds: json['crossfadeSeconds'] as int? ?? 0,
      );

  /// Loudness normalisation mode.
  final ReplayGainMode replayGain;

  /// Extra gain added to the tag value, in dB.
  final double preampDb;

  /// Gain used for tracks without a tag, in dB.
  final double untaggedGainDb;

  /// Fade length when pausing and resuming; 0 disables it.
  final int fadeMs;

  /// Whether the equaliser is on (Android only).
  final bool equalizerEnabled;

  /// Gain per equaliser band in dB.
  final List<double> equalizerGains;

  /// Loudness enhancer boost in dB (Android only).
  final double loudnessBoostDb;

  /// Overlap between songs in seconds; 0 disables crossfade.
  final int crossfadeSeconds;

  /// Returns a copy with the given fields replaced.
  PlaybackSettings copyWith({
    ReplayGainMode? replayGain,
    double? preampDb,
    double? untaggedGainDb,
    int? fadeMs,
    bool? equalizerEnabled,
    List<double>? equalizerGains,
    double? loudnessBoostDb,
    int? crossfadeSeconds,
  }) => PlaybackSettings(
    replayGain: replayGain ?? this.replayGain,
    preampDb: preampDb ?? this.preampDb,
    untaggedGainDb: untaggedGainDb ?? this.untaggedGainDb,
    fadeMs: fadeMs ?? this.fadeMs,
    equalizerEnabled: equalizerEnabled ?? this.equalizerEnabled,
    equalizerGains: equalizerGains ?? this.equalizerGains,
    loudnessBoostDb: loudnessBoostDb ?? this.loudnessBoostDb,
    crossfadeSeconds: crossfadeSeconds ?? this.crossfadeSeconds,
  );

  /// Serialises the settings.
  Map<String, dynamic> toJson() => {
    'replayGain': replayGain.name,
    'preampDb': preampDb,
    'untaggedGainDb': untaggedGainDb,
    'fadeMs': fadeMs,
    'equalizerEnabled': equalizerEnabled,
    'equalizerGains': equalizerGains,
    'loudnessBoostDb': loudnessBoostDb,
    'crossfadeSeconds': crossfadeSeconds,
  };

  /// Player volume (0–1) for [track].
  ///
  /// [albumInOrder] tells whether an album is being played in its own order.
  /// The volume cannot go above 1, so positive gains are capped: this also
  /// prevents clipping.
  double volumeFor(Track track, {required bool albumInOrder}) {
    final useAlbum = switch (replayGain) {
      ReplayGainMode.off => null,
      ReplayGainMode.track => false,
      ReplayGainMode.album => true,
      ReplayGainMode.auto => albumInOrder,
    };
    if (useAlbum == null) return 1;
    final tag = useAlbum
        ? (track.albumGainDb ?? track.trackGainDb)
        : (track.trackGainDb ?? track.albumGainDb);
    final db = (tag ?? untaggedGainDb) + preampDb;
    return pow(10, db / 20).toDouble().clamp(0.0, 1.0);
  }
}

/// Holds and persists [PlaybackSettings].
@Riverpod(keepAlive: true)
class PlaybackSettingsController extends _$PlaybackSettingsController {
  /// Preference key.
  static const key = 'player.settings';

  @override
  PlaybackSettings build() {
    final raw = ref.watch(preferencesProvider).getString(key);
    if (raw == null) return const PlaybackSettings();
    try {
      return PlaybackSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return const PlaybackSettings();
    }
  }

  /// Applies [change] and saves the result.
  Future<void> update(
    PlaybackSettings Function(PlaybackSettings current) change,
  ) async {
    state = change(state);
    await ref.read(preferencesProvider).setString(key, jsonEncode(state));
  }
}
