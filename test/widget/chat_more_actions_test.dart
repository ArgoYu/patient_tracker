import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_tracker/direct_chat_page.dart';

void main() {
  testWidgets('direct chat settings opens without crashing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DirectChatPage(contact: personalChatMaya),
      ),
    );

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Search chat'), findsOneWidget);

    await tester.tap(find.text('Search chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  });
}
