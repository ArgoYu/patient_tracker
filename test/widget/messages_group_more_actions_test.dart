import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_tracker/app_modules.dart';

void main() {
  testWidgets('messages quick actions opens add friend sheet', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MessagesPage()));

    await tester.tap(find.byTooltip('Quick actions'));
    await tester.pumpAndSettle();

    expect(find.text('Quick actions'), findsOneWidget);

    await tester.tap(find.text('Add friend'));
    await tester.pumpAndSettle();

    expect(find.text('Add a friend'), findsOneWidget);
  });

  testWidgets('add friend sheet cancel closes the sheet', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MessagesPage()));

    await tester.tap(find.byTooltip('Quick actions'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add friend'));
    await tester.pumpAndSettle();

    expect(find.text('Add a friend'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Add a friend'), findsNothing);
  });

  testWidgets('create group sheet cancel closes the sheet', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MessagesPage()));

    await tester.tap(find.byTooltip('Quick actions'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create group chat'));
    await tester.pumpAndSettle();

    expect(find.text('Create a group chat'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Create a group chat'), findsNothing);
  });
}
