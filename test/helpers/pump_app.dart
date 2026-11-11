import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/app.dart';
import 'package:melody/core/device/client_identity.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/core/theme/system_colors.dart';
import 'package:melody/data/db/app_database.dart';
import 'package:melody/data/repositories/token_store.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/features/auth/auth_providers.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/features/downloads/download_controller.dart';
import 'package:melody/features/settings/app_info.dart';
import 'package:melody/player/player_controller.dart';
import 'package:melody/player/streaming_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_engine.dart';
import 'fakes.dart';

/// Creates a container backed by in-memory storage and fake servers.
///
/// With [signedIn] the test account is active and [source] is its library.
Future<ProviderContainer> createContainer({
  Map<String, Object> preferences = const {},
  Color? systemSeed,
  bool signedIn = true,
  MusicSource? source,
  FakeConnector? connector,
  TokenStore? tokens,
  FakeAudioEngine? engine,
  FakeDownloadTransport? downloadTransport,
  bool mobileData = false,
  Override? engineOverride,
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues(preferences);
  final prefs = await SharedPreferences.getInstance();
  final database = AppDatabase(NativeDatabase.memory());
  final fakeSource = source ?? FakeMusicSource();
  Directory? downloadFolder;
  final container = ProviderContainer(
    overrides: [
      preferencesProvider.overrideWithValue(prefs),
      systemSeedColorProvider.overrideWith((ref) async => systemSeed),
      appVersionProvider.overrideWith((ref) async => '9.9.9 (99)'),
      clientIdentityProvider.overrideWithValue(testIdentity),
      appDatabaseProvider.overrideWithValue(database),
      tokenStoreProvider.overrideWithValue(tokens ?? MemoryTokenStore()),
      serverConnectorProvider.overrideWithValue(connector ?? FakeConnector()),
      sessionBootstrapProvider.overrideWithValue([
        if (signedIn) (account: testAccount, token: 'token-1'),
      ]),
      engineOverride ??
          audioEngineProvider.overrideWithValue(engine ?? FakeAudioEngine()),
      downloadDirectoryProvider.overrideWithValue(
        () async => downloadFolder ??= Directory.systemTemp.createTempSync(
          'melody_downloads',
        ),
      ),
      downloadTransportProvider.overrideWithValue(
        downloadTransport ?? FakeDownloadTransport(),
      ),
      onMobileDataProvider.overrideWith((ref) => Stream.value(mobileData)),
      ...overrides,
      activeSourceProvider.overrideWith(
        (ref) => ref.watch(sessionControllerProvider).activeToken == null
            ? null
            : fakeSource,
      ),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await database.close();
    final folder = downloadFolder;
    if (folder != null && folder.existsSync()) {
      folder.deleteSync(recursive: true);
    }
  });
  return container;
}

/// Pumps the whole app at the given logical [size].
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  Map<String, Object> preferences = const {},
  Color? systemSeed,
  Size size = const Size(400, 800),
  bool signedIn = true,
  MusicSource? source,
  FakeConnector? connector,
  FakeAudioEngine? engine,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = await createContainer(
    preferences: preferences,
    systemSeed: systemSeed,
    signedIn: signedIn,
    source: source,
    connector: connector,
    engine: engine,
    overrides: overrides,
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MelodyApp()),
  );
  await tester.pumpAndSettle();
  return container;
}
