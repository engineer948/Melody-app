import 'package:melody/data/downloads/download_settings.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/player/streaming_settings.dart';

/// Ready-made sound quality choices on top of the detailed settings.
enum QualityPreset {
  /// Original files everywhere.
  best,

  /// Original on Wi-Fi, a little less on mobile data.
  balanced,

  /// Small streams and small downloads.
  saver,

  /// Anything else the user set by hand.
  custom,
}

/// Streaming settings of [preset], keeping the cache size of [current].
StreamingSettings streamingFor(
  QualityPreset preset,
  StreamingSettings current,
) => switch (preset) {
  QualityPreset.best ||
  QualityPreset.custom => StreamingSettings(cacheMb: current.cacheMb),
  QualityPreset.balanced => StreamingSettings(
    mobileBitrate: 256,
    cacheMb: current.cacheMb,
  ),
  QualityPreset.saver => StreamingSettings(
    wifiBitrate: 192,
    mobileBitrate: 128,
    format: StreamFormat.opus,
    dataSaver: true,
    cacheMb: current.cacheMb,
  ),
};

/// Download settings of [preset], keeping everything but quality.
DownloadSettings downloadsFor(QualityPreset preset, DownloadSettings current) =>
    switch (preset) {
      QualityPreset.best || QualityPreset.balanced || QualityPreset.custom =>
        current.copyWith(clearBitrate: true, format: StreamFormat.original),
      QualityPreset.saver => current.copyWith(
        bitrate: 128,
        format: StreamFormat.opus,
      ),
    };

/// The preset [streaming] and [downloads] match, or [QualityPreset.custom].
QualityPreset presetOf(
  StreamingSettings streaming,
  DownloadSettings downloads,
) {
  for (final p in [
    QualityPreset.best,
    QualityPreset.balanced,
    QualityPreset.saver,
  ]) {
    final d = downloadsFor(p, downloads);
    if (streamingFor(p, streaming) == streaming &&
        d.bitrate == downloads.bitrate &&
        d.format == downloads.format) {
      return p;
    }
  }
  return QualityPreset.custom;
}
