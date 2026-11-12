import 'dart:async';

import 'package:melody/data/history/history_store.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/stats/play_event.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/player/listening_settings.dart';
import 'package:melody/player/player_controller.dart';
import 'package:melody/player/player_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_recorder.g.dart';

/// The on-device listening history.
@Riverpod(keepAlive: true)
HistoryStore historyStore(Ref ref) =>
    HistoryStore(ref.watch(appDatabaseProvider));

/// Bumped whenever the history changes, so statistics and suggestions
/// refresh.
@Riverpod(keepAlive: true)
class HistoryRevision extends _$HistoryRevision {
  @override
  int build() => 0;

  /// Signals a change.
  void bump() => state++;
}

/// Turns player states into history entries: which track, when, and for how
/// long it was really heard (pauses do not count).
class HistoryRecorder {
  /// Creates a recorder; [save] receives every finished play.
  HistoryRecorder({required this.save, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Stores one finished play.
  final Future<void> Function(PlayEvent event) save;

  final DateTime Function() _clock;

  int? _uid;
  Track? _track;
  DateTime? _startedAt;
  DateTime? _playingSince;
  Duration _listened = Duration.zero;

  /// Feeds the next player state.
  void onState(PlayerState state) {
    final entry = state.queue.current;
    if (entry?.uid != _uid) {
      _finish();
      _uid = entry?.uid;
      _track = entry?.track;
    }
    final now = _clock();
    if (state.playing && _track != null) {
      _startedAt ??= now;
      _playingSince ??= now;
    } else if (_playingSince != null) {
      _listened += now.difference(_playingSince!);
      _playingSince = null;
      // The track ran to its end (e.g. the last one of the queue).
      final duration = state.duration ?? _track?.duration;
      if (duration != null &&
          _listened.inMilliseconds >= duration.inMilliseconds * 0.9) {
        _finish();
      }
    }
  }

  /// Writes the play in progress, e.g. before the app goes away.
  void flush() => _finish();

  void _finish() {
    final track = _track;
    final startedAt = _startedAt;
    var listened = _listened;
    final since = _playingSince;
    final now = _clock();
    if (since != null) {
      listened += now.difference(since);
      _playingSince = now;
    }
    _listened = Duration.zero;
    _startedAt = since == null ? null : now;
    if (track == null || startedAt == null) return;
    if (listened < PlayEvent.minListen) return;
    unawaited(
      save(
        PlayEvent(
          track: track,
          startedAt: startedAt,
          listened: listened,
          skipped: PlayEvent.isSkip(listened, track.duration),
        ),
      ),
    );
  }
}

/// Records what is played into the history while it is enabled.
@Riverpod(keepAlive: true)
HistoryRecorder historyRecorder(Ref ref) {
  final recorder = HistoryRecorder(
    save: (event) async {
      final accountId = ref.read(sessionControllerProvider).activeId;
      if (accountId == null ||
          !ref.read(listeningSettingsControllerProvider).history) {
        return;
      }
      try {
        await ref.read(historyStoreProvider).add(accountId, event);
        if (ref.mounted) ref.read(historyRevisionProvider.notifier).bump();
      } on Object {
        // Statistics are optional; playback must never suffer.
      }
    },
  );
  ref
    ..listen(
      playerControllerProvider,
      (_, state) => recorder.onState(state),
      fireImmediately: true,
    )
    ..onDispose(recorder.flush);
  return recorder;
}
