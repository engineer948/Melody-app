import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/share/mp3_clip.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/lyrics/lyrics_providers.dart';
import 'package:melody/features/share/audio_clip.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lyrics_auto_sync.g.dart';

/// Measures once where the music of [track] really starts and keeps the
/// matching lyrics correction, which it returns. Songs measured before
/// are not measured again. Fails (and is tried again next time) when the
/// start cannot be read: offline, or no MP3 from the server.
@riverpod
Future<Duration> lyricsAutoSync(Ref ref, Track track) async {
  final settings = ref.read(lyricsSettingsControllerProvider);
  if (settings.autoOffsetsMs[track.id] case final ms?) {
    return Duration(milliseconds: ms);
  }
  final source = ref.read(activeSourceProvider);
  if (source == null) throw StateError('signed out');
  final loader = ref.read(songAudioLoaderProvider);
  final controller = ref.read(lyricsSettingsControllerProvider.notifier);
  final bytes = await loader.loadStart(source, track);
  final offset = autoLyricsOffset(Mp3Song.parse(bytes).soundStart());
  await controller.setAuto(track.id, offset);
  return offset;
}
