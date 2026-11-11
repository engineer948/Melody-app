import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'streaming_settings.g.dart';

/// Bitrate limits offered in the settings (kbps); `null` keeps the original.
const bitrateChoices = <int?>[null, 320, 256, 192, 128, 96];

/// Bitrate used on mobile data when the data saver is on.
const dataSaverBitrate = 128;

/// Stream quality and cache preferences.
@immutable
class StreamingSettings {
  /// Creates the settings.
  const StreamingSettings({
    this.wifiBitrate,
    this.mobileBitrate,
    this.format = StreamFormat.original,
    this.dataSaver = false,
    this.cacheMb = 512,
  });

  /// Restores settings saved with [toJson].
  factory StreamingSettings.fromJson(Map<String, dynamic> json) =>
      StreamingSettings(
        wifiBitrate: json['wifiBitrate'] as int?,
        mobileBitrate: json['mobileBitrate'] as int?,
        format:
            StreamFormat.values.asNameMap()[json['format']] ??
            StreamFormat.original,
        dataSaver: json['dataSaver'] as bool? ?? false,
        cacheMb: json['cacheMb'] as int? ?? 512,
      );

  /// Limit on Wi-Fi / Ethernet; `null` for the original quality.
  final int? wifiBitrate;

  /// Limit on mobile data; `null` for the original quality.
  final int? mobileBitrate;

  /// Wanted format.
  final StreamFormat format;

  /// Caps mobile data at [dataSaverBitrate].
  final bool dataSaver;

  /// Size limit of the stream cache; 0 disables it.
  final int cacheMb;

  /// Stream options for the current connection.
  StreamOptions optionsFor({required bool mobile}) {
    var limit = mobile ? mobileBitrate : wifiBitrate;
    if (mobile && dataSaver) {
      limit = limit == null || limit > dataSaverBitrate
          ? dataSaverBitrate
          : limit;
    }
    return StreamOptions(maxBitrateKbps: limit, format: format);
  }

  /// Returns a copy with the given fields replaced; use [clearWifi] or
  /// [clearMobile] to go back to the original quality.
  StreamingSettings copyWith({
    int? wifiBitrate,
    bool clearWifi = false,
    int? mobileBitrate,
    bool clearMobile = false,
    StreamFormat? format,
    bool? dataSaver,
    int? cacheMb,
  }) => StreamingSettings(
    wifiBitrate: clearWifi ? null : wifiBitrate ?? this.wifiBitrate,
    mobileBitrate: clearMobile ? null : mobileBitrate ?? this.mobileBitrate,
    format: format ?? this.format,
    dataSaver: dataSaver ?? this.dataSaver,
    cacheMb: cacheMb ?? this.cacheMb,
  );

  /// Serialises the settings.
  Map<String, dynamic> toJson() => {
    'wifiBitrate': wifiBitrate,
    'mobileBitrate': mobileBitrate,
    'format': format.name,
    'dataSaver': dataSaver,
    'cacheMb': cacheMb,
  };

  @override
  bool operator ==(Object other) =>
      other is StreamingSettings &&
      other.wifiBitrate == wifiBitrate &&
      other.mobileBitrate == mobileBitrate &&
      other.format == format &&
      other.dataSaver == dataSaver &&
      other.cacheMb == cacheMb;

  @override
  int get hashCode =>
      Object.hash(wifiBitrate, mobileBitrate, format, dataSaver, cacheMb);
}

/// Holds and persists [StreamingSettings].
@Riverpod(keepAlive: true)
class StreamingSettingsController extends _$StreamingSettingsController {
  /// Preference key.
  static const key = 'player.streaming';

  @override
  StreamingSettings build() {
    final raw = ref.watch(preferencesProvider).getString(key);
    if (raw == null) return const StreamingSettings();
    try {
      return StreamingSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on Object {
      return const StreamingSettings();
    }
  }

  /// Applies [change] and saves the result.
  Future<void> update(
    StreamingSettings Function(StreamingSettings current) change,
  ) async {
    state = change(state);
    await ref.read(preferencesProvider).setString(key, jsonEncode(state));
  }
}

/// Whether the device is on mobile data (and not on Wi-Fi or Ethernet).
@Riverpod(keepAlive: true)
Stream<bool> onMobileData(Ref ref) async* {
  bool mobile(List<ConnectivityResult> results) =>
      results.contains(ConnectivityResult.mobile) &&
      !results.contains(ConnectivityResult.wifi) &&
      !results.contains(ConnectivityResult.ethernet);
  final connectivity = Connectivity();
  try {
    yield mobile(await connectivity.checkConnectivity());
    yield* connectivity.onConnectivityChanged.map(mobile);
  } on Object {
    yield false; // Unknown: treat as Wi-Fi.
  }
}
