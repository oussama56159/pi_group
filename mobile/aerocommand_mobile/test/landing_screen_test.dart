import 'package:aerocommand_mobile/src/ui/screens/landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Landing screen shows logos and Get Started', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: LandingScreen(
          onGetStarted: () => tapped = true,
        ),
      ),
    );

    // Let the entry animation complete.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('AeroCommand'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    expect(tapped, isTrue);

    // Assets are referenced (we can't decode images in a pure widget test).
    expect(find.byType(Image), findsWidgets);
  });
}
