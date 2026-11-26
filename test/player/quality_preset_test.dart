import 'package:flutter_test/flutter_test.dart';
import 'package:melody/data/downloads/download_settings.dart';
import 'package:melody/domain/repositories/music_source.dart';
import 'package:melody/player/quality_preset.dart';
import 'package:melody/player/streaming_settings.dart';

void main() {
  test('defaults are the best preset', () {
    expect(
      presetOf(const StreamingSettings(), const DownloadSettings()),
      QualityPreset.best,
    );
  });

  test('each preset is recognised after choosing it; cache size stays', () {
    const streaming = StreamingSettings(cacheMb: 2048, wifiBitrate: 96);
    const downloads = DownloadSettings(wifiOnly: false);
    for (final p in [
      QualityPreset.best,
      QualityPreset.balanced,
      QualityPreset.saver,
    ]) {
      final s = streamingFor(p, streaming);
      final d = downloadsFor(p, downloads);
      expect(presetOf(s, d), p);
      expect(s.cacheMb, 2048);
      expect(d.wifiOnly, isFalse);
    }
  });

  test('a changed detail makes it custom', () {
    final s = streamingFor(QualityPreset.saver, const StreamingSettings());
    final d = downloadsFor(QualityPreset.saver, const DownloadSettings());
    expect(
      presetOf(s.copyWith(format: StreamFormat.mp3), d),
      QualityPreset.custom,
    );
    expect(presetOf(s, d.copyWith(bitrate: 320)), QualityPreset.custom);
  });
}
