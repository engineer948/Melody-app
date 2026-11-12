import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/features/share/share_screen.dart';
import 'package:melody/features/share/share_subject.dart';

import '../../helpers/pump_app.dart';

void main() {
  const prefs = {LocaleController.localeKey: 'en'};
  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');

  group('ShareSubject', () {
    test('track uses the artists and the album cover', () {
      const track = Track(
        id: 't1',
        title: 'Firuze',
        artists: [NamedRef(id: 'a1', name: 'Sezen Aksu')],
        artwork: Artwork(itemId: 'al1'),
      );
      final subject = ShareSubject.track(track);
      expect(subject.kind, ShareKind.track);
      expect(subject.line, 'Firuze — Sezen Aksu');
      expect(subject.artwork?.itemId, 'al1');
      expect(subject.circular, isFalse);
    });

    test('artist is circular and has no subtitle', () {
      final subject = ShareSubject.artist(
        const Artist(id: 'a1', name: 'Sezen Aksu'),
      );
      expect(subject.circular, isTrue);
      expect(subject.line, 'Sezen Aksu');
    });

    test('playlist falls back to the first track cover', () {
      final subject = ShareSubject.playlist(
        'Road trip',
        tracks: const [
          Track(id: '1', title: 'A'),
          Track(
            id: '2',
            title: 'B',
            artwork: Artwork(itemId: 'c2'),
          ),
        ],
      );
      expect(subject.artwork?.itemId, 'c2');
    });
  });

  group('ShareScreen', () {
    late List<MethodCall> shared;
    late Directory temp;

    setUp(() {
      shared = [];
      temp = Directory.systemTemp.createTempSync('melody_share');
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

    Future<void> open(WidgetTester tester, ShareSubject subject) async {
      await pumpApp(tester, preferences: prefs);
      final context = tester.element(find.byType(Scaffold).first);
      showShareScreen(context, subject).ignore();
      await tester.pumpAndSettle();
    }

    const album = ShareSubject(
      kind: ShareKind.album,
      title: 'Gülümse',
      subtitle: 'Sezen Aksu',
    );

    testWidgets('shows a story card with the item and the styles', (
      tester,
    ) async {
      await open(tester, album);
      expect(find.byType(ShareCard), findsOneWidget);
      expect(find.text('Gülümse'), findsOneWidget);
      expect(find.text('Sezen Aksu'), findsOneWidget);
      expect(find.text('ALBUM'), findsOneWidget);
      await tester.tap(find.text('Color'));
      await tester.pumpAndSettle();
      final card = tester.widget<ShareCard>(find.byType(ShareCard));
      expect(card.background, ShareBackground.color);
    });

    testWidgets('shares plain text without any server address', (tester) async {
      await open(tester, album);
      await tester.tap(find.text('Share as text'));
      await tester.pumpAndSettle();
      expect(shared, hasLength(1));
      final args = shared.single.arguments as Map;
      expect(args['text'], 'Gülümse — Sezen Aksu\nShared from Melody');
    });

    testWidgets('exports a 1080x1920 PNG and shares it', (tester) async {
      await open(tester, album);
      await tester.runAsync(() async {
        await tester.tap(find.text('Share image'));
        // Rendering and writing the file happen outside the fake clock.
        for (var i = 0; i < 50 && shared.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }
      });
      expect(shared, hasLength(1));
      final args = shared.single.arguments as Map;
      final paths = (args['paths'] as List).cast<String>();
      expect(paths.single, endsWith('.png'));
      final bytes = File(paths.single).readAsBytesSync();
      // PNG header: width and height are big-endian at offsets 16 and 20.
      final data = ByteData.sublistView(bytes);
      expect(data.getUint32(16), 1080);
      expect(data.getUint32(20), 1920);
    });

    testWidgets('the track menu offers sharing', (tester) async {
      await pumpApp(tester, preferences: prefs);
      await tester.tap(find.text('Library').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Songs'));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Firuze'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Share'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(find.byType(ShareScreen), findsOneWidget);
      expect(find.text('SONG'), findsOneWidget);
    });
  });
}
