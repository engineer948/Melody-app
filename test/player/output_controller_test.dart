import 'package:flutter_test/flutter_test.dart';
import 'package:melody/data/dlna/dlna_models.dart';
import 'package:melody/player/output_controller.dart';
import 'package:melody/player/playback_settings.dart';
import 'package:melody/player/player_controller.dart';

import '../helpers/fake_engine.dart';
import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

void main() {
  tearDown(pumpEventQueue);

  test('switching the output moves the queue to the other engine', () async {
    final phone = FakeAudioEngine();
    final speaker = FakeAudioEngine();
    final renderer = DlnaRenderer(
      id: 'r1',
      name: 'Speaker',
      avTransportUrl: Uri.parse('http://speaker/avt'),
    );
    final c = await createContainer(
      preferences: {PlaybackSettingsController.key: '{"fadeMs":0}'},
      engineOverride: audioEngineProvider.overrideWith(
        (ref) => ref.watch(outputControllerProvider) == null ? phone : speaker,
      ),
    );
    c.listen(playerControllerProvider, (_, _) {});
    final tracks = [for (var i = 0; i < 3; i++) makeTrack('t$i')];
    await c
        .read(playerControllerProvider.notifier)
        .playTracks(tracks, start: 1);
    phone.position = const Duration(seconds: 30);

    await switchOutput(c, renderer);
    await pumpEventQueue();

    expect(c.read(outputControllerProvider), renderer);
    expect(speaker.loadedIds, ['t0', 't1', 't2']);
    expect(speaker.state.index, 1);
    expect(speaker.position, const Duration(seconds: 30));
    expect(speaker.log, contains('play'));
    final state = c.read(playerControllerProvider);
    expect(state.current?.id, 't1');
    expect(state.playing, isTrue);

    // And back to the phone.
    await switchOutput(c, null);
    await pumpEventQueue();
    expect(c.read(outputControllerProvider), isNull);
    expect(c.read(playerControllerProvider).current?.id, 't1');
  });
}
