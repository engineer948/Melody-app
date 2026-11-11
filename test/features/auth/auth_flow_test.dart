import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/errors/failure.dart';
import 'package:melody/core/errors/result.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/domain/models/server.dart';
import 'package:melody/features/auth/add_server_screen.dart';
import 'package:melody/features/auth/login_screen.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/home/home_screen.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  const en = {LocaleController.localeKey: 'en'};

  Future<void> connect(WidgetTester tester, String address) async {
    await tester.enterText(find.byType(TextField), address);
    await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
    await tester.pumpAndSettle();
  }

  testWidgets('signed out users start on the connect screen', (tester) async {
    await pumpApp(tester, preferences: en, signedIn: false);
    expect(find.byType(AddServerScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('No servers found on your network.'), findsOneWidget);
  });

  testWidgets('address, password, home: the whole sign-in', (tester) async {
    final connector = FakeConnector();
    final container = await pumpApp(
      tester,
      preferences: en,
      signedIn: false,
      connector: connector,
    );

    await connect(tester, 'music.example.com');
    expect(connector.probed, ['music.example.com']);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Home Server'), findsOneWidget);
    expect(find.textContaining('Version 10.10.3'), findsOneWidget);

    // Wrong password first.
    await tester.enterText(find.byType(TextField).first, 'ayla');
    await tester.enterText(find.byType(TextField).last, 'nope');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Wrong user name or password.'), findsOneWidget);
    expect(container.read(sessionControllerProvider).active, isNull);

    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(container.read(sessionControllerProvider).active, testAccount);
    expect(container.read(sessionControllerProvider).activeToken, 'token-1');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Recently added'), findsOneWidget);
    expect(find.text('Gülümse'), findsWidgets);
  });

  testWidgets('an empty user name is refused before any request', (
    tester,
  ) async {
    await pumpApp(tester, preferences: en, signedIn: false);
    await connect(tester, 'music.example.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your user name.'), findsOneWidget);
  });

  testWidgets('servers found on the network can be tapped', (tester) async {
    final connector = FakeConnector()
      ..discovered = [
        ServerInfo(baseUrl: Uri.parse('https://found.local'), name: 'Attic'),
      ];
    await pumpApp(
      tester,
      preferences: en,
      signedIn: false,
      connector: connector,
    );
    expect(find.text('Attic'), findsOneWidget);
    await tester.tap(find.text('Attic'));
    await tester.pumpAndSettle();
    expect(connector.probed, ['https://found.local']);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('a wrong address is explained', (tester) async {
    final connector = FakeConnector()
      ..probeResult = const Err(ParsingFailure());
    await pumpApp(
      tester,
      preferences: en,
      signedIn: false,
      connector: connector,
    );
    await connect(tester, 'example.com');
    expect(
      find.text('No Jellyfin server was found at this address.'),
      findsOneWidget,
    );

    connector.probeResult = const Err(NetworkFailure());
    await connect(tester, 'example.com');
    expect(
      find.text('The server cannot be reached. Check your connection.'),
      findsOneWidget,
    );
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('plain HTTP needs explicit consent', (tester) async {
    final connector = FakeConnector()
      ..probeResult = Ok(
        ServerInfo(baseUrl: Uri.parse('http://192.168.1.10:8096'), name: 'Lan'),
      );
    await pumpApp(
      tester,
      preferences: en,
      signedIn: false,
      connector: connector,
    );

    await connect(tester, '192.168.1.10');
    expect(find.text('Unencrypted connection'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsNothing);

    await connect(tester, '192.168.1.10');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Quick Connect shows a code and signs in once approved', (
    tester,
  ) async {
    final connector = FakeConnector()..quickConnect = true;
    final container = await pumpApp(
      tester,
      preferences: en,
      signedIn: false,
      connector: connector,
    );
    await connect(tester, 'music.example.com');

    await tester.tap(find.text('Use Quick Connect'));
    await tester.pump();
    await tester.pump();
    expect(find.text('123456'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(container.read(sessionControllerProvider).active, isNull);

    connector.quickConnectIsApproved = true;
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(container.read(sessionControllerProvider).active, testAccount);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Quick Connect is hidden when the server lacks it', (
    tester,
  ) async {
    await pumpApp(tester, preferences: en, signedIn: false);
    await connect(tester, 'music.example.com');
    expect(find.text('Use Quick Connect'), findsNothing);
  });

  testWidgets('a rejected token leads back to the sign-in screen', (
    tester,
  ) async {
    final container = await pumpApp(tester, preferences: en);
    await container
        .read(sessionControllerProvider.notifier)
        .expire(testAccount.id);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.textContaining('session has expired'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'ayla',
    );

    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(container.read(sessionControllerProvider).activeExpired, isFalse);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('connect and sign-in screens are accessible', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, preferences: en, signedIn: false);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await connect(tester, 'music.example.com');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
