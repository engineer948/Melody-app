import 'dart:async';

import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/social/sync_play.dart';

import 'fakes.dart';

/// A tiny SyncPlay server: groups, a shared queue, "everyone ready ->
/// play" and pause / seek / next commands, like Jellyfin's. Its clock runs
/// [offset] ahead of the test's, to check clock syncing.
class FakeSyncServer {
  /// Creates the server.
  FakeSyncServer({this.offset = const Duration(hours: 2)});

  /// Server clock minus local clock.
  final Duration offset;

  /// How far ahead commands are scheduled.
  Duration lead = const Duration(milliseconds: 80);

  final _members = <FakeSyncTransport>[];
  String? groupId;
  List<String> _items = [];
  int _index = 0;
  Duration _start = Duration.zero;
  bool _playing = false;
  DateTime? _playingSince;
  final _ready = <FakeSyncTransport>{};
  // Whether the group plays once everyone is ready (like Jellyfin's
  // WaitingGroupState.ResumePlaying).
  bool _resume = false;
  int _updates = 0;

  /// Requests received, for assertions.
  final log = <String>[];

  DateTime get now => DateTime.now().toUtc().add(offset);

  Duration get _position => _playing && _playingSince != null
      ? _start + now.difference(_playingSince!)
      : _start;

  List<String> get _pids => [for (var i = 0; i < _items.length; i++) 'p$i'];

  SyncQueue _queue(String reason) => SyncQueue(
    reason: reason,
    lastUpdate: DateTime.utc(2026).add(Duration(seconds: ++_updates)),
    itemIds: _items,
    playlistItemIds: _pids,
    index: _index,
    start: _position,
    isPlaying: _playing,
  );

  void _all(SyncPlayEvent e) {
    for (final m in _members) {
      m._events.add(e);
    }
  }

  SyncCommand _command(String name, Duration position) => SyncCommand(
    command: name,
    when: now.add(lead),
    position: position,
    playlistItemId: _pids.isEmpty ? '' : _pids[_index],
  );

  void _newQueue(String reason) {
    _start = _position;
    _resume = true;
    _playing = false;
    _ready.clear();
    _all(_queue(reason));
  }

  void handle(FakeSyncTransport from, String action, [Object? arg]) {
    log.add('${from.name}:$action');
    switch (action) {
      case 'new':
        groupId = 'g1';
        _members.add(from);
        from._events.add(SyncGroupJoined('g1', [from.name]));
      case 'join':
        for (final m in _members) {
          m._events.add(SyncUserChanged(from.name, joined: true));
        }
        _members.add(from);
        from._events.add(
          SyncGroupJoined('g1', [for (final m in _members) m.name]),
        );
        if (_items.isNotEmpty) from._events.add(_queue('NewPlaylist'));
      case 'leave':
        _members.remove(from);
        from._events.add(const SyncGroupLeft());
      case 'setQueue':
        final (ids, index, start) = arg! as (List<String>, int, Duration);
        _items = ids;
        _index = index;
        _start = start;
        _playing = false;
        _resume = true;
        _ready.clear();
        _all(_queue('NewPlaylist'));
      case 'ready':
        _ready.add(from);
        if (_playing) {
          // Late joiner: play from where the group is.
          from._events.add(_command('Unpause', _position));
        } else if (_resume && _ready.containsAll(_members)) {
          final start = _start;
          _playing = true;
          _playingSince = now.add(lead);
          _all(_command('Unpause', start));
        }
      case 'unpause':
        if (!_playing) {
          _playing = true;
          _playingSince = now.add(lead);
          _all(_command('Unpause', _start));
        }
      case 'pause':
        _resume = false;
        _start = _position;
        _playing = false;
        _all(_command('Pause', _start));
      case 'seek':
        _resume = _playing;
        _start = arg! as Duration;
        _playing = false;
        _ready.clear();
        _all(_command('Seek', _start));
      case 'setItem':
        _index = _pids.indexOf(arg! as String);
        _start = Duration.zero;
        _newQueue('SetCurrentItem');
      case 'next':
        if (arg == _pids[_index] && _index + 1 < _items.length) {
          _index++;
          _start = Duration.zero;
          _playingSince = null;
          _newQueue('NextItem');
        }
    }
  }
}

/// One member's connection to a [FakeSyncServer].
class FakeSyncTransport implements SyncPlayTransport {
  /// Creates the transport for user [name].
  FakeSyncTransport(this.server, this.name);

  /// The server.
  final FakeSyncServer server;

  /// User name.
  final String name;

  final _events = StreamController<SyncPlayEvent>.broadcast();

  @override
  Stream<SyncPlayEvent> get events => _events.stream;

  @override
  Future<void> connect() async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> newGroup(String name) async => server.handle(this, 'new');

  @override
  Future<void> join(String groupId) async => server.handle(this, 'join');

  @override
  Future<void> leave() async => server.handle(this, 'leave');

  @override
  Future<void> setQueue(
    List<String> itemIds,
    int index,
    Duration start,
  ) async => server.handle(this, 'setQueue', (itemIds, index, start));

  @override
  Future<void> unpause() async => server.handle(this, 'unpause');

  @override
  Future<void> pause() async => server.handle(this, 'pause');

  @override
  Future<void> seek(Duration position) async =>
      server.handle(this, 'seek', position);

  @override
  Future<void> setPlaylistItem(String playlistItemId) async =>
      server.handle(this, 'setItem', playlistItemId);

  @override
  Future<void> nextItem(String playlistItemId) async =>
      server.handle(this, 'next', playlistItemId);

  @override
  Future<void> report({
    required bool ready,
    required DateTime when,
    required Duration position,
    required bool isPlaying,
    required String playlistItemId,
  }) async {
    if (ready) server.handle(this, 'ready');
  }

  @override
  Future<(DateTime, DateTime)> serverTime() async => (server.now, server.now);

  @override
  Future<List<Track>> tracks(List<String> ids) async => [
    for (final id in ids) makeTrack(id),
  ];
}
