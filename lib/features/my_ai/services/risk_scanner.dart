// lib/features/my_ai/services/risk_scanner.dart

import '../models/risk_models.dart';

const _defaultLatency = Duration(milliseconds: 420);

/// Public API entry used across the app & tests.
Future<RiskResult> runRiskScan(String notes) {
  return const RiskScanner().run(notes);
}

/// Keyword based risk detector that surfaces high-signal findings.
class RiskScanner {
  const RiskScanner({this.latency = _defaultLatency});

  final Duration latency;

  Future<RiskResult> run(String notes) async {
    final normalized = notes.toLowerCase();
    final findings = <RiskItem>[];

    for (final group in _rules) {
      final match = group.evaluate(normalized);
      if (match == null) continue;
      findings.add(match);
    }

    await Future.delayed(latency);
    final details = _buildRuleDetails(normalized);
    final computedMax = details.fold<int>(0, (sum, d) => sum + d.weight);
    final maxScore = computedMax == 0 ? 100 : computedMax;
    final score =
        details.where((d) => d.matched).fold<int>(0, (sum, d) => sum + d.weight);
    final summary = findings.isEmpty
        ? 'No acute risk signals detected. Continue routine monitoring.'
        : 'Detected ${findings.length} risk ${findings.length == 1 ? 'theme' : 'themes'}, '
            'highest level ${_labelFor(findings.map((f) => f.level).reduce(_maxLevel))}.';

    return RiskResult(
      overallScore: score,
      maxScore: maxScore,
      items: findings,
      summary: summary,
      generatedAt: DateTime.now(),
      details: details,
    );
  }
}

class _RiskRule {
  const _RiskRule({
    required this.category,
    required this.low,
    required this.medium,
    required this.high,
    required this.suggestion,
  });

  final String category;
  final List<String> low;
  final List<String> medium;
  final List<String> high;
  final String suggestion;

  RiskItem? evaluate(String normalizedNotes) {
    final hits = <String>[];
    RiskLevel? matchedLevel;

    bool _matchAny(List<String> keywords, RiskLevel level) {
      final localHits = keywords
          .where((keyword) => normalizedNotes.contains(keyword))
          .toList();
      if (localHits.isEmpty) return false;
      hits.addAll(localHits);
      matchedLevel = level;
      return true;
    }

    if (_matchAny(high, RiskLevel.high)) {
      return RiskItem(
        category: category,
        level: RiskLevel.high,
        triggers: hits,
        suggestion: suggestion,
      );
    }
    if (_matchAny(medium, RiskLevel.medium)) {
      return RiskItem(
        category: category,
        level: RiskLevel.medium,
        triggers: hits,
        suggestion: suggestion,
      );
    }
    if (_matchAny(low, RiskLevel.low)) {
      return RiskItem(
        category: category,
        level: RiskLevel.low,
        triggers: hits,
        suggestion: suggestion,
      );
    }
    return null;
  }
}

final List<_RiskRule> _rules = <_RiskRule>[
  const _RiskRule(
    category: 'Respiratory stability',
    suggestion: 'Escalate to pulmonary consult if breathing symptoms worsen.',
    high: [
      'chest pain',
      'short of breath at rest',
      'oxygen dropped',
      'cyanosis',
    ],
    medium: [
      'nighttime cough',
      'wheezing episodes',
      'rescue inhaler more than twice',
      'peak flow decline',
    ],
    low: [
      'mild congestion',
      'seasonal allergy',
      'light cough',
    ],
  ),
  const _RiskRule(
    category: 'Medication adherence',
    suggestion: 'Confirm refills and reinforce adherence plan within 48 hours.',
    high: [
      'stopped taking',
      'refused medication',
      'unable to afford meds',
    ],
    medium: [
      'missed dose',
      'skipped medication',
      'sometimes forget',
      'ran out of inhaler',
    ],
    low: [
      'delayed dose',
      'took late',
    ],
  ),
  const _RiskRule(
    category: 'Behavioral health',
    suggestion:
        'Conduct safety check-in and update safety plan or crisis resources.',
    high: [
      'suicidal',
      'self-harm',
      'cannot keep self safe',
    ],
    medium: [
      'panic attack',
      'hopeless',
      'flashbacks',
      'severe anxiety',
    ],
    low: [
      'trouble sleeping',
      'feeling down',
    ],
  ),
  const _RiskRule(
    category: 'Care coordination',
    suggestion: 'Schedule earlier follow-up and share summary with care team.',
    high: [
      'missed specialist visit repeatedly',
      'discharged against advice',
    ],
    medium: [
      'transportation barrier',
      'missed appointment',
      'insurance issue',
    ],
    low: [
      'needs reminder',
      'prefers telehealth',
    ],
  ),
];

class _RuleDetailBlueprint {
  const _RuleDetailBlueprint({
    required this.category,
    required this.description,
    required this.weight,
    required this.keywords,
  });

  final String category;
  final String description;
  final int weight;
  final List<String> keywords;
}

List<_RuleDetailBlueprint> _buildRulebook() {
  const weights = [40, 25, 20, 15];
  return List<_RuleDetailBlueprint>.generate(_rules.length, (index) {
    final rule = _rules[index];
    final keywords = <String>[
      ...rule.high,
      ...rule.medium,
      ...rule.low,
    ];
    final weight =
        index < weights.length ? weights[index] : weights.last;
    return _RuleDetailBlueprint(
      category: rule.category,
      description: keywords.join(' OR '),
      weight: weight,
      keywords: keywords,
    );
  });
}

List<RiskRuleDetail> _buildRuleDetails(String normalizedNotes) {
  final book = _buildRulebook();
  return book.map((entry) {
    final evidence = entry.keywords
        .where((keyword) => normalizedNotes.contains(keyword))
        .toList();
    return RiskRuleDetail(
      category: entry.category,
      rule: entry.description,
      weight: entry.weight,
      matched: evidence.isNotEmpty,
      evidence: evidence,
    );
  }).toList(growable: false);
}

RiskLevel _maxLevel(RiskLevel a, RiskLevel b) {
  if (a == RiskLevel.high || b == RiskLevel.high) return RiskLevel.high;
  if (a == RiskLevel.medium || b == RiskLevel.medium) return RiskLevel.medium;
  return RiskLevel.low;
}

String _labelFor(RiskLevel level) {
  switch (level) {
    case RiskLevel.low:
      return 'low';
    case RiskLevel.medium:
      return 'medium';
    case RiskLevel.high:
      return 'high';
  }
}
