import 'dart:io';
import 'dart:math';

import 'package:melody/core/config/app_config.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'client_identity.g.dart';

/// How this installation introduces itself to servers.
@immutable
class ClientIdentity {
  /// Creates a [ClientIdentity].
  const ClientIdentity({
    required this.deviceId,
    required this.deviceName,
    this.clientName = AppConfig.clientName,
    this.version = '0.0.0',
  });

  /// Loads the identity, creating the device id on first use.
  factory ClientIdentity.load(SharedPreferences prefs, {String? version}) {
    var id = prefs.getString(deviceIdKey);
    if (id == null || id.isEmpty) {
      id = generateDeviceId();
      prefs.setString(deviceIdKey, id).ignore();
    }
    return ClientIdentity(
      deviceId: id,
      deviceName: _platformName(),
      version: version ?? '0.0.0',
    );
  }

  /// Preference key of the persisted device id.
  static const deviceIdKey = 'app.deviceId';

  /// Random id identifying this installation.
  final String deviceId;

  /// Human readable device name.
  final String deviceName;

  /// Client name reported to servers.
  final String clientName;

  /// Application version.
  final String version;

  /// Creates a random 128-bit hexadecimal id.
  static String generateDeviceId([Random? random]) {
    final rng = random ?? Random.secure();
    return List.generate(
      16,
      (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  static String _platformName() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return Platform.operatingSystem;
  }
}

/// Identity of this installation; overridden at startup with the real version.
@Riverpod(keepAlive: true)
ClientIdentity clientIdentity(Ref ref) =>
    ClientIdentity.load(ref.watch(preferencesProvider));
