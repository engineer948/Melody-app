/// Kinds of music backends the code base knows about.
enum SourceType {
  /// Jellyfin media server.
  jellyfin,

  /// Emby media server.
  emby,

  /// Subsonic / OpenSubsonic compatible servers.
  subsonic,

  /// Audio files stored on the device.
  local,

  /// Internet radio stations.
  radio,
}

/// Build-time switches deciding which features are exposed in the UI.
///
/// Sources are selected with
/// `--dart-define=ENABLED_SOURCES=jellyfin,subsonic,local`. Anything that is
/// not listed stays compiled in but is never offered to the user.
abstract final class FeatureFlags {
  static const String _rawSources = String.fromEnvironment('ENABLED_SOURCES');

  /// Source used when nothing (or nothing valid) is configured.
  static const Set<SourceType> defaultSources = {SourceType.jellyfin};

  /// Sources the UI is allowed to list.
  static final Set<SourceType> enabledSources = parseSources(_rawSources);

  /// Whether [type] may be shown to the user.
  static bool isEnabled(SourceType type) => enabledSources.contains(type);

  /// Whether a source picker is needed at all.
  static bool get hasMultipleSources => enabledSources.length > 1;

  /// Parses a comma separated list of [SourceType] names.
  ///
  /// Unknown names are ignored. An empty result falls back to
  /// [defaultSources] so the app can never end up without a source.
  static Set<SourceType> parseSources(String raw) {
    final byName = SourceType.values.asNameMap();
    final parsed = raw
        .split(',')
        .map((name) => byName[name.trim().toLowerCase()])
        .nonNulls
        .toSet();
    return parsed.isEmpty ? defaultSources : Set.unmodifiable(parsed);
  }
}
