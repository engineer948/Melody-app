import 'dart:math';

import 'package:melody/domain/lyrics/vocal_start.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/share/mp3_clip.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/lyrics/lyrics_providers.dart';
import 'package:melody/features/lyrics/voice_analyzer.dart';
import 'package:melody/features/share/audio_clip.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lyrics_auto_sync.g.dart';

/// Bytes per second of the MP3 the server sends for measuring (192 kb/s).
const _bytesPerSecond = 24000;

/// The first line of [lyrics] that has words, or `null`.
Duration? firstSungLine(Lyrics lyrics) {
  for (final line in lyrics.lines) {
    final text = line.text.trim();
    if (line.start != null && text.isNotEmpty && text != '♪') {
      return line.start;
    }
  }
  return null;
}

/// Measures once where the singing of [track] starts and keeps the lyrics
/// correction that puts the first sung line there, which it returns. When
/// the singing cannot be found (or the phone cannot decode audio), the
/// silence at the start is used instead. Songs measured before are not
/// measured again. Fails (and is tried again next time) when the start
/// cannot be read: offline, or no MP3 from the server.
@riverpod
Future<Duration> lyricsAutoSync(Ref ref, Track track) async {
  final settings = ref.read(lyricsSettingsControllerProvider);
  if (settings.autoOffsetsMs[track.id] case final ms?) {
    return Duration(milliseconds: ms);
  }
  final lyricsFuture = ref.watch(trackLyricsProvider(track).future);
  final source = ref.read(activeSourceProvider);
  if (source == null) throw StateError('signed out');
  final loader = ref.read(songAudioLoaderProvider);
  final analyzer = ref.read(voiceAnalyzerProvider);
  final controller = ref.read(lyricsSettingsControllerProvider.notifier);
  final lyrics = await lyricsFuture;
  final firstLine = lyrics == null ? null : firstSungLine(lyrics);
  // Enough of the song to hear the first line and a bit after it.
  final seconds = min(120, (firstLine?.inSeconds ?? 20) + 12);
  final bytes = await loader.loadStart(
    source,
    track,
    maxBytes: max(800000, seconds * _bytesPerSecond),
  );
  Duration? offset;
  if (analyzer.supported && firstLine != null) {
    final bands = await analyzer.bands(bytes, seconds: seconds);
    if (bands != null) {
      offset = vocalLyricsOffset(
        vocalStart(bands.mid, bands.side, hop: bands.hop),
        firstLine,
      );
    }
  }
  offset ??= autoLyricsOffset(Mp3Song.parse(bytes).soundStart());
  await controller.setAuto(track.id, offset);
  return offset;
}
