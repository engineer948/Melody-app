import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/features/settings/update_check.dart';

import '../../helpers/pump_app.dart';

void main() {
  test('compares versions', () {
    expect(isNewerVersion('0.13.0', '0.12.0'), isTrue);
    expect(isNewerVersion('0.12.1', '0.12.0'), isTrue);
    expect(isNewerVersion('1.0.0', '0.99.9'), isTrue);
    expect(isNewerVersion('0.12.0', '0.12.0'), isFalse);
    expect(isNewerVersion('0.11.9', '0.12.0'), isFalse);
    expect(isNewerVersion('0.12.0', '0.12.0+21'), isFalse);
  });

  Future<void> pump(WidgetTester tester, {required String latest}) async {
    await pumpApp(
      tester,
      preferences: {LocaleController.localeKey: 'en'},
      overrides: [
        installedVersionProvider.overrideWith((ref) async => '0.12.0'),
        latestReleaseFetcherProvider.overrideWithValue(
          () async => (latest, Uri.parse('https://example.com/r')),
        ),
      ],
    );
  }

  testWidgets('a newer release shows a banner on the home screen', (
    tester,
  ) async {
    await pump(tester, latest: '0.13.0');
    expect(find.text('Melody 0.13.0 is available'), findsOneWidget);
  });

  testWidgets('no banner when up to date', (tester) async {
    await pump(tester, latest: '0.12.0');
    expect(find.textContaining('is available'), findsNothing);
  });
}
