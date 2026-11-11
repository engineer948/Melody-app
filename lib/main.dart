import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/app.dart';
import 'package:melody/core/device/client_identity.dart';
import 'package:melody/core/logging/app_logger.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/core/theme/font_licenses.dart';
import 'package:melody/core/widgets/app_error_view.dart';
import 'package:melody/data/db/app_database.dart';
import 'package:melody/data/repositories/account_store.dart';
import 'package:melody/data/repositories/token_store.dart';
import 'package:melody/features/auth/session_controller.dart';
import 'package:melody/player/media_session.dart';
import 'package:melody/player/player_controller.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _log = AppLogger('app');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installErrorHandling();
  registerFontLicenses();
  final preferences = await SharedPreferences.getInstance();
  final database = AppDatabase();
  final accounts = await _loadAccounts(database);
  final version = await _loadVersion();
  final container = ProviderContainer(
    overrides: [
      preferencesProvider.overrideWithValue(preferences),
      appDatabaseProvider.overrideWithValue(database),
      sessionBootstrapProvider.overrideWithValue(accounts),
      clientIdentityProvider.overrideWithValue(
        ClientIdentity.load(preferences, version: version),
      ),
    ],
  );
  // Restores the saved queue, then connects notification and lock screen.
  unawaited(
    MelodyAudioHandler.start(container..read(playerControllerProvider)),
  );
  runApp(
    UncontrolledProviderScope(container: container, child: const MelodyApp()),
  );
}

/// Reads the saved accounts; a broken store must not block startup.
Future<List<StoredAccount>> _loadAccounts(AppDatabase database) async {
  try {
    return await AccountStore(database, const SecureTokenStore()).loadAll();
  } on Object catch (error, stack) {
    _log.error('Could not load accounts', error, stack);
    return const [];
  }
}

Future<String?> _loadVersion() async {
  try {
    return (await PackageInfo.fromPlatform()).version;
  } on Object {
    return null;
  }
}

/// Logs uncaught errors and keeps the red error box out of release builds.
void _installErrorHandling() {
  if (kReleaseMode) {
    debugPrint = (message, {wrapWidth}) {};
    ErrorWidget.builder = (details) => const AppErrorView();
  }
  final presentError = FlutterError.onError;
  FlutterError.onError = (details) {
    _log.error('Flutter error', details.exception, details.stack);
    if (!kReleaseMode) presentError?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    _log.error('Uncaught error', error, stack);
    return true;
  };
}
