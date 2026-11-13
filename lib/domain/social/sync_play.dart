import 'package:melody/domain/models/media.dart';

/// One message from the server about the listening group.
sealed class SyncPlayEvent {
  const SyncPlayEvent();
}

/// Joined a group.
class SyncGroupJoined extends SyncPlayEvent {
  /// Creates the event.
  const SyncGroupJoined(this.groupId, this.participants);

  /// Group id.
  final String groupId;

  /// User names in the group.
  final List<String> participants;
}

/// Someone joined (true) or left (false).
class SyncUserChanged extends SyncPlayEvent {
  /// Creates the event.
  const SyncUserChanged(this.name, {required this.joined});

  /// User name.
  final String name;

  /// Whether they joined.
  final bool joined;
}

/// This device is no longer in a group.
class SyncGroupLeft extends SyncPlayEvent {
  /// Creates the event.
  const SyncGroupLeft();
}

/// The group's queue changed.
class SyncQueue extends SyncPlayEvent {
  /// Creates the event.
  const SyncQueue({
    required this.reason,
    required this.lastUpdate,
    required this.itemIds,
    required this.playlistItemIds,
    required this.index,
    required this.start,
    required this.isPlaying,
  });

  /// Why (NewPlaylist, SetCurrentItem, NextItem, PreviousItem, Queue, ...).
  final String reason;

  /// When the server changed it.
  final DateTime lastUpdate;

  /// Track ids in order.
  final List<String> itemIds;

  /// The server's id of each entry.
  final List<String> playlistItemIds;

  /// Playing entry.
  final int index;

  /// Position to start from.
  final Duration start;

  /// Whether the group is playing.
  final bool isPlaying;
}

/// A playback command to carry out at server time [when].
class SyncCommand extends SyncPlayEvent {
  /// Creates the command.
  const SyncCommand({
    required this.command,
    required this.when,
    required this.position,
    required this.playlistItemId,
  });

  /// Unpause, Pause, Seek or Stop.
  final String command;

  /// Server time at which to act.
  final DateTime when;

  /// Position at [when].
  final Duration position;

  /// The entry it applies to.
  final String playlistItemId;
}

/// A listening group on the server.
class SyncGroup {
  /// Creates the entry.
  const SyncGroup({
    required this.id,
    required this.name,
    this.participants = const [],
  });

  /// Group id.
  final String id;

  /// Group name.
  final String name;

  /// User names in it.
  final List<String> participants;
}

/// Server side of listening together.
abstract interface class SyncPlayTransport {
  /// Messages from the server; open while [connect]ed.
  Stream<SyncPlayEvent> get events;

  /// Opens the live connection.
  Future<void> connect();

  /// Closes it.
  Future<void> close();

  /// Groups open on the server.
  Future<List<SyncGroup>> groups();

  /// Creates a group (the server then sends [SyncGroupJoined]).
  Future<void> newGroup(String name);

  /// Joins [groupId].
  Future<void> join(String groupId);

  /// Leaves the group.
  Future<void> leave();

  /// Replaces the group's queue.
  Future<void> setQueue(List<String> itemIds, int index, Duration start);

  /// Asks the group to play.
  Future<void> unpause();

  /// Asks the group to pause.
  Future<void> pause();

  /// Asks the group to seek.
  Future<void> seek(Duration position);

  /// Asks the group to play entry [playlistItemId].
  Future<void> setPlaylistItem(String playlistItemId);

  /// Moves the group on from [playlistItemId] (the current entry).
  Future<void> nextItem(String playlistItemId);

  /// Tells the server this device is ready ([ready]) or buffering.
  Future<void> report({
    required bool ready,
    required DateTime when,
    required Duration position,
    required bool isPlaying,
    required String playlistItemId,
  });

  /// The server's clock: (request received, response sent).
  Future<(DateTime, DateTime)> serverTime();

  /// Tracks for [ids].
  Future<List<Track>> tracks(List<String> ids);
}
