// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ripple/app.dart';

void main() {
  testWidgets('Splash screen load test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: RippleApp(),
      ),
    );

    // Let GoRouter initialize and route to Splash screen, then advance time to complete the splash screen timer
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 3));

    // Verify that the splash screen shows the title 'Ripple'.
    expect(find.text('Ripple'), findsOneWidget);
  });
}
