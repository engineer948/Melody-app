import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/features/social/listen_together.dart';
import 'package:melody/player/player_controller.dart';

import '../../helpers/fake_engine.dart';
import '../../helpers/fake_sync_play.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

Future<void> settle([int ms = 250]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  late FakeSyncServer sync;
  late FakeAudioEngine aliEngine;
  late FakeAudioEngine aylaEngine;

  setUp(() {
    sync = FakeSyncServer();
    aliEngine = FakeAudioEngine();
    aylaEngine = FakeAudioEngine();
  });

  Future<ProviderContainer> member(String id, FakeAudioEngine engine) =>
      createContainer(
        engine: engine,
        overrides: [
          syncPlayTransportProvider.overrideWithValue(
            FakeSyncTransport(sync, id),
          ),
        ],
      );

  test('when a song ends, the group moves on together', () async {
    final ali = await member('admin', aliEngine);
    final ayla = await member('ayla', aylaEngine);
    await ali.read(playerControllerProvider.notifier).playTracks([
      makeTrack('t1'),
      makeTrack('t2'),
      makeTrack('t3'),
    ]);
    final groupId = await ali
        .read(listenTogetherProvider.notifier)
        .createGroup('Cuma akşamı');
    await settle();
    await ayla.read(listenTogetherProvider.notifier).joinGroup(groupId!);
    await settle();
    expect(aylaEngine.state.playing, isTrue);

    // Ali's player reaches the end of t1 and goes on by itself.
    aliEngine.advanceTo(1);
    await settle();
    expect(sync.log, contains('admin:next'));
    expect(ayla.read(playerControllerProvider).queue.index, 1);
    expect(aylaEngine.state.playing, isTrue);
    expect(aliEngine.state.playing, isTrue);
  });

  test('anyone on the server can open a group and others can join', () async {
    final ali = await member('admin', aliEngine);
    final ayla = await member('ayla', aylaEngine);
    await ali.read(playerControllerProvider.notifier).playTracks([
      makeTrack('t1'),
    ]);
    final groupId = await ali
        .read(listenTogetherProvider.notifier)
        .createGroup('Cuma akşamı');
    expect(groupId, 'g1');
    await settle();
    expect(aliEngine.state.playing, isTrue);

    final groups = await ayla.read(listenTogetherProvider.notifier).groups();
    expect(groups.single.id, 'g1');
    expect(
      await ayla.read(listenTogetherProvider.notifier).joinGroup('g1'),
      isTrue,
    );
    await settle();
    expect(aylaEngine.loadedIds, ['t1']);
    expect(aylaEngine.state.playing, isTrue);
  });
}
