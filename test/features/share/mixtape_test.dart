import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/domain/share/mixtape.dart';

import '../../helpers/pump_app.dart';

void main() {
  const prefs = {LocaleController.localeKey: 'en'};
  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  late List<MethodCall> shared;
  late Directory temp;

  setUp(() {
    shared = [];
    temp = Directory.systemTemp.createTempSync('melody_mix');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(shareChannel, (call) async {
        shared.add(call);
        return 'dev.fluttercommunity.plus/share/unavailable';
      })
      ..setMockMethodCallHandler(pathChannel, (call) async => temp.path);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(shareChannel, null)
      ..setMockMethodCallHandler(pathChannel, null);
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  Future<void> openLibrary(WidgetTester tester) async {
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
  }

  testWidgets('picked songs become a song letter with a code', (tester) async {
    await pumpApp(tester, preferences: prefs, size: const Size(400, 1400));
    await openLibrary(tester);
    await tester.tap(find.widgetWithText(ListTile, 'Songs'));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Firuze'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hadi'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Song letter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Song letter'));
    await tester.pumpAndSettle();

    expect(find.text('A few songs for you'), findsWidgets);
    await tester.enterText(
      find.widgetWithText(TextField, 'Your note'),
      'Bunları dinle',
    );
    await tester.pumpAndSettle();
    expect(find.text('“Bunları dinle”'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('Send'));
      for (var i = 0; i < 50 && shared.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    final args = shared.single.arguments as Map;
    expect((args['paths'] as List).single, endsWith('.png'));
    final mixtape = Mixtape.decode(args['text'] as String);
    expect(mixtape.note, 'Bunları dinle');
    expect(mixtape.from, 'ayla');
    expect(mixtape.songs.map((s) => s.title), ['Firuze', 'Hadi']);
  });

  testWidgets('a received letter opens like an envelope', (tester) async {
    await pumpApp(tester, preferences: prefs, size: const Size(400, 1400));
    await openLibrary(tester);
    await tester.tap(find.text('Open a song letter'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'merhaba');
    await tester.tap(find.text('Open').last);
    await tester.pumpAndSettle();
    expect(find.text('No song letter found in this text.'), findsOneWidget);

    const letter = Mixtape(
      title: 'Yol için',
      from: 'Ali',
      note: 'Dinle bunu',
      songs: [
        MixtapeSong(id: 't2', title: 'Hadi'),
        MixtapeSong(id: 'nope', title: 'Yok böyle'),
      ],
    );
    await tester.enterText(find.byType(TextField), 'Bak:\n${letter.encode()}');
    await tester.tap(find.text('Open').last);
    await tester.pumpAndSettle();
    expect(find.text('Ali sent you a song letter'), findsOneWidget);

    await tester.tap(find.text('Open'));
    // The reels keep turning: pump instead of settling.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('“Dinle bunu”'), findsOneWidget);
    expect(find.text('Hadi'), findsOneWidget);
    expect(find.text('1 song is not in your library'), findsOneWidget);
    expect(find.text('Save as playlist'), findsOneWidget);
  });
}
