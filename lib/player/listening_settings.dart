import 'dart:convert';

import 'package:melody/core/settings/preferences.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'listening_settings.g.dart';

/// How the queue is extended when it runs out.
enum AutoDjMode {
  /// The source's "instant mix" of the last track.
  similar,

  /// More of the same artist.
  artist,

  /// More of the same genre.
  genre,

  /// Anything from the library.
  random,

  /// Picked by the on-device suggestions.
  smart,
}

/// Listening history, suggestions and Auto DJ preferences.
@immutable
class ListeningSettings {
  /// Creates the settings.
  const ListeningSettings({
    this.history = true,
    this.suggestions = true,
    this.autoDj = false,
    this.autoDjMode = AutoDjMode.similar,
    this.autoDjThreshold = 1,
  });

  /// Restores settings saved with [toJson].
  factory ListeningSettings.fromJson(Map<String, dynamic> json) =>
      ListeningSettings(
        history: json['history'] as bool? ?? true,
        suggestions: json['suggestions'] as bool? ?? true,
        autoDj: json['autoDj'] as bool? ?? false,
        autoDjMode:
            AutoDjMode.values.asNameMap()[json['autoDjMode']] ??
            AutoDjMode.similar,
        autoDjThreshold: json['autoDjThreshold'] as int? ?? 1,
      );

  /// Whether plays are recorded on the device.
  final bool history;

  /// Whether suggestions are shown on the home tab.
  final bool suggestions;

  /// Whether the queue is extended automatically.
  final bool autoDj;

  /// Where Auto DJ takes tracks from.
  final AutoDjMode autoDjMode;

  /// Auto DJ adds tracks when this many (or fewer) remain after the current
  /// one.
  final int autoDjThreshold;

  /// Returns a copy with the given fields replaced.
  ListeningSettings copyWith({
    bool? history,
    bool? suggestions,
    bool? autoDj,
    AutoDjMode? autoDjMode,
    int? autoDjThreshold,
  }) => ListeningSettings(
    history: history ?? this.history,
    suggestions: suggestions ?? this.suggestions,
    autoDj: autoDj ?? this.autoDj,
    autoDjMode: autoDjMode ?? this.autoDjMode,
    autoDjThreshold: autoDjThreshold ?? this.autoDjThreshold,
  );

  /// Serialises the settings.
  Map<String, dynamic> toJson() => {
    'history': history,
    'suggestions': suggestions,
    'autoDj': autoDj,
    'autoDjMode': autoDjMode.name,
    'autoDjThreshold': autoDjThreshold,
  };

  @override
  bool operator ==(Object other) =>
      other is ListeningSettings &&
      other.history == history &&
      other.suggestions == suggestions &&
      other.autoDj == autoDj &&
      other.autoDjMode == autoDjMode &&
      other.autoDjThreshold == autoDjThreshold;

  @override
  int get hashCode =>
      Object.hash(history, suggestions, autoDj, autoDjMode, autoDjThreshold);
}

/// Holds and persists [ListeningSettings].
@Riverpod(keepAlive: true)
class ListeningSettingsController extends _$ListeningSettingsController {
  /// Preference key.
  static const key = 'player.listening';

  @override
  ListeningSettings build() {
    final raw = ref.watch(preferencesProvider).getString(key);
    if (raw == null) return const ListeningSettings();
    try {
      return ListeningSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on Object {
      return const ListeningSettings();
    }
  }

  /// Applies [change] and saves the result.
  Future<void> update(
    ListeningSettings Function(ListeningSettings current) change,
  ) async {
    state = change(state);
    await ref.read(preferencesProvider).setString(key, jsonEncode(state));
  }
}
