import 'package:flutter_test/flutter_test.dart';
import 'package:patient_tracker/features/my_ai/models/risk_models.dart';
import 'package:patient_tracker/features/my_ai/services/risk_scanner.dart';

void main() {
  group('RiskScanner', () {
    const scanner = RiskScanner(latency: Duration.zero);

    test('detects high severity behavioral risk', () async {
      final result = await scanner
          .run('Patient voiced suicidal thoughts and hopelessness.');
      expect(result.overallLevel, RiskLevel.high);
      expect(
        result.items.any((item) => item.category == 'Behavioral health'),
        isTrue,
      );
    });

    test('flags medium adherence risk', () async {
      final result = await scanner
          .run('Patient missed dose twice this week and ran out of inhaler.');
      expect(
        result.items
            .firstWhere((item) => item.category == 'Medication adherence')
            .level,
        RiskLevel.medium,
      );
    });

    test('flags low respiratory risk', () async {
      final result =
          await scanner.run('Reports mild congestion but no other symptoms.');
      expect(result.items.first.level, RiskLevel.low);
      expect(result.overallLevel, RiskLevel.low);
    });

    test('handles consult with no triggers', () async {
      final result =
          await scanner.run('Routine follow up. Patient doing well overall.');
      expect(result.items, isEmpty);
      expect(result.overallScore, lessThan(20));
    });
  });
}
