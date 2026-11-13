import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderSubscription;
import 'package:melody/core/logging/app_logger.dart';
import 'package:melody/data/sources/jellyfin/jellyfin_music_source.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/social/social_models.dart';
import 'package:melody/domain/social/sync_play.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/social/social_controller.dart';
import 'package:melody/player/player_controller.dart';
import 'package:melody/player/player_state.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'listen_together.g.dart';

const _log = AppLogger('listen');

/// Listening-together transport of the active account; `null` when the
/// source has none (only Jellyfin / Emby).
@Riverpod(keepAlive: true)
SyncPlayTransport? syncPlayTransport(Ref ref) {
  final source = ref.watch(activeSourceProvider);
  return source is JellyfinMusicSource ? source.syncPlay : null;
}

/// Where listening together stands.
enum ListenStatus {
  /// Not in a group.
  off,

  /// Creating or joining a group.
  connecting,

  /// In a group.
  joined,
}

/// State of listening together.
@immutable
class ListenState {
  /// Creates the state.
  const ListenState({
    this.status = ListenStatus.off,
    this.groupId,
    this.participants = const [],
    this.error,
  });

  /// Where it stands.
  final ListenStatus status;

  /// The group.
  final String? groupId;

  /// User names in the group.
  final List<String> participants;

  /// Last error, if any.
  final String? error;

  /// Whether playback is shared now.
  bool get active => status == ListenStatus.joined;
}

/// Plays in step with a Jellyfin SyncPlay group.
///
/// While joined, the user's actions go to the group ([PlaybackRelay]); the
/// group's queue and commands are applied to the player at the server time
/// they name, so everyone hears the same moment.
@Riverpod(keepAlive: true)
class ListenTogether extends _$ListenTogether implements PlaybackRelay {
  SyncPlayTransport? _transport;
  StreamSubscription<SyncPlayEvent>? _events;
  Timer? _scheduled;
  Timer? _clock;
  ProviderSubscription<PlayerState>? _indexWatch;

  /// Server clock minus local clock.
  Duration _offset = Duration.zero;

  SyncQueue? _queue;
  final _trackCache = <String, Track>{};
  bool _applying = false;
  String? _lastCommand;
  Completer<String>? _joined;

  /// How long to wait for the server to confirm a group.
  static Duration joinTimeout = const Duration(seconds: 10);

  PlayerController get _player => ref.read(playerControllerProvider.notifier);

  @override
  ListenState build() {
    ref.onDispose(() => unawaited(_teardown()));
    return const ListenState();
  }

  DateTime get _serverNow => DateTime.now().toUtc().add(_offset);

  /// Measures the server clock (best of three round trips).
  Future<void> _syncClock() async {
    final transport = _transport;
    if (transport == null) return;
    Duration? bestDelay;
    for (var i = 0; i < 3; i++) {
      final sent = DateTime.now().toUtc();
      final (received, replied) = await transport.serverTime();
      final back = DateTime.now().toUtc();
      final delay = back.difference(sent) - replied.difference(received);
      if (bestDelay == null || delay < bestDelay) {
        bestDelay = delay;
        _offset = Duration(
          microseconds:
              (received.difference(sent) + replied.difference(back))
                  .inMicroseconds ~/
              2,
        );
      }
    }
  }

  Future<void> _connect() async {
    final transport = ref.read(syncPlayTransportProvider);
    if (transport == null) throw StateError('not available');
    _transport = transport;
    await transport.connect();
    await _events?.cancel();
    _events = transport.events.listen((e) => unawaited(_onEvent(e)));
    await _syncClock();
    _clock?.cancel();
    _clock = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(_syncClock().catchError((Object _) {})),
    );
  }

  Future<String> _waitJoined() {
    final completer = _joined = Completer<String>();
    return completer.future.timeout(joinTimeout);
  }

  /// Listening groups open on the server.
  Future<List<SyncGroup>> groups() async =>
      await ref.read(syncPlayTransportProvider)?.groups() ?? const [];

  /// Creates group [name] and shares the current queue with it; returns
  /// the group id, or `null` when it failed. Open to everyone on the
  /// server who may use SyncPlay.
  Future<String?> createGroup(String name) async {
    state = const ListenState(status: ListenStatus.connecting);
    try {
      await _connect();
      final joined = _waitJoined();
      await _transport!.newGroup(name);
      final groupId = await joined;
      final player = ref.read(playerControllerProvider);
      final tracks = [for (final e in player.queue.entries) e.track];
      if (tracks.isNotEmpty) {
        await _transport!.setQueue(
          [for (final t in tracks) t.id],
          player.queue.index,
          _player.position,
        );
      }
      return groupId;
    } on Object catch (error, stack) {
      _log.error('Could not start listening together', error, stack);
      await _teardown(error: '$error');
      return null;
    }
  }

  /// Joins group [groupId].
  Future<bool> joinGroup(String groupId) async {
    state = const ListenState(status: ListenStatus.connecting);
    try {
      await _connect();
      final joined = _waitJoined();
      await _transport!.join(groupId);
      await joined;
      return true;
    } on Object catch (error, stack) {
      _log.error('Could not join', error, stack);
      await _teardown(error: '$error');
      return false;
    }
  }

  /// Creates a group and invites the chosen person (administrators, with
  /// their permission).
  Future<bool> start() async {
    final social = ref.read(socialControllerProvider);
    final outbox = social.outbox;
    if (outbox == null || !social.canSend(SocialFeature.listenTogether)) {
      return false;
    }
    final groupId = await createGroup('Melody · ${outbox.fromName}');
    if (groupId == null) return false;
    try {
      await ref
          .read(socialControllerProvider.notifier)
          .setListenInvite(groupId);
      return true;
    } on Object catch (error, stack) {
      _log.error('Could not send the invitation', error, stack);
      return false;
    }
  }

  /// Joins the group the sender invited this user to.
  Future<bool> join() async {
    final social = ref.read(socialControllerProvider);
    final groupId = social.inbox?.listenGroupId;
    if (groupId == null || !social.shows(SocialFeature.listenTogether)) {
      return false;
    }
    return await joinGroup(groupId);
  }

  /// Leaves the group (the sender also withdraws the invitation).
  Future<void> leave() async {
    try {
      await _transport?.leave();
    } on Object catch (_) {}
    if (ref.read(socialControllerProvider).outbox?.listenGroupId != null) {
      try {
        await ref.read(socialControllerProvider.notifier).setListenInvite(null);
      } on Object catch (_) {}
    }
    await _teardown();
  }

  Future<void> _teardown({String? error}) async {
    _scheduled?.cancel();
    _clock?.cancel();
    _indexWatch?.close();
    _indexWatch = null;
    await _events?.cancel();
    _events = null;
    await _transport?.close();
    _transport = null;
    _queue = null;
    _lastCommand = null;
    if (ref.mounted) {
      if (_player.relay == this) _player.relay = null;
      state = ListenState(error: error);
    }
  }

  Future<void> _onEvent(SyncPlayEvent event) async {
    try {
      switch (event) {
        case SyncGroupJoined(:final groupId, :final participants):
          state = ListenState(
            status: ListenStatus.joined,
            groupId: groupId,
            participants: participants,
          );
          _player.relay = this;
          _watchTrackEnd();
          if (_joined case final c? when !c.isCompleted) c.complete(groupId);
        case SyncUserChanged(:final name, :final joined):
          final names = [...state.participants]..remove(name);
          if (joined) names.add(name);
          state = ListenState(
            status: state.status,
            groupId: state.groupId,
            participants: names,
          );
        case SyncGroupLeft():
          if (state.status != ListenStatus.off) await _teardown();
        case SyncQueue():
          await _onQueue(event);
        case SyncCommand():
          _onCommand(event);
      }
    } on Object catch (error, stack) {
      _log.error('Listening together: could not apply $event', error, stack);
    }
  }

  /// When the local player moves on by itself at the end of a track, the
  /// group is moved on too.
  void _watchTrackEnd() {
    _indexWatch?.close();
    _indexWatch = ref.listen(playerControllerProvider, (before, after) {
      final previous = before?.queue.index;
      final next = after.queue.index;
      final queue = _queue;
      if (_applying || queue == null || previous == null) return;
      if (next == previous + 1 &&
          previous < queue.playlistItemIds.length &&
          queue.index == previous) {
        unawaited(_transport?.nextItem(queue.playlistItemIds[previous]));
      }
    });
  }

  String get _currentItemId {
    final queue = _queue;
    if (queue == null || queue.playlistItemIds.isEmpty) return '';
    return queue.playlistItemIds[queue.index.clamp(
      0,
      queue.playlistItemIds.length - 1,
    )];
  }

  Future<void> _onQueue(SyncQueue update) async {
    final old = _queue;
    if (old != null && !update.lastUpdate.isAfter(old.lastUpdate)) return;
    _queue = update;
    if (!const {
      'NewPlaylist',
      'SetCurrentItem',
      'NextItem',
      'PreviousItem',
    }.contains(update.reason)) {
      return;
    }
    if (update.itemIds.isEmpty) return;
    _scheduled?.cancel();
    _applying = true;
    try {
      final player = ref.read(playerControllerProvider);
      final localIds = [for (final e in player.queue.entries) e.track.id];
      final same =
          localIds.length == update.itemIds.length &&
          [
            for (var i = 0; i < localIds.length; i++)
              localIds[i] == update.itemIds[i],
          ].every((x) => x);
      if (same && player.queue.index == update.index) {
        await _player.remotePause(update.start);
      } else {
        final missing = [
          for (final id in update.itemIds)
            if (!_trackCache.containsKey(id)) id,
        ];
        if (missing.isNotEmpty) {
          for (final t in await _transport!.tracks(missing)) {
            _trackCache[t.id] = t;
          }
        }
        final tracks = [for (final id in update.itemIds) ?_trackCache[id]];
        if (tracks.length != update.itemIds.length) return;
        await _player.remoteLoad(tracks, update.index, update.start);
      }
    } finally {
      _applying = false;
    }
    await _transport?.report(
      ready: true,
      when: _serverNow,
      position: _player.position,
      isPlaying: false,
      playlistItemId: _currentItemId,
    );
  }

  void _onCommand(SyncCommand command) {
    final key =
        '${command.command}|${command.when.microsecondsSinceEpoch}|'
        '${command.position.inMicroseconds}|${command.playlistItemId}';
    if (key == _lastCommand) return;
    _lastCommand = key;
    _scheduled?.cancel();
    final delay = command.when.difference(_serverNow);
    void run() => unawaited(_apply(command));
    if (delay > Duration.zero) {
      // Line up the position early so the start is instant.
      if (command.command == 'Unpause' &&
          (_player.position - command.position).abs() >
              const Duration(milliseconds: 300)) {
        unawaited(_player.remotePause(command.position));
      }
      _scheduled = Timer(delay, run);
    } else {
      run();
    }
  }

  Future<void> _apply(SyncCommand command) async {
    _applying = true;
    try {
      switch (command.command) {
        case 'Unpause':
          // Late: catch up with the group.
          final late = _serverNow.difference(command.when);
          await _player.remotePlay(
            command.position + (late > Duration.zero ? late : Duration.zero),
          );
        case 'Pause':
          await _player.remotePause(command.position);
        case 'Stop':
          await _player.remotePause(_player.position);
        case 'Seek':
          await _player.remotePause(command.position);
          await _transport?.report(
            ready: true,
            when: _serverNow,
            position: command.position,
            isPlaying: false,
            playlistItemId: _currentItemId,
          );
      }
    } finally {
      _applying = false;
    }
  }

  // ---- PlaybackRelay: the user's actions go to the group ----

  @override
  Future<void> playTracks(List<Track> tracks, int start) async {
    for (final t in tracks) {
      _trackCache[t.id] = t;
    }
    await _transport?.setQueue([for (final t in tracks) t.id], start, .zero);
  }

  @override
  Future<void> play() async => await _transport?.unpause();

  @override
  Future<void> pause() async => await _transport?.pause();

  @override
  Future<void> seek(Duration position) async =>
      await _transport?.seek(position);

  @override
  Future<void> skipTo(int index) async {
    final queue = _queue;
    if (queue == null || index < 0 || index >= queue.playlistItemIds.length) {
      return;
    }
    await _transport?.setPlaylistItem(queue.playlistItemIds[index]);
  }
}
