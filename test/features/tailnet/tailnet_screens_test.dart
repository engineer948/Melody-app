import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:melody/core/router/app_routes.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/data/tailnet/invite_code.dart';
import 'package:melody/data/tailnet/tailnet_bridge.dart';
import 'package:melody/features/auth/login_screen.dart';
import 'package:melody/features/tailnet/create_invite_screen.dart';
import 'package:melody/features/tailnet/join_tailnet_screen.dart';
import 'package:melody/features/tailnet/qr_code.dart';
import 'package:melody/features/tailnet/tailnet_controller.dart';

import '../../helpers/fake_tailnet.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

const Map<String, Object> prefs = {LocaleController.localeKey: 'en'};
const key = 'tskey-auth-kSecret123CNTRL-zzzzzzzzzzzz';

void main() {
  late FakeTailnetBridge bridge;

  setUp(() {
    bridge = FakeTailnetBridge();
    TailnetController.fastPoll = const Duration(milliseconds: 1);
  });

  Future<void> pump(WidgetTester tester, {bool signedIn = false}) => pumpApp(
    tester,
    preferences: prefs,
    signedIn: signedIn,
    size: const Size(420, 1400),
    connector: FakeConnector(),
    overrides: [
      tailnetBootstrapProvider.overrideWithValue(
        const TailnetBootstrap(available: true),
      ),
      tailnetBridgeProvider.overrideWithValue(bridge),
      tailnetSecretStoreProvider.overrideWithValue(MemoryTailnetSecretStore()),
    ],
  );

  testWidgets('an invite code connects and opens the sign-in page', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Join with an invite code'));
    await tester.pumpAndSettle();
    expect(find.byType(JoinTailnetScreen), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'nonsense');
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    expect(find.text('This is not a valid invite code.'), findsOneWidget);

    final code = TailnetInvite.create(
      authKey: key,
      server: '100.70.0.5',
    ).encode();
    await tester.enterText(find.byType(TextField), code);
    await tester.runAsync(() async {
      await tester.tap(find.text('Connect'));
      for (
        var i = 0;
        i < 50 && find.byType(LoginScreen).evaluate().isEmpty;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(bridge.starts.single['authKey'], key);
  });

  testWidgets('a refused key is explained', (tester) async {
    bridge.reports = [
      const TailnetReport(TailnetStatus.error, error: 'invalid key: expired'),
    ];
    await pump(tester);
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .push(AppRoutes.joinTailnet)
        .ignore();
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      TailnetInvite.create(authKey: key, server: '100.70.0.5').encode(),
    );
    await tester.runAsync(() async {
      await tester.tap(find.text('Connect'));
      for (var i = 0; i < 50; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('The auth key was refused'), findsOneWidget);
    expect(bridge.logouts, 1);
  });

  testWidgets('creating an invite shows code, QR and the access rule', (
    tester,
  ) async {
    await pump(tester, signedIn: true);
    final context = tester.element(find.byType(Scaffold).first);
    CreateInviteScreen.open(context).ignore();
    await tester.pumpAndSettle();
    expect(find.textContaining('"tag:melody-friend"'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'tskey-api-kAdmin123-zzzzzzzz');
    await tester.enterText(fields.at(1), '100.70.0.5:8096');
    await tester.tap(find.text('Create code'));
    await tester.pumpAndSettle();
    expect(find.textContaining('API keys and OAuth secrets'), findsOneWidget);
    expect(find.byType(QrCodeView), findsNothing);

    await tester.enterText(fields.at(0), key);
    await tester.tap(find.text('Create code'));
    await tester.pumpAndSettle();
    expect(find.byType(QrCodeView), findsOneWidget);
    final codeText = find.textContaining('MELODY1-');
    await tester.dragUntilVisible(
      codeText,
      find.byType(ListView).last,
      const Offset(0, -300),
    );
    final code = tester.widget<EditableText>(codeText).controller.text;
    final decoded = TailnetInvite.decode(code);
    expect(decoded.authKey, key);
    expect(decoded.server.toString(), 'http://100.70.0.5:8096');
    // The rule is filled in with the server.
    expect(find.textContaining('"100.70.0.5:8096"'), findsOneWidget);
  });
}
