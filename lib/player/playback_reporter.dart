import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:melody/domain/repositories/music_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sends start / progress / stop reports to the source.
///
/// Reports that fail (e.g. offline) are kept and sent with the next
/// successful one, so play counts stay right.
class PlaybackReporter {
  /// Creates a reporter.
  PlaybackReporter({required this.source, required this._prefs, Random? random})
    : _random = random ?? Random();

  /// Where reports go.
  final MusicSource? Function() source;

  final SharedPreferences _prefs;
  final Random _random;

  /// Preference key of unsent reports.
  static const pendingKey = 'player.pendingReports';

  /// Oldest reports are dropped beyond this many.
  static const maxPending = 200;

  String? _session;
  String? _trackId;
  bool _flushing = false;

  /// Unsent reports.
  List<PlaybackReport> get pending => [
    for (final raw in _prefs.getStringList(pendingKey) ?? const <String>[])
      PlaybackReport.fromJson(jsonDecode(raw) as Map<String, dynamic>),
  ];

  Future<void> _save(List<PlaybackReport> reports) =>
      _prefs.setStringList(pendingKey, [
        for (final r in reports.skip(max(0, reports.length - maxPending)))
          jsonEncode(r.toJson()),
      ]);

  Future<void> _send(PlaybackReport report) async {
    final target = source();
    if (target == null || !target.capabilities.playbackReporting) return;
    final queued = [...pending, report];
    if (_flushing) {
      await _save(queued);
      return;
    }
    _flushing = true;
    try {
      var sent = 0;
      for (final item in queued) {
        if (!(await target.reportPlayback(item)).isOk) break;
        sent++;
      }
      await _save(queued.sublist(sent));
    } finally {
      _flushing = false;
    }
  }

  String _newSession() =>
      List.generate(16, (_) => _random.nextInt(16).toRadixString(16)).join();

  /// A new track started.
  Future<void> started(String trackId, Duration position) {
    _trackId = trackId;
    _session = _newSession();
    return _send(
      PlaybackReport(
        kind: PlaybackEventKind.start,
        trackId: trackId,
        position: position,
        sessionId: _session!,
      ),
    );
  }

  /// Periodic update or a pause / resume.
  Future<void> progress(Duration position, {required bool paused}) async {
    final trackId = _trackId;
    final session = _session;
    if (trackId == null || session == null) return;
    await _send(
      PlaybackReport(
        kind: PlaybackEventKind.progress,
        trackId: trackId,
        position: position,
        sessionId: session,
        isPaused: paused,
      ),
    );
  }

  /// The current track ended or was left.
  Future<void> stopped(Duration position) async {
    final trackId = _trackId;
    final session = _session;
    _trackId = null;
    _session = null;
    if (trackId == null || session == null) return;
    await _send(
      PlaybackReport(
        kind: PlaybackEventKind.stopped,
        trackId: trackId,
        position: position,
        sessionId: session,
      ),
    );
  }
}
