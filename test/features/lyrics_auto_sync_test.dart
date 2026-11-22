import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/domain/share/mp3_clip.dart';
import 'package:melody/features/lyrics/lyrics_auto_sync.dart';
import 'package:melody/features/lyrics/lyrics_providers.dart';
import 'package:melody/features/share/audio_clip.dart';

import '../helpers/fake_mp3.dart';
import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

/// [silence] seconds of quiet, then music.
Uint8List _song(double silence, {int seconds = 40}) {
  final frames = seconds * 1000000 ~/ fakeFrameUs;
  return fakeSong([
    for (var i = 0; i < frames; i++)
      if (i * fakeFrameUs < silence * 1000000) 20 else 170,
  ]);
}

class _Loader implements SongAudioLoader {
  _Loader(this.bytes);

  final Uint8List bytes;
  int calls = 0;

  @override
  Future<Uint8List> load(MusicSource source, Track track) async => bytes;

  @override
  Future<Uint8List> loadStart(
    MusicSource source,
    Track track, {
    int maxBytes = 800000,
  }) async {
    calls++;
    return bytes;
  }
}

void main() {
  test('the music starts after the silence; blips are ignored', () {
    final start = Mp3Song.parse(_song(2)).soundStart()!;
    expect(start.inMilliseconds, closeTo(2000, 60));
    expect(Mp3Song.parse(_song(0)).soundStart(), isNull, reason: 'no rise');
    const frames = 10 * 1000000 ~/ fakeFrameUs;
    final blip = fakeSong([
      for (var i = 0; i < frames; i++)
        if (i == 5 || i * fakeFrameUs >= 3000000) 170 else 20,
    ]);
    expect(Mp3Song.parse(blip).soundStart()!.inMilliseconds, closeTo(3000, 60));
  });

  test('only clear silence moves the lyrics', () {
    expect(autoLyricsOffset(null), Duration.zero);
    expect(autoLyricsOffset(const Duration(milliseconds: 300)), Duration.zero);
    expect(
      autoLyricsOffset(const Duration(milliseconds: 1500)),
      const Duration(milliseconds: 1500),
    );
  });

  test('measured once, remembered; a hand correction wins', () async {
    final loader = _Loader(_song(2));
    final c = await createContainer(
      overrides: [songAudioLoaderProvider.overrideWithValue(loader)],
    );
    final track = makeTrack('t1');
    await c.read(lyricsAutoSyncProvider(track).future);
    var s = c.read(lyricsSettingsControllerProvider);
    expect(s.offsetOf('t1').inMilliseconds, closeTo(2000, 60));
    expect(s.isManual('t1'), isFalse);

    c.invalidate(lyricsAutoSyncProvider(track));
    await c.read(lyricsAutoSyncProvider(track).future);
    expect(loader.calls, 1, reason: 'kept');

    final controller = c.read(lyricsSettingsControllerProvider.notifier);
    final auto = s.offsetOf('t1');
    await controller.shift('t1', -auto);
    s = c.read(lyricsSettingsControllerProvider);
    expect(s.offsetOf('t1'), Duration.zero, reason: 'zero by hand is kept');
    expect(s.isManual('t1'), isTrue);
    await controller.resetManual('t1');
    expect(c.read(lyricsSettingsControllerProvider).offsetOf('t1'), auto);

    await controller.update((s) => s.copyWith(autoSync: false));
    expect(
      c.read(lyricsSettingsControllerProvider).offsetOf('t1'),
      Duration.zero,
    );
    // Settings survive a restart.
    final back = LyricsSettings.fromJson(
      c.read(lyricsSettingsControllerProvider).toJson(),
    );
    expect(back.autoOffsetsMs['t1'], auto.inMilliseconds);
  });
}
