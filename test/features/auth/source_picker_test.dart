import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/config/feature_flags.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/features/auth/auth_providers.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('only Jellyfin: no picker', (tester) async {
    await pumpApp(
      tester,
      signedIn: false,
      preferences: {LocaleController.localeKey: 'en'},
    );
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('hidden sources appear when enabled at build time', (
    tester,
  ) async {
    final c = await pumpApp(
      tester,
      signedIn: false,
      preferences: {LocaleController.localeKey: 'en'},
      overrides: [
        enabledSourcesProvider.overrideWithValue({
          SourceType.jellyfin,
          SourceType.subsonic,
          SourceType.radio,
        }),
      ],
    );
    expect(find.byType(ChoiceChip), findsNWidgets(3));
    expect(find.text('Subsonic / Navidrome'), findsOneWidget);

    await tester.tap(find.text('Internet radio'));
    await tester.pumpAndSettle();
    expect(c.read(selectedSourceTypeProvider), SourceType.radio);
    // No address for the radio directory: a single button adds it.
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Add'), findsOneWidget);

    await tester.tap(find.text('Subsonic / Navidrome'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('Navidrome, Airsonic'), findsOneWidget);
  });
}
