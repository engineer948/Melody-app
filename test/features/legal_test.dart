import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/settings/preferences.dart';
import 'package:melody/features/settings/legal_screen.dart';
import 'package:melody/l10n/l10n.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('sharing terms: asked once, kept with the date; readable', (
    tester,
  ) async {
    final c = await createContainer();
    late WidgetRef ref;
    late BuildContext context;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (ctx, r, _) {
              ref = r;
              context = ctx;
              return const Scaffold();
            },
          ),
        ),
      ),
    );
    var answer = confirmShareTerms(context, ref);
    await tester.pumpAndSettle();
    expect(find.text('You are responsible for what you share'), findsOneWidget);

    await tester.tap(find.text('Read the terms'));
    await tester.pumpAndSettle();
    expect(find.text('Sharing clips, videos and song letters'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('No warranty'), 200);
    expect(find.text('No warranty'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('I understand'));
    await tester.pumpAndSettle();
    expect(await answer, isTrue);
    final prefs = c.read(preferencesProvider);
    expect(prefs.getInt(termsAcceptedKey), legalTermsVersion);
    expect(DateTime.tryParse(prefs.getString(termsAcceptedAtKey)!), isNotNull);

    // Not asked again.
    answer = confirmShareTerms(context, ref);
    await tester.pumpAndSettle();
    expect(find.text('I understand'), findsNothing);
    expect(await answer, isTrue);
  });
}
