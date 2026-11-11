import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melody/core/widgets/app_error_view.dart';

void main() {
  testWidgets('renders without any app scaffolding around it', (tester) async {
    await tester.pumpWidget(const AppErrorView());
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('offers a retry action when given a callback', (tester) async {
    var retried = 0;
    await tester.pumpWidget(AppErrorView(onRetry: () => retried++));
    await tester.tap(find.text('Retry'));
    expect(retried, 1);
  });
}
