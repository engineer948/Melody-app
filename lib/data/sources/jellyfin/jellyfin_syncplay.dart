import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:melody/data/sources/jellyfin/jellyfin_api.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/social/sync_play.dart';

/// Jellyfin SyncPlay: requests over HTTP, group messages over the server's
/// WebSocket (`/socket`), authenticated with the same header as the API.
class JellyfinSyncPlay implements SyncPlayTransport {
  /// Creates the transport.
  JellyfinSyncPlay(this._api, this._tracks);

  final JellyfinApi _api;
  final Future<List<Track>> Function(List<String> ids) _tracks;
  final _events = StreamController<SyncPlayEvent>.broadcast();
  WebSocket? _socket;
  Timer? _keepAlive;

  static const _ticksPerMicrosecond = 10;

  static Duration _ticks(Object? value) => Duration(
    microseconds: value is num ? value.toInt() ~/ _ticksPerMicrosecond : 0,
  );

  static int _toTicks(Duration d) => d.inMicroseconds * _ticksPerMicrosecond;

  static DateTime _date(Object? value) =>
      (value is String ? DateTime.tryParse(value) : null)?.toUtc() ??
      DateTime.now().toUtc();

  @override
  Stream<SyncPlayEvent> get events => _events.stream;

  @override
  Future<void> connect() async {
    if (_socket != null) return;
    final http = _api.resolve('socket');
    final uri = http.replace(scheme: http.scheme == 'https' ? 'wss' : 'ws');
    final socket = await WebSocket.connect(
      uri.toString(),
      headers: {_api.authHeader: _api.authorizationHeader},
    );
    _socket = socket;
    socket.listen(
      (data) {
        if (data is String) _onMessage(data);
      },
      onDone: () {
        _keepAlive?.cancel();
        _socket = null;
        _events.add(const SyncGroupLeft());
      },
      onError: (Object _) {},
      cancelOnError: false,
    );
  }

  void _send(Map<String, Object?> message) => _socket?.add(jsonEncode(message));

  void _onMessage(String text) {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      return;
    }
    if (json is! Map) return;
    final data = json['Data'];
    switch (json['MessageType']) {
      case 'ForceKeepAlive':
        final seconds = data is num && data > 0 ? data.toInt() : 60;
        _keepAlive?.cancel();
        _keepAlive = Timer.periodic(
          Duration(milliseconds: seconds * 500),
          (_) => _send({'MessageType': 'KeepAlive'}),
        );
        _send({'MessageType': 'KeepAlive'});
      case 'SyncPlayCommand' when data is Map:
        _events.add(
          SyncCommand(
            command: '${data['Command']}',
            when: _date(data['When']),
            position: _ticks(data['PositionTicks']),
            playlistItemId: '${data['PlaylistItemId'] ?? ''}',
          ),
        );
      case 'SyncPlayGroupUpdate' when data is Map:
        final event = _groupUpdate(data);
        if (event != null) _events.add(event);
    }
  }

  SyncPlayEvent? _groupUpdate(Map<dynamic, dynamic> update) {
    final data = update['Data'];
    switch (update['Type']) {
      case 'GroupJoined' when data is Map:
        final participants = data['Participants'];
        return SyncGroupJoined('${data['GroupId'] ?? update['GroupId']}', [
          if (participants is List)
            for (final p in participants) '$p',
        ]);
      case 'UserJoined':
        return SyncUserChanged('$data', joined: true);
      case 'UserLeft':
        return SyncUserChanged('$data', joined: false);
      case 'GroupLeft' || 'NotInGroup' || 'GroupDoesNotExist':
        return const SyncGroupLeft();
      case 'PlayQueue' when data is Map:
        final playlist = data['Playlist'];
        final items = [
          if (playlist is List)
            for (final e in playlist)
              if (e is Map) e,
        ];
        return SyncQueue(
          reason: '${data['Reason']}',
          lastUpdate: _date(data['LastUpdate']),
          itemIds: [for (final e in items) '${e['ItemId']}'],
          playlistItemIds: [for (final e in items) '${e['PlaylistItemId']}'],
          index: data['PlayingItemIndex'] is num
              ? (data['PlayingItemIndex'] as num).toInt()
              : 0,
          start: _ticks(data['StartPositionTicks']),
          isPlaying: data['IsPlaying'] == true,
        );
    }
    return null;
  }

  @override
  Future<void> close() async {
    _keepAlive?.cancel();
    final socket = _socket;
    _socket = null;
    await socket?.close();
  }

  Future<void> _post(String action, [Map<String, Object?> body = const {}]) =>
      _api.post('SyncPlay/$action', body: body);

  @override
  Future<void> newGroup(String name) => _post('New', {'GroupName': name});

  @override
  Future<void> join(String groupId) => _post('Join', {'GroupId': groupId});

  @override
  Future<void> leave() => _post('Leave');

  @override
  Future<void> setQueue(List<String> itemIds, int index, Duration start) =>
      _post('SetNewQueue', {
        'PlayingQueue': itemIds,
        'PlayingItemPosition': index,
        'StartPositionTicks': _toTicks(start),
      });

  @override
  Future<void> unpause() => _post('Unpause');

  @override
  Future<void> pause() => _post('Pause');

  @override
  Future<void> seek(Duration position) =>
      _post('Seek', {'PositionTicks': _toTicks(position)});

  @override
  Future<void> setPlaylistItem(String playlistItemId) =>
      _post('SetPlaylistItem', {'PlaylistItemId': playlistItemId});

  @override
  Future<void> nextItem(String playlistItemId) =>
      _post('NextItem', {'PlaylistItemId': playlistItemId});

  @override
  Future<void> report({
    required bool ready,
    required DateTime when,
    required Duration position,
    required bool isPlaying,
    required String playlistItemId,
  }) => _post(ready ? 'Ready' : 'Buffering', {
    'When': when.toUtc().toIso8601String(),
    'PositionTicks': _toTicks(position),
    'IsPlaying': isPlaying,
    'PlaylistItemId': playlistItemId,
  });

  @override
  Future<(DateTime, DateTime)> serverTime() async {
    final json = await _api.getObject('GetUtcTime');
    return (
      _date(json['RequestReceptionTime']),
      _date(json['ResponseTransmissionTime']),
    );
  }

  @override
  Future<List<Track>> tracks(List<String> ids) => _tracks(ids);
}
