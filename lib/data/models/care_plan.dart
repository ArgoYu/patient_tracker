// lib/data/models/care_plan.dart

/// Summarises care plan metadata displayed on the profile page.
class CarePlan {
  CarePlan({
    required this.physician,
    required this.insurance,
    required this.medsEffects,
    required this.plan,
    required this.expectedOutcomes,
  });

  final String physician;
  final InsuranceSummary insurance;
  final List<MedEffect> medsEffects;
  final List<String> plan;
  final List<String> expectedOutcomes;
}

/// Insurance cost breakdown for the care plan.
class InsuranceSummary {
  InsuranceSummary({required this.totalCost, required this.covered});

  final double totalCost;
  final double covered;

  double youPay() => (totalCost - covered).clamp(0, totalCost);
}

/// Medication effect details listed in the care plan.
class MedEffect {
  const MedEffect({
    required this.name,
    required this.effect,
    required this.sideEffects,
  });

  final String name;
  final String effect;
  final String sideEffects;
}
