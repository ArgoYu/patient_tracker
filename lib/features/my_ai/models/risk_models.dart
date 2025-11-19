// lib/features/my_ai/models/risk_models.dart

/// Categorizes the severity of a detected risk.
enum RiskLevel { low, medium, high }

/// Captures how a specific weighted rule contributed to the final score.
class RiskRuleDetail {
  const RiskRuleDetail({
    required this.category,
    required this.rule,
    required this.weight,
    required this.matched,
    required this.evidence,
  });

  final String category;
  final String rule;
  final int weight;
  final bool matched;
  final List<String> evidence;
}

/// Represents a single risk finding produced by the scanner.
class RiskItem {
  const RiskItem({
    required this.category,
    required this.level,
    required this.triggers,
    required this.suggestion,
  });

  final String category;
  final RiskLevel level;
  final List<String> triggers;
  final String suggestion;

  bool get hasTriggers => triggers.isNotEmpty;
}

/// Structured risk scan output rendered by the UI and exporter.
class RiskResult {
  const RiskResult({
    required this.overallScore,
    required this.maxScore,
    required this.items,
    required this.summary,
    required this.generatedAt,
    required this.details,
  })  : assert(overallScore >= 0),
        assert(maxScore > 0),
        assert(overallScore <= maxScore);

  final int overallScore;
  final int maxScore;
  final List<RiskItem> items;
  final String summary;
  final DateTime generatedAt;
  final List<RiskRuleDetail> details;

  bool get hasFindings => items.isNotEmpty;

  RiskLevel get overallLevel {
    if (items.isNotEmpty) {
      return items.map((item) => item.level).reduce(_maxLevel);
    }
    if (overallScore >= 70) return RiskLevel.high;
    if (overallScore >= 40) return RiskLevel.medium;
    return RiskLevel.low;
  }

  static RiskLevel _maxLevel(RiskLevel a, RiskLevel b) {
    if (a == RiskLevel.high || b == RiskLevel.high) return RiskLevel.high;
    if (a == RiskLevel.medium || b == RiskLevel.medium) return RiskLevel.medium;
    return RiskLevel.low;
  }
}
