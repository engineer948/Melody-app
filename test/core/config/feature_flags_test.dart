import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/config/feature_flags.dart';

void main() {
  group('FeatureFlags', () {
    test('only Jellyfin is enabled by default', () {
      expect(FeatureFlags.enabledSources, {SourceType.jellyfin});
      expect(FeatureFlags.isEnabled(SourceType.jellyfin), isTrue);
      expect(FeatureFlags.isEnabled(SourceType.subsonic), isFalse);
      expect(FeatureFlags.hasMultipleSources, isFalse);
    });

    test('parses a comma separated list', () {
      expect(FeatureFlags.parseSources('jellyfin,subsonic,local'), {
        SourceType.jellyfin,
        SourceType.subsonic,
        SourceType.local,
      });
    });

    test('ignores case, whitespace and unknown names', () {
      expect(FeatureFlags.parseSources(' Radio , EMBY,tape,,'), {
        SourceType.radio,
        SourceType.emby,
      });
    });

    test('falls back to the default when nothing valid is given', () {
      expect(FeatureFlags.parseSources(''), FeatureFlags.defaultSources);
      expect(FeatureFlags.parseSources('vinyl'), {SourceType.jellyfin});
    });
  });
}
