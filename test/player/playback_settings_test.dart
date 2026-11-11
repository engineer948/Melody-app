import 'package:flutter_test/flutter_test.dart';
import 'package:melody/player/playback_settings.dart';

import '../helpers/fakes.dart';

void main() {
  final tagged = makeTrack('t').copyWith(trackGainDb: -6, albumGainDb: -3);
  final untagged = makeTrack('u');

  test('modes pick the right tag', () {
    double volume(ReplayGainMode mode, {bool album = false}) =>
        PlaybackSettings(replayGain: mode)
            .volumeFor(tagged, albumInOrder: album);
    expect(volume(ReplayGainMode.off), 1);
    expect(volume(ReplayGainMode.track), closeTo(0.501, 0.001));
    expect(volume(ReplayGainMode.album), closeTo(0.708, 0.001));
    expect(volume(ReplayGainMode.auto), closeTo(0.501, 0.001));
    expect(volume(ReplayGainMode.auto, album: true), closeTo(0.708, 0.001));
  });

  test('preamp and untagged gain apply, positive gain is capped', () {
    const settings = PlaybackSettings(preampDb: -6, untaggedGainDb: -6);
    expect(
      settings.volumeFor(untagged, albumInOrder: false),
      closeTo(0.251, 0.001),
    );
    final quiet = makeTrack('q').copyWith(trackGainDb: 8);
    expect(
      const PlaybackSettings(replayGain: ReplayGainMode.track)
          .volumeFor(quiet, albumInOrder: false),
      1,
    );
  });

  test('survives a JSON round trip and tolerates junk', () {
    const settings = PlaybackSettings(
      replayGain: ReplayGainMode.album,
      preampDb: -2,
      fadeMs: 300,
      equalizerEnabled: true,
      equalizerGains: [1, 2, 3],
      loudnessBoostDb: 4,
    );
    final restored = PlaybackSettings.fromJson(settings.toJson());
    expect(restored.toJson(), settings.toJson());
    expect(
      PlaybackSettings.fromJson(const {'replayGain': 'loud'}).replayGain,
      ReplayGainMode.auto,
    );
  });
}
