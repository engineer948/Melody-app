import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/social/social_models.dart';
import 'package:melody/features/social/social_controller.dart';
import 'package:melody/features/social/social_home.dart';

import '../../helpers/fake_social.dart';
import '../../helpers/pump_app.dart';

const track = Track(
  id: 't1',
  title: 'Firuze',
  artists: [NamedRef(id: 'a', name: 'Sezen Aksu')],
  albumId: 'al1',
);

void main() {
  late FakeSocialServer server;

  setUp(() {
    server = FakeSocialServer();
    SocialController.refreshEvery = Duration.zero;
  });

  Future<ProviderContainer> user(String id, {bool admin = false}) =>
      createContainer(
        overrides: [
          socialApiProvider.overrideWithValue(
            FakeSocialApi(server, id, admin: admin),
          ),
        ],
      );

  Future<SocialController> ready(ProviderContainer c) async {
    c.read(socialControllerProvider);
    final controller = c.read(socialControllerProvider.notifier);
    await controller.refresh();
    return controller;
  }

  group('models', () {
    test('broken or hostile stored text is ignored or clipped', () {
      expect(SocialInbox.decode('not json'), isNull);
      expect(SocialInbox.decode('[]'), isNull);
      expect(SocialConsent.decode('{"granted":"yes"}'), isNull);
      final inbox = SocialInbox.decode(
        '{"fromId":"a","fromName":"${'x' * 500}",'
        '"requestedAt":"2026-01-01T00:00:00Z",'
        '"dedications":[{"id":"1"},{"id":"2","trackId":"t",'
        '"at":"2026-01-01T00:00:00Z","note":"${'n' * 500}"}],'
        '"welcome":{"text":"hi","color":305419896}}',
      )!;
      expect(inbox.fromName.length, 40);
      expect(inbox.dedications, hasLength(1), reason: 'broken entry dropped');
      expect(inbox.dedications.single.note.length, maxNoteLength);
      expect(inbox.welcome!.color, 0xFF345678, reason: 'always opaque');
      final consent = SocialConsent.decode(
        '{"fromId":"a","granted":true,"features":["welcome","bogus"]}',
      )!;
      expect(consent.features, {SocialFeature.welcome});
      expect(consent.allows(SocialFeature.welcome), isTrue);
      expect(consent.allows(SocialFeature.dedications), isFalse);
    });
  });

  test('nothing reaches the recipient before she allows it', () async {
    final ali = await user('admin', admin: true);
    final ayla = await user('ayla');
    final aliCtl = await ready(ali);
    await aliCtl.chooseRecipient(const SocialUser(id: 'ayla', name: 'Ayla'));
    await aliCtl.requestPermission('Ali');

    // Before an answer the sender cannot send anything.
    expect(
      ali.read(socialControllerProvider).canSend(SocialFeature.dedications),
      isFalse,
    );
    expect(await aliCtl.dedicate(track, note: 'hi'), isFalse);

    final aylaCtl = await ready(ayla);
    var state = ayla.read(socialControllerProvider);
    expect(state.mustAnswer, isTrue);
    expect(state.inbox!.fromName, 'Ali');
    expect(state.shows(SocialFeature.welcome), isFalse);

    // She declines: still nothing can be sent.
    await aylaCtl.answer(granted: false);
    await aliCtl.refresh();
    expect(await aliCtl.dedicate(track), isFalse);
    expect(ayla.read(socialControllerProvider).mustAnswer, isFalse);

    // She changes her mind, but only for songs.
    await aylaCtl.answer(granted: true, features: {SocialFeature.dedications});
    await aliCtl.refresh();
    state = ali.read(socialControllerProvider);
    expect(state.canSend(SocialFeature.dedications), isTrue);
    expect(state.canSend(SocialFeature.welcome), isFalse);
    expect(
      await aliCtl.dedicate(track, note: 'Bunu duyunca aklıma geldin'),
      isTrue,
    );
    await aliCtl.setWelcome('Hoş geldin', 0xFFE91E63);
    await aliCtl.createSharedPlaylist('Bizim liste');
    expect(server.playlists, isEmpty, reason: 'playlist not allowed');

    await aylaCtl.refresh();
    state = ayla.read(socialControllerProvider);
    expect(state.inbox!.dedications.single.note, 'Bunu duyunca aklıma geldin');
    expect(socialGreeting(state), isNull, reason: 'welcome not allowed');
    expect(socialAccent(state), isNull);

    // She likes the song; the sender sees it.
    await aylaCtl.toggleLike(state.inbox!.dedications.single);
    await aylaCtl.markSeen(state.inbox!.dedications.single);
    await aliCtl.refresh();
    final answer = ali.read(socialControllerProvider).outgoingAnswer!;
    expect(answer.liked, hasLength(1));
    expect(answer.seen, hasLength(1));
  });

  test('greeting, color and shared playlist once allowed', () async {
    final ali = await user('admin', admin: true);
    final ayla = await user('ayla');
    final aliCtl = await ready(ali);
    await aliCtl.chooseRecipient(const SocialUser(id: 'ayla', name: 'Ayla'));
    await aliCtl.requestPermission('Ali');
    final aylaCtl = await ready(ayla);
    await aylaCtl.answer(granted: true, features: SocialFeature.values.toSet());
    await aliCtl.refresh();
    await aliCtl.setWelcome('Hoş geldin Ayla', 0xFFE91E63);
    await aliCtl.createSharedPlaylist('Bizim liste');
    expect(server.playlists.values.single, 'ayla');

    await aylaCtl.refresh();
    var state = ayla.read(socialControllerProvider);
    expect(socialGreeting(state), 'Hoş geldin Ayla');
    expect(socialAccent(state), const Color(0xFFE91E63));
    expect(state.inbox!.playlist!.name, 'Bizim liste');

    // He changes it later; she turns the greeting off.
    await aliCtl.setWelcome('İyi dinlemeler', null);
    await aylaCtl.refresh();
    expect(
      socialGreeting(ayla.read(socialControllerProvider)),
      'İyi dinlemeler',
    );
    expect(socialAccent(ayla.read(socialControllerProvider)), isNull);
    await aylaCtl.setFeature(SocialFeature.welcome, on: false);
    state = ayla.read(socialControllerProvider);
    expect(socialGreeting(state), isNull);
  });

  test('a non-admin cannot write to someone else', () async {
    final ayla = FakeSocialApi(server, 'ayla');
    expect(
      () => ayla.writeInbox(
        'admin',
        SocialInbox(
          fromId: 'ayla',
          fromName: 'x',
          requestedAt: DateTime.utc(2026),
        ),
      ),
      throwsStateError,
    );
  });

  testWidgets('the request card asks before showing anything', (tester) async {
    server.inboxes['ayla'] = SocialInbox(
      fromId: 'admin',
      fromName: 'Ali',
      requestedAt: DateTime.utc(2026),
      dedications: [
        Dedication(
          id: 'd1',
          trackId: 'track-1',
          title: 'Firuze',
          artist: 'Sezen Aksu',
          note: 'Bunu duyunca aklıma geldin',
          at: DateTime.utc(2026),
        ),
      ],
      welcome: Welcome(text: 'Hoş geldin Ayla', at: DateTime.utc(2026)),
    ).encode();
    await pumpApp(
      tester,
      preferences: {LocaleController.localeKey: 'en'},
      overrides: [
        socialApiProvider.overrideWithValue(FakeSocialApi(server, 'ayla')),
      ],
    );
    expect(find.text('Ali wants to share music with you'), findsOneWidget);
    expect(find.text('Bunu duyunca aklıma geldin'), findsNothing);
    expect(find.text('Hoş geldin Ayla'), findsNothing);

    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    // Unticks the greeting, allows the rest.
    await tester.tap(find.text('Greeting and color'));
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Allow'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ali wants to share music with you'), findsNothing);
    expect(find.text('From Ali'), findsOneWidget);
    expect(find.text('Bunu duyunca aklıma geldin'), findsOneWidget);
    expect(find.text('Hoş geldin Ayla'), findsNothing);
    final consent = SocialConsent.decode(server.consents['ayla'])!;
    expect(consent.features, isNot(contains(SocialFeature.welcome)));
    expect(consent.features, contains(SocialFeature.dedications));
  });

  testWidgets('the sender sends a song with a note from the song menu', (
    tester,
  ) async {
    server
      ..inboxes['ayla'] = SocialInbox(
        fromId: 'admin',
        fromName: 'Ali',
        requestedAt: DateTime.utc(2026),
      ).encode()
      ..consents['ayla'] = const SocialConsent(
        fromId: 'admin',
        granted: true,
        features: {SocialFeature.dedications},
      ).encode();
    final container = await pumpApp(
      tester,
      preferences: {LocaleController.localeKey: 'en'},
      overrides: [
        socialApiProvider.overrideWithValue(
          FakeSocialApi(server, 'admin', admin: true),
        ),
      ],
    );
    await container
        .read(socialControllerProvider.notifier)
        .chooseRecipient(const SocialUser(id: 'ayla', name: 'Ayla'));
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Songs'));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Firuze'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Send to Ayla'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send to Ayla'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Bunu dinle');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    final inbox = SocialInbox.decode(server.inboxes['ayla'])!;
    expect(inbox.dedications.single.title, 'Firuze');
    expect(inbox.dedications.single.note, 'Bunu dinle');
    expect(find.text('Sent to Ayla'), findsOneWidget);
  });
}
