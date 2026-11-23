import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/features/player/cassette.dart';
import 'package:melody/player/player_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'player_look.g.dart';

/// What the full player shows in the middle.
enum PlayerFace {
  /// The cover.
  cover,

  /// A cassette whose tape winds from one reel to the other.
  cassette,
}

/// How the full player looks.
@immutable
class PlayerLook {
  /// Creates the look.
  const PlayerLook({this.face = PlayerFace.cover, this.movingLyrics = false});

  /// Cover or cassette.
  final PlayerFace face;

  /// Whether the words of the current lyrics line light up one by one.
  final bool movingLyrics;
}

/// The player's look, kept in preferences.
@Riverpod(keepAlive: true)
class PlayerLookController extends _$PlayerLookController {
  static const _faceKey = 'player.face';
  static const _movingKey = 'player.movingLyrics';

  @override
  PlayerLook build() {
    final prefs = ref.watch(preferencesProvider);
    return PlayerLook(
      face:
          PlayerFace.values.asNameMap()[prefs.getString(_faceKey)] ??
          PlayerFace.cover,
      movingLyrics: prefs.getBool(_movingKey) ?? false,
    );
  }

  /// Shows [face] in the player.
  Future<void> setFace(PlayerFace face) async {
    state = PlayerLook(face: face, movingLyrics: state.movingLyrics);
    await ref.read(preferencesProvider).setString(_faceKey, face.name);
  }

  /// Turns moving lyrics on or off.
  Future<void> setMovingLyrics({required bool value}) async {
    state = PlayerLook(face: state.face, movingLyrics: value);
    await ref.read(preferencesProvider).setBool(_movingKey, value);
  }

  /// Switches between cover and cassette.
  Future<void> toggleFace() => setFace(
    state.face == PlayerFace.cover ? PlayerFace.cassette : PlayerFace.cover,
  );
}

/// Label colour of the cassette of [track]: the same for a whole album.
Color cassetteColor(Track track) {
  final key = track.albumId ?? track.id;
  var hash = 0;
  for (final unit in key.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return Color(cassetteColors[hash % cassetteColors.length]);
}

/// The song playing as a cassette: the reels turn while it plays and the
/// tape winds from the left reel to the right one as the song goes on.
class PlayerCassette extends ConsumerStatefulWidget {
  /// Creates the cassette for [track].
  const PlayerCassette({
    required this.track,
    required this.playing,
    required this.width,
    super.key,
  });

  /// The song.
  final Track track;

  /// Whether the reels turn.
  final bool playing;

  /// Width of the cassette.
  final double width;

  @override
  ConsumerState<PlayerCassette> createState() => _PlayerCassetteState();
}

class _PlayerCassetteState extends ConsumerState<PlayerCassette>
    with SingleTickerProviderStateMixin {
  late final _turns = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void initState() {
    super.initState();
    if (widget.playing) _turns.repeat();
  }

  @override
  void didUpdateWidget(PlayerCassette old) {
    super.didUpdateWidget(old);
    if (widget.playing && !_turns.isAnimating) {
      _turns.repeat();
    } else if (!widget.playing && _turns.isAnimating) {
      _turns.stop();
    }
  }

  @override
  void dispose() {
    _turns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(playerPositionProvider).value ?? Duration.zero;
    final duration =
        ref.watch(playerControllerProvider.select((s) => s.duration)) ??
        widget.track.duration;
    final progress = duration == null || duration.inMilliseconds == 0
        ? 0.0
        : min(1, position.inMilliseconds / duration.inMilliseconds).toDouble();
    return Cassette(
      title: widget.track.title,
      from: widget.track.artistLine,
      color: cassetteColor(widget.track),
      turns: _turns,
      progress: progress,
      width: widget.width,
    );
  }
}
