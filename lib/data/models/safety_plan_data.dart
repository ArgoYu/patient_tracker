// lib/data/models/safety_plan_data.dart

/// Holds editable safety plan content for the patient.
class SafetyPlanData {
  SafetyPlanData({
    this.warningSigns = '',
    this.copingStrategies = '',
    this.supportContacts = '',
    this.nextSteps = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
  });

  final String warningSigns;
  final String copingStrategies;
  final String supportContacts;
  final String nextSteps;
  final String emergencyContactName;
  final String emergencyContactPhone;

  SafetyPlanData copyWith({
    String? warningSigns,
    String? copingStrategies,
    String? supportContacts,
    String? nextSteps,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) {
    return SafetyPlanData(
      warningSigns: warningSigns ?? this.warningSigns,
      copingStrategies: copingStrategies ?? this.copingStrategies,
      supportContacts: supportContacts ?? this.supportContacts,
      nextSteps: nextSteps ?? this.nextSteps,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
    );
  }

  bool get hasEmergencyContact => emergencyContactPhone.trim().isNotEmpty;

  factory SafetyPlanData.defaults() => SafetyPlanData(
        warningSigns:
            'Changes in sleep or appetite patterns\nFeeling suddenly overwhelmed or hopeless\nUrges to withdraw from people or activities',
        copingStrategies:
            'Try box breathing: inhale 4 · hold 4 · exhale 4 · hold 4\nUse the 5-4-3-2-1 grounding exercise to stay present\nWrite down one worry and one calming thought next to it',
        supportContacts:
            'Partner · Jamie (555-0102)\nCare team nurse · Weekdays 8:00–18:00\nNeighbour · Alex (down the hall)',
        nextSteps:
            'Move to a brighter or shared space in your home\nPut away medications or objects that feel unsafe right now\nSet a 10-minute timer and do a gentle activity (shower, stretch)',
        emergencyContactName: 'Jamie (Partner)',
        emergencyContactPhone: '555-0102',
      );
}
