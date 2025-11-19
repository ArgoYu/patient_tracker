import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_tracker/app.dart';

void main() {
  testWidgets('Patient tracker displays navigation tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AppRoot());
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Chat'), findsWidgets);
    expect(find.text('More'), findsWidgets);
  });
}
