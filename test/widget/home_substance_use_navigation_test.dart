import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:patient_tracker/app.dart';
import 'package:patient_tracker/features/home/view/home_page.dart';

void main() {
  testWidgets('tapping Substance Use Disorder opens dedicated page',
      (tester) async {
    await tester.pumpWidget(const AppRoot());
    await tester.pump(const Duration(seconds: 1));

    // Sanity check: verify other panels navigate correctly.
    final goalsInkWellFinder = find.descendant(
      of: find.widgetWithText(GlassSmallPanel, 'My Goals'),
      matching: find.byType(InkWell),
    );
    final goalsInkWell = tester.widget<InkWell>(goalsInkWellFinder);
    goalsInkWell.onTap?.call();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    expect(find.byType(GoalsPage), findsOneWidget);
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 400));

    final sudLabelFinder = find.text('Substance Use Disorder');
    await tester.scrollUntilVisible(
      sudLabelFinder,
      300,
      scrollable: find.byType(Scrollable).first,
    );

    final sudInkWellFinder = find.descendant(
      of: find.ancestor(
        of: sudLabelFinder,
        matching: find.byType(GlassSmallPanel),
      ),
      matching: find.byType(InkWell),
    );

    final sudInkWell = tester.widget<InkWell>(sudInkWellFinder);
    sudInkWell.onTap?.call();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(SubstanceUseDisorderPage), findsOneWidget);
  });
}
