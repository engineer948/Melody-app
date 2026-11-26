import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/config/feature_flags.dart';

void main() {
  group('FeatureFlags', () {
    test('Jellyfin and Subsonic are enabled by default', () {
      expect(FeatureFlags.enabledSources, {
        SourceType.jellyfin,
        SourceType.subsonic,
      });
      expect(FeatureFlags.isEnabled(SourceType.jellyfin), isTrue);
      expect(FeatureFlags.isEnabled(SourceType.subsonic), isTrue);
      expect(FeatureFlags.isEnabled(SourceType.local), isFalse);
      expect(FeatureFlags.hasMultipleSources, isTrue);
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
      expect(FeatureFlags.parseSources('vinyl'), FeatureFlags.defaultSources);
    });
  });
}
