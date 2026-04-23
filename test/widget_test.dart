import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pingu_throw_mobile/main.dart';

void main() {
  testWidgets('game HUD and prompt are visible', (WidgetTester tester) async {
    await tester.pumpWidget(const ArcticSluggerApp());

    expect(find.textContaining('DIST'), findsOneWidget);
    expect(find.textContaining('BEST'), findsOneWidget);
    expect(
      find.text('Tap to drop the penguin. Tap again in the hit zone.'),
      findsOneWidget,
    );
    expect(find.text('Reset'), findsOneWidget);
  });

  testWidgets('first tap changes gameplay prompt', (WidgetTester tester) async {
    await tester.pumpWidget(const ArcticSluggerApp());
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();

    expect(
      find.text('Tap now for the swing. Perfect timing gives better launch.'),
      findsOneWidget,
    );
  });
}
