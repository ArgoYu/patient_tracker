import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_tracker/app_modules.dart';

void main() {
  testWidgets('care team chat settings opens without crashing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CareTeamMessagesPage(),
                  ),
                ),
                child: const Text('Open care chat'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open care chat'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Search chat'), findsOneWidget);

    await tester.tap(find.text('Chat preferences'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  });
}
