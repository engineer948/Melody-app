import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/recommendation/recommender.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/domain/stats/play_event.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/player/history_recorder.dart';
import 'package:melody/player/listening_settings.dart';
import 'package:melody/player/play_queue.dart';
import 'package:melody/player/player_controller.dart';
import 'package:melody/player/player_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auto_queue.g.dart';

/// Auto DJ: keeps the music going by adding tracks when the queue is about
/// to run out.
class AutoQueueService {
  /// Creates the service.
  AutoQueueService({
    required this.source,
    required this.settings,
    required this.history,
    required this.enqueue,
    Random? random,
    DateTime Function()? clock,
  }) : _random = random ?? Random(),
       _clock = clock ?? DateTime.now;

  /// Number of tracks added at a time.
  static const batch = 10;

  /// Tracks played within this time are not added again.
  static const rest = Duration(hours: 3);

  /// The active source.
  final MusicSource? Function() source;

  /// Current preferences.
  final ListeningSettings Function() settings;

  /// Plays since the given time (may be empty when history is off).
  final Future<List<PlayEvent>> Function(DateTime since) history;

  /// Appends tracks to the queue.
  final Future<void> Function(List<Track> tracks) enqueue;

  final Random _random;
  final DateTime Function() _clock;
  bool _busy = false;
  int? _exhaustedFor;
  Map<String, String>? _genreIds;

  /// Feeds the next player state; adds tracks when needed.
  Future<void> onState(PlayerState state) async {
    final config = settings();
    final queue = state.queue;
    final current = queue.current;
    if (!config.autoDj ||
        _busy ||
        current == null ||
        !state.playing ||
        queue.repeat != QueueRepeat.off ||
        queue.length - queue.index - 1 > config.autoDjThreshold ||
        _exhaustedFor == current.uid) {
      return;
    }
    final target = source();
    if (target == null) return;
    _busy = true;
    try {
      final tracks = await pick(target, queue, config.autoDjMode);
      if (tracks.isEmpty) {
        _exhaustedFor = current.uid; // Do not ask again for this track.
      } else {
        await enqueue(tracks);
      }
    } finally {
      _busy = false;
    }
  }

  /// Chooses up to [batch] tracks to follow [queue] in [mode].
  Future<List<Track>> pick(
    MusicSource target,
    PlayQueue queue,
    AutoDjMode mode,
  ) async {
    final seed = queue.entries.last.track;
    final now = _clock();
    List<PlayEvent> recent;
    try {
      recent = await history(now.subtract(rest));
    } on Object {
      recent = const [];
    }
    final exclude = {
      for (final e in queue.entries) e.track.id,
      for (final e in recent) e.track.id,
    };
    var pool = await _candidates(target, seed, mode);
    if (pool.where((t) => !exclude.contains(t.id)).isEmpty &&
        mode != AutoDjMode.random) {
      pool = await _candidates(target, seed, AutoDjMode.random);
    }
    if (mode == AutoDjMode.smart) {
      List<PlayEvent> all;
      try {
        all = await history(DateTime.fromMillisecondsSinceEpoch(0));
      } on Object {
        all = const [];
      }
      return Recommender(
        all,
        now: now,
      ).mix(pool, count: batch, exclude: exclude, random: _random);
    }
    final seen = <String>{};
    final fresh = [
      for (final t in pool)
        if (!exclude.contains(t.id) && seen.add(t.id)) t,
    ];
    // An instant mix is already ordered by similarity; the rest is shuffled.
    if (mode != AutoDjMode.similar) fresh.shuffle(_random);
    return fresh.take(batch).toList();
  }

  Future<List<Track>> _candidates(
    MusicSource target,
    Track seed,
    AutoDjMode mode,
  ) async {
    List<Track> of(Result<List<Track>> result) => result.valueOrNull ?? [];
    switch (mode) {
      case AutoDjMode.similar:
        if (!target.capabilities.instantMix) return const [];
        return of(await target.similarTracks(seed.id));
      case AutoDjMode.artist:
        final artistId = seed.artists.firstOrNull?.id;
        if (artistId == null) return const [];
        return of(
          await target.tracks(TrackQuery(artistId: artistId, limit: 200)),
        );
      case AutoDjMode.genre:
        final genreId = await _genreId(target, seed);
        if (genreId == null) return const [];
        return of(await target.randomTracks(genreId: genreId));
      case AutoDjMode.random:
        return of(await target.randomTracks());
      case AutoDjMode.smart:
        final (random, similar) = await (
          target.randomTracks(count: 100),
          target.capabilities.instantMix
              ? target.similarTracks(seed.id)
              : Future.value(const Ok(<Track>[])),
        ).wait;
        return [...of(similar), ...of(random)];
    }
  }

  Future<String?> _genreId(MusicSource target, Track seed) async {
    if (seed.genres.isEmpty || !target.capabilities.genres) return null;
    var ids = _genreIds;
    if (ids == null) {
      final genres = (await target.genres()).valueOrNull;
      if (genres == null) return null;
      ids = _genreIds = {for (final g in genres) g.name: g.id};
    }
    for (final name in seed.genres) {
      final id = ids[name];
      if (id != null) return id;
    }
    return null;
  }
}

/// Auto DJ bound to the player.
@Riverpod(keepAlive: true)
AutoQueueService autoQueue(Ref ref) {
  // A new account has other genres and tracks.
  ref.watch(sessionControllerProvider.select((s) => s.activeId));
  final service = AutoQueueService(
    source: () => ref.read(activeSourceProvider),
    settings: () => ref.read(listeningSettingsControllerProvider),
    history: (since) async {
      final accountId = ref.read(sessionControllerProvider).activeId;
      if (accountId == null) return const [];
      return await ref
          .read(historyStoreProvider)
          .events(accountId, from: since);
    },
    enqueue: (tracks) =>
        ref.read(playerControllerProvider.notifier).addToQueue(tracks),
  );
  ref.listen(
    playerControllerProvider,
    (_, state) => unawaited(service.onState(state)),
  );
  return service;
}
