import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/features/home/welcome_card.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('welcome card: quality and shelves, closed for good', (
    tester,
  ) async {
    final c = await pumpApp(
      tester,
      preferences: {LocaleController.localeKey: 'en', welcomeDoneKey: false},
    );
    expect(find.text('Welcome to Melody'), findsOneWidget);
    expect(find.text('Balanced'), findsOneWidget);
    await tester.tap(find.text('Start listening'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Melody'), findsNothing);
    expect(c.read(preferencesProvider).getBool(welcomeDoneKey), isTrue);
  });
}
