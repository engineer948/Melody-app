import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/domain/share/mixtape.dart';
import 'package:melody/features/share/letter_extras.dart';

import '../../helpers/pump_app.dart';

Future<Uint8List> _photo() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  for (var i = 0; i < 20; i++) {
    canvas.drawRect(
      Rect.fromLTWH(i * 10.0, 0, 10, 120),
      Paint()..color = Color.fromARGB(255, i * 12, 255 - i * 10, 90),
    );
  }
  final image = await recorder.endRecording().toImage(200, 120);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return png!.buffer.asUint8List();
}

void main() {
  const prefs = {LocaleController.localeKey: 'en'};

  test('links carry the letter code', () {
    final code = const Mixtape(
      title: 'Bir',
      songs: [MixtapeSong(id: 't1', title: 'Firuze')],
    ).encode();
    expect(letterCodeOf(letterLink(code)), code);
    expect(letterCodeOf('melody://letter?c=broken'), isNull);
    expect(letterCodeOf('see: $code'), 'see: $code');
  });

  testWidgets('a letter hidden in a photo is read back', (tester) async {
    final code = const Mixtape(
      title: 'Gizli',
      songs: [MixtapeSong(id: 't1', title: 'Firuze')],
    ).encode();
    final found = await tester.runAsync(() async {
      final png = await hideLetterInPhoto(await _photo(), code);
      expect(png, isNotNull);
      return await revealLetterInPhoto(png!);
    });
    expect(found, code);
    final plain = await tester.runAsync(
      () async => await revealLetterInPhoto(await _photo()),
    );
    expect(plain, isNull);
  });

  testWidgets('a time capsule stays shut; letters are kept', (tester) async {
    final c = await pumpApp(
      tester,
      preferences: prefs,
      size: const Size(400, 1400),
    );
    final now = DateTime.now();
    final capsule = Mixtape(
      title: 'Gələcəyə',
      from: 'Leyla',
      songs: const [MixtapeSong(id: 't1', title: 'Firuze')],
      openOn: DateTime(now.year + 1),
      hops: const ['Ali'],
    );
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open a song letter'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), capsule.encode());
    await tester.tap(find.text('Open').last);
    await tester.pumpAndSettle();
    expect(find.text('Leyla sent you a song letter'), findsOneWidget);
    expect(find.textContaining('Opens on'), findsOneWidget);
    expect(find.text('Open'), findsNothing, reason: 'sealed');
    expect(c.read(letterInboxProvider).single.code, capsule.encode());
    expect(c.read(dueLettersProvider), isEmpty);

    // A letter whose day has come shows on Home.
    final due = Mixtape(
      title: 'Bu gün',
      songs: const [MixtapeSong(id: 't1', title: 'Firuze')],
      openOn: DateTime(now.year - 1),
    );
    await c.read(letterInboxProvider.notifier).keep(due.encode(), own: true);
    expect(c.read(dueLettersProvider).single.code, due.encode());
    await c.read(letterInboxProvider.notifier).opened(due.encode());
    expect(c.read(dueLettersProvider), isEmpty);
  });

  testWidgets('a relay letter shows who passed it on', (tester) async {
    await pumpApp(tester, preferences: prefs, size: const Size(400, 1400));
    const letter = Mixtape(
      title: 'Zəncir',
      from: 'Leyla',
      songs: [MixtapeSong(id: 't2', title: 'Hadi')],
      hops: ['Ali'],
    );
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open a song letter'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), letter.encode());
    await tester.tap(find.text('Open').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Ali → Leyla → you'), findsOneWidget);
    expect(find.text('Add a song and pass it on'), findsOneWidget);
  });
}
