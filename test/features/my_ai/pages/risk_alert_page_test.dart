import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_tracker/app_modules.dart';
import 'package:patient_tracker/features/my_ai/models/risk_models.dart';

void main() {
  RiskResult buildResult({
    int score = 72,
    RiskLevel level = RiskLevel.high,
    String category = 'Behavioral health',
  }) {
    final detail = RiskRuleDetail(
      category: category,
      rule: 'matched keywords',
      weight: 100,
      matched: true,
      evidence: const ['suicidal'],
    );
    return RiskResult(
      overallScore: score,
      maxScore: 100,
      summary: 'Detected $category concerns.',
      generatedAt: DateTime.now(),
      items: [
        RiskItem(
          category: category,
          level: level,
          triggers: const ['suicidal'],
          suggestion: 'Escalate care team outreach.',
        ),
      ],
      details: [detail],
    );
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    required Future<String?> Function() fetchNotes,
    required Future<RiskResult> Function(String notes) runScan,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RiskAlertPage(
          fetchNotes: fetchNotes,
          runScan: runScan,
          exportReport: (_) async {},
        ),
      ),
    );
  }

  testWidgets('loads and renders success state', (tester) async {
    final result = buildResult();
    await pumpPage(
      tester,
      fetchNotes: () async => 'Latest notes with suicidal mention.',
      runScan: (_) async => result,
    );

    expect(find.textContaining('Scanning latest consultation notes'),
        findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Risk findings'), findsOneWidget);
    expect(find.text('Behavioral health'), findsOneWidget);
    expect(find.textContaining('Escalate care team outreach'), findsOneWidget);
  });

  testWidgets('shows empty state when notes missing', (tester) async {
    await pumpPage(
      tester,
      fetchNotes: () async => null,
      runScan: (_) async => buildResult(),
    );

    await tester.pumpAndSettle();
    expect(find.text('No consultation notes found'), findsOneWidget);
  });

  testWidgets('shows error state on failure', (tester) async {
    await pumpPage(
      tester,
      fetchNotes: () async => throw Exception('offline'),
      runScan: (_) async => buildResult(),
    );

    await tester.pumpAndSettle();
    expect(find.text('Unable to complete scan'), findsOneWidget);
    expect(find.textContaining('offline'), findsOneWidget);
  });

  testWidgets('re-run scan refreshes data', (tester) async {
    final responses = <String?>[null, 'Now we have notes'];
    var runCount = 0;
    await pumpPage(
      tester,
      fetchNotes: () async => responses.removeAt(0),
      runScan: (_) async {
        runCount++;
        return buildResult(
            score: 55,
            level: RiskLevel.medium,
            category: 'Medication adherence');
      },
    );

    await tester.pumpAndSettle();
    expect(find.text('No consultation notes found'), findsOneWidget);

    await tester.tap(find.text('Re-run Scan'));
    await tester.pump(); // start loading
    await tester.pumpAndSettle();

    expect(runCount, 1);
    expect(find.text('Medication adherence'), findsOneWidget);
  });
}
