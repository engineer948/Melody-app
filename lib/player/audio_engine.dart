import 'dart:async';

import 'package:melody/player/play_queue.dart';
import 'package:meta/meta.dart';

/// Something the engine can play.
@immutable
class EngineSource {
  /// Creates a source.
  const EngineSource({
    required this.uri,
    this.headers = const {},
    this.tag,
    this.cacheKey,
    this.title,
    this.artist,
    this.album,
    this.artUri,
  });

  /// Stream address.
  final Uri uri;

  /// HTTP headers for the request.
  final Map<String, String> headers;

  /// Opaque value given back unchanged (the queue entry uid).
  final Object? tag;

  /// When set, the stream is saved to (and replayed from) the disk cache.
  final String? cacheKey;

  /// Song title, for outputs that show what they play (DLNA).
  final String? title;

  /// Artist name, see [title].
  final String? artist;

  /// Album title, see [title].
  final String? album;

  /// Cover address, see [title].
  final Uri? artUri;
}

/// Coarse state of the engine.
enum EngineStatus {
  /// Nothing loaded.
  idle,

  /// Loading or buffering.
  buffering,

  /// Ready to play or playing.
  ready,

  /// The last item finished.
  completed,
}

/// Snapshot published by an [AudioEngine].
@immutable
class EngineState {
  /// Creates a snapshot.
  const EngineState({
    this.status = EngineStatus.idle,
    this.playing = false,
    this.index,
    this.duration,
    this.error,
  });

  /// Load state.
  final EngineStatus status;

  /// Whether playback is running (may still be buffering).
  final bool playing;

  /// Item currently loaded.
  final int? index;

  /// Duration of the current item, when known.
  final Duration? duration;

  /// Message of the last playback error.
  final String? error;

  @override
  bool operator ==(Object other) =>
      other is EngineState &&
      other.status == status &&
      other.playing == playing &&
      other.index == index &&
      other.duration == duration &&
      other.error == error;

  @override
  int get hashCode => Object.hash(status, playing, index, duration, error);
}

/// Equaliser band exposed by the platform.
@immutable
class EqualizerBand {
  /// Creates a band.
  const EqualizerBand({
    required this.centerHz,
    required this.minDb,
    required this.maxDb,
  });

  /// Centre frequency.
  final double centerHz;

  /// Lowest gain.
  final double minDb;

  /// Highest gain.
  final double maxDb;
}

/// Plays a list of sources gaplessly. Implemented with just_audio in the
/// app and faked in tests.
abstract interface class AudioEngine {
  /// State changes.
  Stream<EngineState> get states;

  /// The latest state.
  EngineState get state;

  /// Current position inside the current item.
  Duration get position;

  /// Replaces everything that is loaded.
  Future<void> load(
    List<EngineSource> sources, {
    int index = 0,
    Duration position = Duration.zero,
  });

  /// Inserts sources at [index].
  Future<void> insert(int index, List<EngineSource> sources);

  /// Removes the source at [index].
  Future<void> removeAt(int index);

  /// Moves a source.
  Future<void> move(int from, int to);

  /// Starts or resumes playback.
  Future<void> play();

  /// Pauses.
  Future<void> pause();

  /// Stops and releases the audio focus.
  Future<void> stop();

  /// Seeks inside the item at [index] (the current one by default).
  Future<void> seek(Duration position, {int? index});

  /// Sets the repeat behaviour.
  Future<void> setRepeat(QueueRepeat mode);

  /// Sets the playback speed.
  Future<void> setSpeed(double speed);

  /// Sets the volume, 0 to 1.
  Future<void> setVolume(double volume);

  /// Equaliser bands; empty when the platform has no equaliser.
  Future<List<EqualizerBand>> equalizerBands();

  /// Enables or disables the equaliser and sets band gains (dB).
  Future<void> setEqualizer({
    required bool enabled,
    required List<double> gainsDb,
  });

  /// Sets the loudness boost in dB (0 disables it).
  Future<void> setLoudnessBoost(double db);

  /// Overlap between songs; zero turns crossfade off.
  Future<void> setCrossfade(Duration overlap);

  /// Releases resources.
  Future<void> dispose();
}
