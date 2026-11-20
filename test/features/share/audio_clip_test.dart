import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/domain/models/media.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/features/share/audio_clip.dart';
import 'package:melody/features/share/share_screen.dart';
import 'package:melody/features/share/share_subject.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

class FakeClipMaker implements ClipMaker {
  FakeClipMaker(this.dir);

  final Directory dir;
  final calls = <(Duration, Duration)>[];

  @override
  Future<File> make(
    MusicSource source,
    Track track,
    Duration start,
    Duration length,
  ) async {
    calls.add((start, length));
    final file = File('${dir.path}/${clipFileName(track)}')
      ..writeAsBytesSync([0xFF, 0xFB, 0x90, 0x00]);
    return file;
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
  final calls = <(String, String, String)>[];

  @override
  bool get supported => true;

  @override
  Future<File> make({
    required File image,
    required File audio,
    required String name,
  }) async {
    calls.add((image.path, audio.path, name));
    return File('${dir.path}/$name.mp4')..writeAsBytesSync([0]);
  }
}

void main() {
  const prefs = {LocaleController.localeKey: 'en'};
  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  late List<MethodCall> shared;
  late Directory temp;
  late FakeClipMaker maker;
  late FakeClipPreview preview;
  late FakeVideoMaker video;

  setUp(() {
    shared = [];
    temp = Directory.systemTemp.createTempSync('melody_clip');
    maker = FakeClipMaker(temp);
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

  Future<void> open(WidgetTester tester) async {
    await pumpApp(
      tester,
      preferences: prefs,
      overrides: [
        clipMakerProvider.overrideWithValue(maker),
        clipPreviewProvider.overrideWithValue(preview),
        storyVideoMakerProvider.overrideWithValue(video),
      ],
    );
    final context = tester.element(find.byType(Scaffold).first);
    // 3:05 long.
    showShareScreen(
      context,
      ShareSubject.track(makeTrack('t1', title: 'Firuze')),
    ).ignore();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sound clip'));
    await tester.pumpAndSettle();
  }

  testWidgets('picks a part, plays it and shares it as MP3', (tester) async {
    await open(tester);
    // Starts about a third in, 30 seconds long.
    expect(find.text('0:55 – 1:25'), findsOneWidget);

    await tester.tap(find.byTooltip('5 seconds later'));
    await tester.tap(find.text('15 s'));
    await tester.pumpAndSettle();
    expect(find.text('1:00 – 1:15'), findsOneWidget);

    await tester.tap(find.text('Listen'));
    await tester.pumpAndSettle();
    expect(maker.calls.single, (
      const Duration(seconds: 60),
      const Duration(seconds: 15),
    ));
    expect(preview.played.single, endsWith('Sezen - Firuze.mp3'));
    expect(find.text('Stop'), findsOneWidget);

    // The same piece is not made twice. The first share asks once about
    // copyright.
    await tester.tap(find.text('Share clip'));
    await tester.pumpAndSettle();
    expect(find.text('You are responsible for what you share'), findsOneWidget);
    await tester.tap(find.text('I understand'));
    await tester.pumpAndSettle();
    expect(maker.calls, hasLength(1));
    expect(preview.playing.value, isFalse);
    final args = shared.single.arguments as Map;
    expect((args['paths'] as List).single, endsWith('.mp3'));
    expect((args['mimeTypes'] as List).single, 'audio/mpeg');
  });

  testWidgets('the piece cannot go past the end of the song', (tester) async {
    await open(tester);
    for (var i = 0; i < 40; i++) {
      await tester.tap(find.byTooltip('5 seconds later'));
    }
    await tester.pumpAndSettle();
    expect(find.text('2:35 – 3:05'), findsOneWidget);
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
    expect(maker.calls, isEmpty);
    // Asked again next time.
    await tester.tap(find.text('Share clip'));
    await tester.pumpAndSettle();
    expect(find.text('I understand'), findsOneWidget);
  });

  testWidgets('a story video joins the card picture and the clip', (
    tester,
  ) async {
    await open(tester);
    await tester.runAsync(() async {
      await tester.tap(find.text('Story video (picture + song)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I understand'));
      // Rendering the card happens outside the fake clock.
      for (var i = 0; i < 50 && shared.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    final (image, audio, name) = video.calls.single;
    expect(image, endsWith('.png'));
    expect(audio, endsWith('Sezen - Firuze.mp3'));
    expect(name, 'Sezen - Firuze');
    final args = shared.single.arguments as Map;
    expect((args['paths'] as List).single, endsWith('Sezen - Firuze.mp4'));
    expect((args['mimeTypes'] as List).single, 'video/mp4');
  });
}
