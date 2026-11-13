import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/domain/social/social_models.dart';
import 'package:melody/features/social/listen_together.dart';
import 'package:melody/features/social/social_controller.dart';
import 'package:melody/player/player_controller.dart';

import '../../helpers/fake_engine.dart';
import '../../helpers/fake_social.dart';
import '../../helpers/fake_sync_play.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

Future<void> settle([int ms = 250]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  late FakeSocialServer social;
  late FakeSyncServer sync;
  late FakeAudioEngine aliEngine;
  late FakeAudioEngine aylaEngine;

  setUp(() {
    social = FakeSocialServer();
    sync = FakeSyncServer();
    aliEngine = FakeAudioEngine();
    aylaEngine = FakeAudioEngine();
    SocialController.refreshEvery = Duration.zero;
  });

  Future<ProviderContainer> member(
    String id,
    FakeAudioEngine engine, {
    bool admin = false,
  }) => createContainer(
    engine: engine,
    overrides: [
      socialApiProvider.overrideWithValue(
        FakeSocialApi(social, id, admin: admin),
      ),
      syncPlayTransportProvider.overrideWithValue(FakeSyncTransport(sync, id)),
    ],
  );

  /// Ali asks, Ayla allows [features].
  Future<(ProviderContainer, ProviderContainer)> pair(
    Set<SocialFeature> features,
  ) async {
    final ali = await member('admin', aliEngine, admin: true);
    final ayla = await member('ayla', aylaEngine);
    final aliSocial = ali.read(socialControllerProvider.notifier);
    ali.read(socialControllerProvider);
    await aliSocial.refresh();
    await aliSocial.chooseRecipient(const SocialUser(id: 'ayla', name: 'Ayla'));
    await aliSocial.requestPermission('Ali');
    ayla.read(socialControllerProvider);
    final aylaSocial = ayla.read(socialControllerProvider.notifier);
    await aylaSocial.refresh();
    await aylaSocial.answer(granted: true, features: features);
    await aliSocial.refresh();
    return (ali, ayla);
  }

  test('needs her permission', () async {
    final (ali, _) = await pair({SocialFeature.dedications});
    expect(await ali.read(listenTogetherProvider.notifier).start(), isFalse);
    expect(sync.log, isEmpty);
  });

  test(
    'both play the same song at the same moment and follow each other',
    () async {
      final (ali, ayla) = await pair(SocialFeature.values.toSet());
      // Ali is already listening to something.
      await ali.read(playerControllerProvider.notifier).playTracks([
        makeTrack('t1'),
        makeTrack('t2'),
      ]);
      expect(aliEngine.state.playing, isTrue);

      final aliListen = ali.read(listenTogetherProvider.notifier);
      expect(await aliListen.start(), isTrue);
      await settle();
      expect(ali.read(listenTogetherProvider).active, isTrue);
      // The invitation reached her inbox.
      final aylaSocial = ayla.read(socialControllerProvider.notifier);
      await aylaSocial.refresh();
      expect(ayla.read(socialControllerProvider).inbox!.listenGroupId, 'g1');
      // The group took over Ali's queue and plays it.
      expect(aliEngine.loadedIds, ['t1', 't2']);
      expect(aliEngine.state.playing, isTrue);

      // Ayla joins: she gets the same queue and starts playing.
      expect(await ayla.read(listenTogetherProvider.notifier).join(), isTrue);
      await settle();
      expect(aylaEngine.loadedIds, ['t1', 't2']);
      expect(aylaEngine.state.playing, isTrue);
      expect(
        ayla.read(listenTogetherProvider).participants,
        containsAll(['admin', 'ayla']),
      );

      // Her pause pauses both, at the same position.
      await ayla.read(playerControllerProvider.notifier).pause();
      await settle();
      expect(sync.log, contains('ayla:pause'));
      expect(aliEngine.state.playing, isFalse);
      expect(aylaEngine.state.playing, isFalse);
      expect(aliEngine.position, aylaEngine.position);

      // His seek moves both; then play resumes both.
      await ali
          .read(playerControllerProvider.notifier)
          .seek(const Duration(seconds: 42));
      await settle();
      expect(aliEngine.position, const Duration(seconds: 42));
      expect(aylaEngine.position, const Duration(seconds: 42));
      await ali.read(playerControllerProvider.notifier).play();
      await settle();
      expect(aliEngine.state.playing, isTrue);
      expect(aylaEngine.state.playing, isTrue);

      // Skipping goes to the group too.
      await ayla.read(playerControllerProvider.notifier).next();
      await settle();
      expect(ali.read(playerControllerProvider).queue.index, 1);
      expect(ayla.read(playerControllerProvider).queue.index, 1);

      // A new song chosen by her replaces the queue for both.
      await ayla.read(playerControllerProvider.notifier).playTracks([
        makeTrack('t9'),
      ]);
      await settle();
      expect(aliEngine.loadedIds, ['t9']);
      expect(aylaEngine.loadedIds, ['t9']);
      expect(aliEngine.state.playing && aylaEngine.state.playing, isTrue);

      // Leaving gives the player back and withdraws the invitation.
      await ali.read(listenTogetherProvider.notifier).leave();
      expect(ali.read(listenTogetherProvider).active, isFalse);
      expect(ali.read(playerControllerProvider.notifier).relay, isNull);
      await aylaSocial.refresh();
      expect(ayla.read(socialControllerProvider).inbox!.listenGroupId, isNull);
    },
  );

  test('when a song ends, the group moves on together', () async {
    final (ali, ayla) = await pair(SocialFeature.values.toSet());
    await ali.read(playerControllerProvider.notifier).playTracks([
      makeTrack('t1'),
      makeTrack('t2'),
      makeTrack('t3'),
    ]);
    await ali.read(listenTogetherProvider.notifier).start();
    await settle();
    await ayla.read(socialControllerProvider.notifier).refresh();
    await ayla.read(listenTogetherProvider.notifier).join();
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
}
