import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/features/lyrics/lyrics_view.dart';
import 'package:melody/features/player/now_playing_screen.dart';
import 'package:melody/features/player/player_look.dart';
import 'package:melody/features/share/mixtape_screens.dart';
import 'package:melody/player/playback_settings.dart';
import 'package:melody/player/player_controller.dart';

import '../../helpers/fake_engine.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  const prefs = {
    LocaleController.localeKey: 'en',
    PlaybackSettingsController.key: '{"fadeMs":0}',
  };

  test('a line is sung from its start to the next line', () {
    const s = Duration(seconds: 10);
    expect(lineProgress(const Duration(seconds: 9), s, null), 0);
    expect(
      lineProgress(const Duration(seconds: 12), s, const Duration(seconds: 14)),
      0.5,
    );
    expect(lineProgress(const Duration(seconds: 12), s, null), 0.5);
    expect(lineProgress(const Duration(minutes: 1), s, null), 1);
  });

  test('a whole album gets one cassette colour', () {
    expect(
      cassetteColor(makeTrack('t1')),
      cassetteColor(makeTrack('t9')),
      reason: 'same album a1',
    );
  });

  testWidgets('moving lyrics light words up one by one', (tester) async {
    Widget line(double progress) => MaterialApp(
      home: MovingLine(text: 'bir iki üç', progress: progress),
    );
    await tester.pumpWidget(line(0.1));
    await tester.pumpAndSettle();
    double opacity(String word) => tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.text(word),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;
    expect(opacity('bir'), 1);
    expect(opacity('üç'), lessThan(1));
    await tester.pumpWidget(line(1));
    await tester.pumpAndSettle();
    expect(opacity('üç'), 1);
  });

  testWidgets('hold the cover for a cassette; slowed changes the pitch', (
    tester,
  ) async {
    final engine = FakeAudioEngine();
    final container = await pumpApp(
      tester,
      preferences: prefs,
      engine: engine,
      size: const Size(400, 1400),
    );
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Songs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Firuze'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Firuze').last);
    await tester.pumpAndSettle();
    expect(find.byType(NowPlayingScreen), findsOneWidget);

    await tester.longPress(find.byType(Hero).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(Cassette), findsOneWidget);
    expect(
      container.read(playerLookControllerProvider).face,
      PlayerFace.cassette,
    );

    Future<void> settle() async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tester.tap(find.text('1.0×'));
    await settle();
    await tester.tap(find.text('Slowed'));
    await settle();
    expect(engine.speed, 0.85);
    expect(engine.pitch, 0.85);
    expect(find.text('🌙 Slowed'), findsOneWidget);

    await container.read(playerControllerProvider.notifier).setSpeed(1.5);
    expect(engine.pitch, 1);
    await container.read(playerControllerProvider.notifier).clear();
    await tester.pump(const Duration(seconds: 1));
  });
}
