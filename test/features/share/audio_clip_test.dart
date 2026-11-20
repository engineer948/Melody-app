import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/features/lyrics/lyrics_providers.dart';
import 'package:melody/features/share/audio_clip.dart';
import 'package:melody/features/share/share_screen.dart';
import 'package:melody/features/share/share_subject.dart';

import '../../helpers/fake_mp3.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

class FakeSongLoader implements SongAudioLoader {
  int calls = 0;

  @override
  Future<Uint8List> load(MusicSource source, Track track) async {
    calls++;
    // 3:05, loud from 1:40 to 2:10.
    return fakeSongWithChorus();
  }
}

class FakeClipPreview implements ClipPreview {
  final played = <String>[];

  @override
  final ValueNotifier<bool> playing = ValueNotifier(false);

  @override
  Future<void> play(File file) async {
    played.add(file.path);
    playing.value = true;
  }

  @override
  Future<void> stop() async => playing.value = false;

  @override
  Future<void> dispose() async {}
}

class FakeVideoMaker implements StoryVideoMaker {
  FakeVideoMaker(this.dir);

  final Directory dir;
  final calls = <(List<(File, Duration)>, String, String)>[];
  final discs = <(File?, Rect?, List<double>)>[];

  @override
  bool get supported => true;

  @override
  Future<File> make({
    required List<(File, Duration)> pictures,
    required File audio,
    required String name,
    File? disc,
    Rect? discRect,
    List<double> pulse = const [],
  }) async {
    calls.add((pictures, audio.path, name));
    discs.add((disc, discRect, pulse));
    return File('${dir.path}/$name.mp4')..writeAsBytesSync([0]);
  }
}

void main() {
  const prefs = {LocaleController.localeKey: 'en'};
  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  final track = makeTrack('t1', title: 'Firuze');
  const lyrics = Lyrics(
    synced: true,
    lines: [
      LyricLine(text: 'Gül yüzlüm', start: Duration(seconds: 95)),
      LyricLine(text: 'Firuze', start: Duration(seconds: 105)),
      LyricLine(text: 'Ah firuze', start: Duration(seconds: 115)),
    ],
  );
  late List<MethodCall> shared;
  late Directory temp;
  late FakeSongLoader loader;
  late FakeClipPreview preview;
  late FakeVideoMaker video;

  setUp(() {
    shared = [];
    temp = Directory.systemTemp.createTempSync('melody_clip');
    loader = FakeSongLoader();
    preview = FakeClipPreview();
    video = FakeVideoMaker(temp);
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

  Future<void> open(WidgetTester tester, {Lyrics? songLyrics}) async {
    await pumpApp(
      tester,
      preferences: prefs,
      size: const Size(400, 1400),
      overrides: [
        songAudioLoaderProvider.overrideWithValue(loader),
        clipPreviewProvider.overrideWithValue(preview),
        storyVideoMakerProvider.overrideWithValue(video),
        trackLyricsProvider(track).overrideWith((ref) async => songLyrics),
      ],
    );
    final context = tester.element(find.byType(Scaffold).first);
    showShareScreen(context, ShareSubject.track(track)).ignore();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sound clip'));
    await tester.pumpAndSettle();
  }

  /// Taps [text] and waits for real file writing to finish.
  Future<void> tapAndWait(
    WidgetTester tester,
    String text,
    bool Function() done,
  ) => tester.runAsync(() async {
    await tester.tap(find.text(text));
    for (var i = 0; i < 80 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
      await tester.pump();
    }
  });

  testWidgets('starts on the loudest part, plays it and shares an MP3', (
    tester,
  ) async {
    await open(tester);
    expect(loader.calls, 1);
    expect(find.text('1:40 – 2:10 · 30 s'), findsOneWidget);

    await tester.tap(find.byTooltip('5 seconds later'));
    await tester.pumpAndSettle();
    expect(find.text('1:45 – 2:15 · 30 s'), findsOneWidget);
    await tester.tap(find.text('Best part'));
    await tester.pumpAndSettle();
    expect(find.text('1:40 – 2:10 · 30 s'), findsOneWidget);

    await tapAndWait(tester, 'Listen', () => preview.played.isNotEmpty);
    await tester.pumpAndSettle();
    final path = preview.played.single;
    expect(path, endsWith('Sezen - Firuze.mp3'));
    // Faded in: the first frame is quieter than the song there.
    final bytes = File(path).readAsBytesSync();
    final firstFrame = bytes.indexOf(0xFF, 10);
    expect(readBits(bytes, firstFrame * 8 + fakeGainBit(0), 8), lessThan(200));
    expect(find.text('Stop'), findsOneWidget);

    await tester.tap(find.text('Share clip'));
    await tester.pumpAndSettle();
    await tapAndWait(tester, 'I understand', () => shared.isNotEmpty);
    await tester.pumpAndSettle();
    expect(preview.playing.value, isFalse);
    final args = shared.single.arguments as Map;
    expect((args['paths'] as List).single, endsWith('.mp3'));
    expect((args['mimeTypes'] as List).single, 'audio/mpeg');
    expect(loader.calls, 1, reason: 'the song is downloaded once');
  });

  testWidgets('nothing is shared when copyright is not accepted', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Share clip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(shared, isEmpty);
    await tester.tap(find.text('Share clip'));
    await tester.pumpAndSettle();
    expect(find.text('I understand'), findsOneWidget);
  });

  testWidgets('the piece cannot go past the end of the song', (tester) async {
    await open(tester);
    for (var i = 0; i < 20; i++) {
      await tester.tap(find.byTooltip('5 seconds later'));
    }
    await tester.pumpAndSettle();
    // The fake song is a few milliseconds shorter than 3:05.
    expect(find.text('2:35 – 3:04 · 29 s'), findsOneWidget);
  });

  testWidgets('a story video without lyrics is one picture', (tester) async {
    await open(tester);
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Show the lyrics on the story'),
          )
          .onChanged,
      isNull,
      reason: 'no synced lyrics',
    );
    await tester.runAsync(() async {
      await tester.tap(find.text('Story video (picture + song)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I understand'));
      for (var i = 0; i < 50 && shared.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    final (pictures, audio, name) = video.calls.single;
    expect(pictures.single.$2, Duration.zero);
    expect(pictures.single.$1.path, endsWith('.png'));
    expect(audio, endsWith('Sezen - Firuze.mp3'));
    expect(name, 'Sezen - Firuze');
    final args = shared.single.arguments as Map;
    expect((args['mimeTypes'] as List).single, 'video/mp4');
  });

  testWidgets('lyrics are optional, can be retimed and change in the video', (
    tester,
  ) async {
    await open(tester, songLyrics: lyrics);
    expect(find.text('Firuze', skipOffstage: false), findsWidgets);
    expect(find.text('Gül yüzlüm'), findsNothing, reason: 'off by default');

    await tester.tap(find.text('Show the lyrics on the story'));
    await tester.pumpAndSettle();
    // The piece starts at 1:40, during the first line.
    expect(find.text('Gül yüzlüm'), findsOneWidget);
    expect(find.text('Timing: 0.00 s'), findsOneWidget);
    await tester.tap(find.byTooltip('Show later'));
    await tester.pumpAndSettle();
    expect(find.text('Timing: +0.25 s'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('Story video (picture + song)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I understand'));
      for (var i = 0; i < 80 && shared.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    final (pictures, _, _) = video.calls.single;
    expect(pictures.map((p) => p.$2), const [
      Duration.zero,
      Duration(milliseconds: 5250),
      Duration(milliseconds: 15250),
    ]);
    expect(pictures.map((p) => p.$1.path).toSet(), hasLength(3));
  });

  testWidgets('a turning record is drawn apart and swells with the music', (
    tester,
  ) async {
    await open(tester);
    expect(find.byType(VinylDisc), findsNothing, reason: 'off by default');
    await tester.tap(find.text('Turning record'));
    // The record keeps turning: pump instead of settling.
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(VinylDisc), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Story video (picture + song)'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('I understand'));
      for (var i = 0; i < 80 && shared.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    final (disc, rect, pulse) = video.discs.single;
    expect(disc!.path, endsWith('.png'));
    expect(rect!.left, inExclusiveRange(0, 1));
    expect(rect.width, inExclusiveRange(0.2, 0.9));
    // 30 s at 24 frames a second, louder in the chorus part.
    expect(pulse, hasLength(720));
    expect(pulse.every((p) => p >= 0 && p <= 1), isTrue);
    await tester.tap(find.text('Turning record'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(VinylDisc), findsNothing);
  });
}
