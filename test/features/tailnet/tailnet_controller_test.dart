import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/data/tailnet/invite_code.dart';
import 'package:melody/data/tailnet/tailnet_bridge.dart';
import 'package:melody/data/tailnet/tailnet_routing_connector.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/tailnet/qr_code.dart';
import 'package:melody/features/tailnet/tailnet_controller.dart';

import '../../helpers/fake_tailnet.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

const authKey = 'tskey-auth-kSecret123CNTRL-zzzzzzzzzzzz';

final invite = TailnetInvite.create(
  authKey: authKey,
  server: '100.70.0.5:8096',
  name: 'Ali',
);

void main() {
  late FakeTailnetBridge bridge;
  late MemoryTailnetSecretStore secrets;

  setUp(() {
    bridge = FakeTailnetBridge();
    secrets = MemoryTailnetSecretStore();
    TailnetController.fastPoll = const Duration(milliseconds: 1);
    TailnetController.joinTimeout = const Duration(seconds: 2);
    TailnetController.crashWindow = const Duration(milliseconds: 1);
  });

  Future<ProviderContainer> container({bool signedIn = false}) =>
      createContainer(
        signedIn: signedIn,
        overrides: [
          tailnetBootstrapProvider.overrideWithValue(
            const TailnetBootstrap(available: true),
          ),
          tailnetBridgeProvider.overrideWithValue(bridge),
          tailnetSecretStoreProvider.overrideWithValue(secrets),
        ],
      );

  test(
    'joining keeps the secrets in the keystore, never the auth key',
    () async {
      final c = await container();
      final report = await c
          .read(tailnetControllerProvider.notifier)
          .join(invite);
      expect(report.status, TailnetStatus.running);

      final start = bridge.starts.single;
      expect(start['authKey'], authKey);
      expect(start['target'], 'http://100.70.0.5:8096');
      expect(start['hostname'], matches(RegExp(r'^melody-[0-9a-f]{6}$')));
      // 256-bit random secrets.
      expect(start['secret'], matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(start['stateKey'], matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(start['secret'], isNot(start['stateKey']));
      expect(secrets.secrets?.proxySecret, start['secret']);

      final prefs = c.read(preferencesProvider);
      for (final key in prefs.getKeys()) {
        expect('${prefs.get(key)}', isNot(contains('tskey')), reason: key);
        expect(
          '${prefs.get(key)}',
          isNot(contains(start['secret']! as String)),
        );
      }

      final state = c.read(tailnetControllerProvider);
      expect(
        state.local.toString(),
        'http://127.0.0.1:41641/${start['secret']}',
      );
      final router = c.read(tailnetRouterProvider);
      expect(
        router.route(Uri.parse('http://100.70.0.5:8096/Items')).toString(),
        'http://127.0.0.1:41641/${start['secret']}/Items',
      );
    },
  );

  test('a refused key leaves nothing behind', () async {
    bridge.reports = [
      const TailnetReport(TailnetStatus.starting),
      const TailnetReport(TailnetStatus.error, error: 'invalid key: used'),
    ];
    final c = await container();
    final report = await c
        .read(tailnetControllerProvider.notifier)
        .join(invite);
    expect(report.status, TailnetStatus.error);
    expect(report.error, contains('invalid key'));
    expect(bridge.logouts, 1);
    expect(secrets.secrets, isNull);
    expect(c.read(tailnetControllerProvider).configured, isFalse);
    expect(
      c.read(preferencesProvider).getString(TailnetController.targetKey),
      isNull,
    );
  });

  test('waiting for approval is reported, not treated as failure', () async {
    bridge.reports = [
      const TailnetReport(TailnetStatus.starting),
      const TailnetReport(TailnetStatus.needsApproval),
    ];
    final c = await container();
    final report = await c
        .read(tailnetControllerProvider.notifier)
        .join(invite);
    expect(report.status, TailnetStatus.needsApproval);
    expect(c.read(tailnetControllerProvider).configured, isTrue);
    expect(secrets.secrets, isNotNull);
  });

  test('restarts without the auth key from saved settings', () async {
    final first = await container();
    await first.read(tailnetControllerProvider.notifier).join(invite);
    // Let the start count as survived.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final saved = secrets.secrets!;
    final prefs = first.read(preferencesProvider);
    final restarted = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        tailnetBootstrapProvider.overrideWithValue(
          TailnetBootstrap(available: true, secrets: saved),
        ),
        tailnetBridgeProvider.overrideWithValue(bridge),
        tailnetSecretStoreProvider.overrideWithValue(secrets),
      ],
    );
    addTearDown(restarted.dispose);
    final state = restarted.read(tailnetControllerProvider);
    expect(state.configured, isTrue);
    expect(
      state.local.toString(),
      'http://127.0.0.1:41641/${saved.proxySecret}',
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final again = bridge.starts.last;
    expect(again['authKey'], '');
    expect(again['port'], 41641);
    expect(again['hostname'], bridge.starts.first['hostname']);
  });

  test(
    'leaving logs out, wipes secrets and signs out of that server',
    () async {
      final c = await container(signedIn: true);
      final notifier = c.read(tailnetControllerProvider.notifier);
      await notifier.join(invite);
      final tailnetAccount = testAccount.copyWith(
        id: 'jellyfin:tail:u2',
        baseUrl: Uri.parse('http://100.70.0.5:8096'),
      );
      await c
          .read(sessionControllerProvider.notifier)
          .signedIn(AuthSession(account: tailnetAccount, accessToken: 't2'));
      expect(c.read(sessionControllerProvider).accounts, hasLength(2));

      await notifier.leave();
      expect(bridge.logouts, 1);
      expect(secrets.secrets, isNull);
      expect(c.read(tailnetControllerProvider).configured, isFalse);
      final accounts = c.read(sessionControllerProvider).accounts;
      expect(accounts.map((a) => a.id), [testAccount.id]);
    },
  );

  test('a start that killed the app is not repeated by itself', () async {
    TailnetController.crashWindow = const Duration(milliseconds: 50);
    final first = await container();
    await first.read(tailnetControllerProvider.notifier).join(invite);
    final prefs = first.read(preferencesProvider);
    // Survived the start: the guard is cleared.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(prefs.getBool(TailnetController.startingKey), isNull);

    // Simulate being killed during the next start.
    await prefs.setBool(TailnetController.startingKey, true);
    bridge
      ..starts.clear()
      ..crash = 'panic: boom';
    final restarted = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        tailnetBootstrapProvider.overrideWithValue(
          TailnetBootstrap(available: true, secrets: secrets.secrets),
        ),
        tailnetBridgeProvider.overrideWithValue(bridge),
        tailnetSecretStoreProvider.overrideWithValue(secrets),
      ],
    );
    addTearDown(restarted.dispose);
    final state = restarted.read(tailnetControllerProvider);
    expect(state.crashed, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bridge.starts, isEmpty, reason: 'no automatic start after a crash');
    expect(
      restarted.read(tailnetControllerProvider).crashReport,
      'panic: boom',
    );

    await restarted.read(tailnetControllerProvider.notifier).retry();
    expect(bridge.starts, hasLength(1));
    expect(restarted.read(tailnetControllerProvider).crashed, isFalse);
  });

  test('a dropped connection is restarted, a missing key is not', () async {
    final c = await container();
    final notifier = c.read(tailnetControllerProvider.notifier);
    await notifier.join(invite);
    expect(bridge.starts, hasLength(1));

    bridge.reports = [const TailnetReport(TailnetStatus.stopped)];
    await notifier.ensureConnected();
    expect(bridge.stops, 1);
    expect(bridge.starts, hasLength(2));
    expect(bridge.starts.last['authKey'], '', reason: 'key never reused');

    // Removed from the tailnet: reconnecting would not help.
    bridge.reports = [const TailnetReport(TailnetStatus.needsLogin)];
    await notifier.ensureConnected();
    expect(bridge.starts, hasLength(2));
  });

  group('TailnetRoutingConnector', () {
    test(
      'probes and signs in through the proxy, saves the real address',
      () async {
        final target = Uri.parse('http://100.70.0.5:8096');
        final local = Uri.parse('http://127.0.0.1:41641/abc');
        final inner = FakeConnector()
          ..probeResult = Ok(testServer.copyWith(baseUrl: local));
        final connector = TailnetRoutingConnector(
          inner,
          TailnetRouter(target: target, local: local),
        );
        final probed = await connector.probe('100.70.0.5:8096');
        expect(inner.probed, ['http://127.0.0.1:41641/abc']);
        final server = probed.valueOrNull!;
        expect(server.baseUrl, target);
        expect(server.isInsecure, isFalse, reason: 'WireGuard-encrypted');

        final session = await connector.signIn(
          server,
          username: 'ayla',
          password: 'secret',
        );
        expect(session.valueOrNull, isNotNull);

        // Other servers are untouched.
        await connector.probe('music.example.com');
        expect(inner.probed.last, 'music.example.com');
      },
    );
  });

  test('QR codes survive a round trip through a PNG picture', () async {
    final code = invite.encode();
    final png = await qrPng(code, pixels: 600);
    expect(png, isA<Uint8List>());
    expect(await decodeQrImage(png), code);
    expect(await decodeQrImage(Uint8List.fromList([1, 2, 3])), isNull);
  });
}
