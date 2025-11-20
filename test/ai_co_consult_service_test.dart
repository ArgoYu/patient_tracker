import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_tracker/data/models/ai_co_consult_outcome.dart';
import 'package:patient_tracker/data/models/goal.dart';
import 'package:patient_tracker/features/my_ai/controller/ai_co_consult_service.dart';

void main() {
  group('AiCoConsultSessionController', () {
    test('generates structured outcome with plan, goals, meds, and follow-ups',
        () {
      final timestamps = [
        DateTime(2024, 1, 1, 9, 0),
        DateTime(2024, 1, 1, 9, 1),
        DateTime(2024, 1, 1, 9, 2),
        DateTime(2024, 1, 1, 9, 3),
        DateTime(2024, 1, 1, 9, 4),
      ];
      var tick = 0;
      DateTime clock() => timestamps[(tick++).clamp(0, timestamps.length - 1)];

      final controller = AiCoConsultSessionController(clock: clock);
      controller.start(conversationId: 'dr.chen', contactName: 'Dr. Chen');

      controller.recordClinicianMessage(
        'Let\'s add a 20 minute walk after dinner to your weekly plan so we can track evening energy.',
      );
      controller.recordClinicianMessage(
        'Increase Sertraline to 75 mg in the morning and note any dizziness or nausea.',
      );
      controller.recordClinicianMessage(
        'Try a breathing exercise goal at least 3 times weekly before bed to calm the mind.',
      );
      controller.recordPatientMessage(
          'Should I keep logging sleep when I wake up groggy?');

      final outcome = controller.complete(
        consentRecord: AiConsentRecord(
          granted: true,
          recordedAt: timestamps.last,
          method: 'unit-test',
          version: 'test',
        ),
      );

      expect(outcome.planUpdates, isNotEmpty);
      expect(outcome.goalProposals, isNotEmpty);
      expect(outcome.medicationChanges, isNotEmpty);
      expect(outcome.followUpQuestions, isNotEmpty);
      expect(outcome.chiefComplaint, isNotEmpty);
      expect(outcome.historySummary, isNotEmpty);
      expect(outcome.diagnosisSummary, isNotEmpty);
      expect(outcome.recommendations, isNotEmpty);
      expect(outcome.alerts, isNotEmpty);

      expect(outcome.summary, contains('Dr.'));
      expect(outcome.medicationChanges.first.dose, contains('75'));
      expect(outcome.goalProposals.first.title, isNotEmpty);
      expect(outcome.followUpQuestions.first, contains('?'));
    });

    test('buildGoalFromProposal creates default goal meta', () {
      const proposal = AiCoConsultGoalProposal(
        title: 'Log daily water intake',
        instructions:
            'Record at least 8 cups of water each day and add one cup after lunch.',
        category: GoalCategory.hydration,
        frequency: GoalFrequency.daily,
        timesPerPeriod: 8,
        importance: GoalImportance.high,
      );

      final goal = buildGoalFromProposal(proposal);

      expect(goal.title, proposal.title);
      expect(goal.instructions, proposal.instructions);
      expect(goal.category, GoalCategory.hydration);
      expect(goal.frequency, GoalFrequency.daily);
      expect(goal.timesPerPeriod, 8);
      expect(goal.importance, GoalImportance.high);
      expect(goal.progress, 0);
      expect(goal.reminder, const TimeOfDay(hour: 9, minute: 0));
    });
  });
}
