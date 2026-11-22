import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/share/mp3_clip.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/lyrics/lyrics_providers.dart';
import 'package:melody/features/share/audio_clip.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lyrics_auto_sync.g.dart';

/// Measures once where the music of [track] really starts and keeps the
/// matching lyrics correction. Does nothing when the song was corrected by
/// hand, was measured before, or auto sync is off; a failure (offline, no
/// MP3 from the server) is tried again next time.
@riverpod
Future<void> lyricsAutoSync(Ref ref, Track track) async {
  final settings = ref.read(lyricsSettingsControllerProvider);
  if (!settings.autoSync ||
      settings.isManual(track.id) ||
      settings.autoOffsetsMs.containsKey(track.id)) {
    return;
  }
  final source = ref.read(activeSourceProvider);
  if (source == null) return;
  final loader = ref.read(songAudioLoaderProvider);
  final controller = ref.read(lyricsSettingsControllerProvider.notifier);
  try {
    final bytes = await loader.loadStart(source, track);
    final start = Mp3Song.parse(bytes).soundStart();
    await controller.setAuto(track.id, autoLyricsOffset(start));
  } on Object {
    // Tried again the next time the lyrics are shown.
  }
}
