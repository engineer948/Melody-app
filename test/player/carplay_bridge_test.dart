import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/player/carplay_bridge.dart';
import 'package:melody/player/media_browser.dart';
import 'package:melody/player/playback_settings.dart';
import 'package:melody/player/player_controller.dart';

import '../helpers/pump_app.dart';

void main() {
  tearDown(pumpEventQueue);

  test('CarPlay gets the browse tree and can start a song', () async {
    final c = await createContainer(
      preferences: {PlaybackSettingsController.key: '{"fadeMs":0}'},
    );
    c.read(playerControllerProvider);
    final browser = MediaBrowser(c);

    final root = await CarPlayBridge.handle(
      browser,
      const MethodCall('children', 'root'),
    ) as List<Object?>?;
    expect(root!.first, containsPair('id', 'tab:recent'));
    expect(root.first, containsPair('playable', false));

    final songs = await CarPlayBridge.handle(
      browser,
      const MethodCall('children', 'album:a1'),
    ) as List<Object?>?;
    expect(songs!.first, containsPair('playable', true));

    await CarPlayBridge.handle(
      browser,
      const MethodCall('play', 'play|album:a1|t2'),
    );
    expect(c.read(playerControllerProvider).current?.id, 't2');
  });
}
