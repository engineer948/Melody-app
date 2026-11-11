import 'dart:math';

import 'package:melody/domain/models/media.dart';
import 'package:meta/meta.dart';

/// How the queue repeats.
enum QueueRepeat {
  /// Stop after the last track.
  off,

  /// Start over after the last track.
  all,

  /// Repeat the current track.
  one,
}

/// One slot in the queue. [uid] tells apart the same track queued twice.
@immutable
class QueueEntry {
  /// Creates an entry.
  const QueueEntry(this.uid, this.track);

  /// Unique within one queue.
  final int uid;

  /// The track to play.
  final Track track;

  @override
  bool operator ==(Object other) =>
      other is QueueEntry && other.uid == uid && other.track == track;

  @override
  int get hashCode => Object.hash(uid, track);
}

/// The play order, including shuffle. Pure data; easy to test and persist.
///
/// [entries] is the order actually played. While shuffled, [originalOrder]
/// remembers the unshuffled order so it can be restored.
@immutable
class PlayQueue {
  /// Creates a queue.
  const PlayQueue({
    this.entries = const [],
    this.index = 0,
    this.shuffled = false,
    this.originalOrder = const [],
    this.repeat = QueueRepeat.off,
    this.nextUid = 0,
  });

  /// Builds a queue from [tracks], starting at [start].
  factory PlayQueue.of(
    List<Track> tracks, {
    int start = 0,
    bool shuffle = false,
    QueueRepeat repeat = QueueRepeat.off,
    Random? random,
  }) {
    final entries = [
      for (var i = 0; i < tracks.length; i++) QueueEntry(i, tracks[i]),
    ];
    final queue = PlayQueue(
      entries: entries,
      index: tracks.isEmpty ? 0 : start.clamp(0, tracks.length - 1),
      repeat: repeat,
      nextUid: tracks.length,
    );
    return shuffle ? queue.withShuffle(enabled: true, random: random) : queue;
  }

  /// Restores a queue saved with [toJson].
  factory PlayQueue.fromJson(Map<String, dynamic> json) {
    final entries = [
      for (final raw in json['entries'] as List<dynamic>)
        QueueEntry(
          (raw as Map<String, dynamic>)['uid'] as int,
          Track.fromJson(raw['track'] as Map<String, dynamic>),
        ),
    ];
    return PlayQueue(
      entries: entries,
      index: (json['index'] as int).clamp(0, max(0, entries.length - 1)),
      shuffled: json['shuffled'] as bool? ?? false,
      originalOrder: (json['originalOrder'] as List<dynamic>? ?? const [])
          .cast<int>(),
      repeat: QueueRepeat.values.asNameMap()[json['repeat']] ?? QueueRepeat.off,
      nextUid: json['nextUid'] as int? ?? entries.length,
    );
  }

  /// Play order.
  final List<QueueEntry> entries;

  /// Position of the current entry in [entries].
  final int index;

  /// Whether [entries] is shuffled.
  final bool shuffled;

  /// Unshuffled order as uids; empty when not shuffled.
  final List<int> originalOrder;

  /// Repeat behaviour.
  final QueueRepeat repeat;

  /// Uid given to the next added entry.
  final int nextUid;

  /// Whether nothing is queued.
  bool get isEmpty => entries.isEmpty;

  /// Number of entries.
  int get length => entries.length;

  /// The current entry, if any.
  QueueEntry? get current => isEmpty ? null : entries[index];

  /// Tracks in play order.
  List<Track> get tracks => [for (final e in entries) e.track];

  /// Index played after the current one when it ends naturally.
  int? get nextIndex {
    if (isEmpty) return null;
    if (repeat == QueueRepeat.one) return index;
    if (index + 1 < length) return index + 1;
    return repeat == QueueRepeat.all ? 0 : null;
  }

  /// Index for the "previous" button.
  int? get previousIndex {
    if (isEmpty) return null;
    if (index > 0) return index - 1;
    return repeat == QueueRepeat.all ? length - 1 : null;
  }

  PlayQueue _copy({
    List<QueueEntry>? entries,
    int? index,
    bool? shuffled,
    List<int>? originalOrder,
    QueueRepeat? repeat,
    int? nextUid,
  }) => PlayQueue(
    entries: entries ?? this.entries,
    index: index ?? this.index,
    shuffled: shuffled ?? this.shuffled,
    originalOrder: originalOrder ?? this.originalOrder,
    repeat: repeat ?? this.repeat,
    nextUid: nextUid ?? this.nextUid,
  );

  /// Moves to [newIndex].
  PlayQueue jumpTo(int newIndex) =>
      isEmpty ? this : _copy(index: newIndex.clamp(0, length - 1));

  /// Changes the repeat mode.
  PlayQueue withRepeat(QueueRepeat mode) => _copy(repeat: mode);

  /// Turns shuffle on (current track first, the rest random) or off
  /// (original order, staying on the current track).
  PlayQueue withShuffle({required bool enabled, Random? random}) {
    if (enabled == shuffled || isEmpty) {
      return _copy(shuffled: enabled && !isEmpty);
    }
    final current = entries[index];
    if (enabled) {
      final rest = [...entries]
        ..removeAt(index)
        ..shuffle(random ?? Random());
      return _copy(
        entries: [current, ...rest],
        index: 0,
        shuffled: true,
        originalOrder: [for (final e in entries) e.uid],
      );
    }
    final byUid = {for (final e in entries) e.uid: e};
    final restored = [
      for (final uid in originalOrder) ?byUid.remove(uid),
      // Entries added while shuffled keep their place at the end.
      ...byUid.values,
    ];
    return _copy(
      entries: restored,
      index: restored.indexOf(current),
      shuffled: false,
      originalOrder: const [],
    );
  }

  /// Inserts [tracks] right after the current entry.
  PlayQueue playNext(List<Track> tracks) =>
      insertAt(isEmpty ? 0 : index + 1, tracks);

  /// Appends [tracks].
  PlayQueue append(List<Track> tracks) => insertAt(length, tracks);

  /// Inserts [tracks] at [position] of the play order.
  PlayQueue insertAt(int position, List<Track> tracks) {
    if (tracks.isEmpty) return this;
    final at = position.clamp(0, length);
    final added = [
      for (var i = 0; i < tracks.length; i++)
        QueueEntry(nextUid + i, tracks[i]),
    ];
    final entries = [...this.entries]..insertAll(at, added);
    var original = originalOrder;
    if (shuffled) {
      // Keep them next to the current track in the unshuffled order too.
      final anchor = isEmpty ? -1 : original.indexOf(current!.uid);
      final cut = at <= index ? max(0, anchor) : anchor + 1;
      original = [...original]..insertAll(cut, added.map((e) => e.uid));
    }
    return _copy(
      entries: entries,
      index: isEmpty ? 0 : (at <= index ? index + added.length : index),
      originalOrder: original,
      nextUid: nextUid + added.length,
    );
  }

  /// Removes the entry at [position].
  PlayQueue removeAt(int position) {
    if (position < 0 || position >= length) return this;
    final removed = entries[position];
    final remaining = [...entries]..removeAt(position);
    var newIndex = index;
    if (position < index || (position == index && index >= remaining.length)) {
      newIndex = max(0, index - 1);
    }
    return _copy(
      entries: remaining,
      index: remaining.isEmpty ? 0 : newIndex,
      originalOrder: [
        for (final uid in originalOrder)
          if (uid != removed.uid) uid,
      ],
    );
  }

  /// Moves the entry at [from] to [to] (both in play order).
  PlayQueue move(int from, int to) {
    if (from < 0 || from >= length || to < 0 || to >= length || from == to) {
      return this;
    }
    final entries = [...this.entries];
    final moved = entries.removeAt(from);
    entries.insert(to, moved);
    final current = this.entries[index];
    return _copy(entries: entries, index: entries.indexOf(current));
  }

  /// Keeps only the current entry.
  PlayQueue clearUpcoming() {
    final current = this.current;
    if (current == null) return this;
    return _copy(
      entries: [current],
      index: 0,
      originalOrder: shuffled ? [current.uid] : const [],
    );
  }

  /// Applies [change] to every track, keeping uids and order.
  PlayQueue replaceTracks(Track Function(Track track) change) => _copy(
    entries: [for (final e in entries) QueueEntry(e.uid, change(e.track))],
  );

  /// Serialises the queue.
  Map<String, dynamic> toJson() => {
    'entries': [
      for (final e in entries) {'uid': e.uid, 'track': e.track.toJson()},
    ],
    'index': index,
    'shuffled': shuffled,
    'originalOrder': originalOrder,
    'repeat': repeat.name,
    'nextUid': nextUid,
  };
}
