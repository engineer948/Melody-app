import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/data/downloads/download_models.dart';
import 'package:melody/data/downloads/download_settings.dart';
import 'package:melody/features/downloads/download_controller.dart';
import 'package:melody/player/playback_settings.dart';
import 'package:melody/player/player_controller.dart';
import 'package:melody/player/streaming_settings.dart';

import '../../helpers/fake_engine.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  late FakeDownloadTransport transport;
  late FakeMusicSource source;
  late FakeAudioEngine engine;
  var mobile = false;

  Future<ProviderContainer> setUpDownloads({
    Map<String, Object> preferences = const {},
  }) async {
    transport = FakeDownloadTransport();
    source = FakeMusicSource();
    engine = FakeAudioEngine();
    final container = await createContainer(
      source: source,
      engine: engine,
      preferences: {
        PlaybackSettingsController.key: '{"fadeMs":0}',
        ...preferences,
      },
      downloadTransport: transport,
      mobileData: mobile,
    );
    container.listen(downloadControllerProvider, (_, _) {});
    await container.read(downloadControllerProvider.notifier).ready;
    await container.read(onMobileDataProvider.future);
    return container;
  }

  DownloadController controller(ProviderContainer c) =>
      c.read(downloadControllerProvider.notifier);

  Map<String, DownloadItem> items(ProviderContainer c) =>
      c.read(downloadControllerProvider);

  /// Waits until nothing is queued or running (files are written for real).
  Future<void> settle(ProviderContainer c) async {
    for (var i = 0; i < 500; i++) {
      await pumpEventQueue();
      final busy = items(c).values.any(
        (d) =>
            d.status == DownloadStatus.queued ||
            d.status == DownloadStatus.running,
      );
      if (!busy) return;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    fail('downloads did not finish');
  }

  setUp(() => mobile = false);
  tearDown(pumpEventQueue);

  test('downloads a track to disk and remembers it', () async {
    final c = await setUpDownloads();
    await controller(c).enqueue([makeTrack('t1')]);
    await settle(c);

    final item = items(c)['t1']!;
    expect(item.status, DownloadStatus.done);
    expect(item.bytes, 1000);
    final path = controller(c).localPath('t1');
    expect(path, isNotNull);
    expect(File(path!).lengthSync(), 1000);
    expect(transport.requests.first.path, '/download/t1');

    final saved = await c.read(downloadStoreProvider).load(testAccount.id);
    expect(saved.single.status, DownloadStatus.done);
  });

  test('runs at most the configured number at a time', () async {
    final c = await setUpDownloads();
    transport.gate = Completer();
    await controller(c).enqueue([for (var i = 0; i < 5; i++) makeTrack('t$i')]);
    await pumpEventQueue();

    int count(DownloadStatus s) =>
        items(c).values.where((d) => d.status == s).length;
    expect(count(DownloadStatus.running), 2);
    expect(count(DownloadStatus.queued), 3);

    transport.gate!.complete();
    transport.gate = null;
    await settle(c);
    expect(count(DownloadStatus.done), 5);
  });

  test('pause keeps the partial file, resume finishes it', () async {
    final c = await setUpDownloads();
    transport.gate = Completer();
    await controller(c).enqueue([makeTrack('t1')]);
    await pumpEventQueue();
    controller(c).pause('t1');
    await pumpEventQueue();
    expect(items(c)['t1']!.status, DownloadStatus.paused);
    expect(controller(c).localPath('t1'), isNull);

    transport.gate = null;
    await controller(c).resume('t1');
    await settle(c);
    expect(items(c)['t1']!.status, DownloadStatus.done);
  });

  test('a failed download can be retried', () async {
    final c = await setUpDownloads();
    final uri = '${source.downloadUri(makeTrack('t1'))}';
    transport.failing.add(uri);
    await controller(c).enqueue([makeTrack('t1')]);
    await settle(c);
    expect(items(c)['t1']!.status, DownloadStatus.failed);

    transport.failing.clear();
    await controller(c).resumeAll();
    await settle(c);
    expect(items(c)['t1']!.status, DownloadStatus.done);
  });

  test('waits for Wi-Fi when asked to', () async {
    mobile = true;
    final c = await setUpDownloads();
    await controller(c).enqueue([makeTrack('t1')]);
    await pumpEventQueue();
    expect(items(c)['t1']!.status, DownloadStatus.queued);
    expect(transport.requests, isEmpty);

    await c
        .read(downloadSettingsControllerProvider.notifier)
        .update((s) => s.copyWith(wifiOnly: false));
    await settle(c);
    expect(items(c)['t1']!.status, DownloadStatus.done);
  });

  test('remove deletes the file and the entry', () async {
    final c = await setUpDownloads();
    await controller(c).enqueue([makeTrack('t1'), makeTrack('t2')]);
    await settle(c);
    final path = controller(c).localPath('t1')!;

    await controller(c).remove(['t1']);
    expect(File(path).existsSync(), isFalse);
    expect(items(c).keys, ['t2']);
    expect(
      await c.read(downloadStoreProvider).load(testAccount.id),
      hasLength(1),
    );
  });

  test('a synced playlist follows additions and removals', () async {
    final c = await setUpDownloads();
    source.playlistEntries['p1'] = [
      ('e1', makeTrack('t1')),
      ('e2', makeTrack('t2')),
    ];
    final key = DownloadSettings.playlistKey(testAccount.id, 'p1');
    await c
        .read(downloadSettingsControllerProvider.notifier)
        .update((s) => s.copyWith(syncedPlaylists: {key}));
    await settle(c);
    expect(items(c).keys, unorderedEquals(['t1', 't2']));

    // t1 is also kept on its own; t2 leaves the playlist, t3 joins it.
    await controller(c).enqueue([makeTrack('t1')]);
    source.playlistEntries['p1'] = [
      ('e1', makeTrack('t1')),
      ('e3', makeTrack('t3')),
    ];
    await controller(c).sync();
    await settle(c);
    expect(items(c).keys, unorderedEquals(['t1', 't3']));

    // No longer synced: only what is kept for another reason stays.
    await c
        .read(downloadSettingsControllerProvider.notifier)
        .update((s) => s.copyWith(syncedPlaylists: {}));
    await settle(c);
    expect(items(c).keys, ['t1']);
  });

  test('the player uses the downloaded file', () async {
    final c = await setUpDownloads();
    await controller(c).enqueue([makeTrack('t1')]);
    await settle(c);

    await c.read(playerControllerProvider.notifier).playTracks([
      makeTrack('t1'),
      makeTrack('t2'),
    ]);
    expect(engine.sources.first.uri.scheme, 'file');
    expect(
      engine.sources.first.uri.toFilePath(),
      controller(c).localPath('t1'),
    );
    expect(engine.sources.last.uri.scheme, 'https');
  });

  test('unfinished downloads continue after a restart', () async {
    final c = await setUpDownloads();
    transport.gate = Completer();
    await controller(c).enqueue([makeTrack('t1')]);
    await pumpEventQueue();
    expect(items(c)['t1']!.status, DownloadStatus.running);

    // "Restart": the controller is rebuilt and reads the store again.
    transport.gate = null;
    c.invalidate(downloadControllerProvider);
    await controller(c).ready;
    await settle(c);
    expect(items(c)['t1']!.status, DownloadStatus.done);
  });
}
