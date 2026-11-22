import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/core/widgets/artwork_image.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/l10n/l10n.dart';
import 'package:melody/player/player_controller.dart';

/// Songs per game.
const yearGameRounds = 10;

/// Four years to choose from for a song of [year]: the right one and
/// three others near it, none in the future, in order.
List<int> yearChoices(int year, Random random, {int? now}) {
  final latest = now ?? DateTime.now().year;
  final years = {year};
  while (years.length < 4) {
    final delta = (random.nextInt(8) + 1) * (random.nextBool() ? 1 : -1);
    final candidate = year + delta;
    if (candidate <= latest && candidate > 1900) years.add(candidate);
  }
  return years.toList()..sort();
}

/// Opens the game.
Future<void> showYearGame(BuildContext context) => Navigator.of(
  context,
  rootNavigator: true,
).push(MaterialPageRoute<void>(builder: (_) => const YearGameScreen()));

/// "Which year?": a song of the library plays, the cover is hidden, and
/// the player picks the year it came out.
class YearGameScreen extends ConsumerStatefulWidget {
  /// Creates the game.
  const YearGameScreen({super.key, this.random});

  /// For tests.
  final Random? random;

  @override
  ConsumerState<YearGameScreen> createState() => _YearGameScreenState();
}

class _YearGameScreenState extends ConsumerState<YearGameScreen> {
  late final Random _random = widget.random ?? Random();
  List<Track>? _songs;
  var _round = 0;
  var _score = 0;
  int? _picked;
  List<int> _choices = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final source = ref.read(activeSourceProvider);
    final result = await source?.randomTracks(count: 100);
    final songs = switch (result) {
      Ok(:final value) => [
        for (final t in value)
          if (t.year != null) t,
      ],
      _ => <Track>[],
    }..shuffle(_random);
    if (!mounted) return;
    setState(() {
      _songs = songs.take(yearGameRounds).toList();
      _round = 0;
      _score = 0;
    });
    await _startRound();
  }

  Future<void> _startRound() async {
    final songs = _songs;
    if (songs == null || _round >= songs.length) return;
    final song = songs[_round];
    setState(() {
      _picked = null;
      _choices = yearChoices(song.year!, _random);
    });
    final player = ref.read(playerControllerProvider.notifier);
    await player.playTracks([song]);
    // Skip the intro, it gives too little away.
    final length = song.duration ?? Duration.zero;
    if (length > const Duration(seconds: 60)) {
      await player.seek(const Duration(seconds: 30));
    }
  }

  void _pick(int year) {
    if (_picked != null) return;
    final right = _songs![_round].year!;
    setState(() {
      _picked = year;
      if (year == right) _score++;
    });
  }

  Future<void> _next() async {
    setState(() => _round++);
    if (_round < _songs!.length) {
      await _startRound();
    } else {
      await ref.read(playerControllerProvider.notifier).pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final songs = _songs;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.yearGame)),
      body: switch (songs) {
        null => const Center(child: CircularProgressIndicator()),
        [] || [_] || [_, _] => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(l10n.yearGameNoSongs, textAlign: TextAlign.center),
          ),
        ),
        _ when _round >= songs.length => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded, size: 64),
              const SizedBox(height: 12),
              Text(
                l10n.yearGameScore(_score, songs.length),
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  setState(() => _songs = null);
                  unawaited(_load());
                },
                icon: const Icon(Icons.replay_rounded),
                label: Text(l10n.yearGameAgain),
              ),
            ],
          ),
        ),
        _ => _roundView(context, songs[_round], songs.length),
      },
    );
  }

  Widget _roundView(BuildContext context, Track song, int total) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final picked = _picked;
    final right = song.year!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          l10n.yearGameRound(_round + 1, total),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 16),
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: picked == null
                ? Container(
                    key: const ValueKey('hidden'),
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.question_mark_rounded,
                      size: 96,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : ArtworkImage(
                    key: ValueKey(song.id),
                    artwork: song.artwork,
                    size: 200,
                    radius: 16,
                    icon: Icons.music_note_outlined,
                  ),
          ),
        ),
        const SizedBox(height: 16),
        if (picked != null) ...[
          Text(
            song.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          Text('${song.artistLine} · $right', textAlign: TextAlign.center),
        ] else
          Text(
            l10n.yearGameAsk,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            for (final year in _choices)
              SizedBox(
                width: 130,
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: picked == null
                        ? null
                        : year == right
                        ? Colors.green
                        : year == picked
                        ? theme.colorScheme.error
                        : null,
                    foregroundColor:
                        picked != null && (year == right || year == picked)
                        ? Colors.white
                        : null,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _pick(year),
                  child: Text('$year', style: const TextStyle(fontSize: 20)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        if (picked != null)
          FilledButton.icon(
            onPressed: () => unawaited(_next()),
            icon: const Icon(Icons.skip_next_rounded),
            label: Text(l10n.yearGameNext),
          ),
        const SizedBox(height: 8),
        Text(
          l10n.yearGamePoints(_score),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
