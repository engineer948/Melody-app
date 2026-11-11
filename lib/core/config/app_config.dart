/// Static, build-time application configuration.
///
/// The product name lives here only, so a rename is a one-line change.
abstract final class AppConfig {
  /// User-facing application name (working title).
  static const String appName = 'Melody';

  /// Client name reported to media servers.
  static const String clientName = appName;

  /// Width (dp) at which the bottom bar is replaced by a navigation rail.
  static const double railBreakpoint = 600;

  /// Width (dp) at which a two-pane layout becomes available.
  static const double twoPaneBreakpoint = 840;
}
