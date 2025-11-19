import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:patient_tracker/core/utils/date_formats.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/goal.dart';
import '../../../data/models/rx_medication.dart';
import '../../../data/models/ai_co_consult_outcome.dart';
import '../ai_care_facade.dart';

/// Structured transcript entry captured during the session.
class AiCoConsultUtterance {
  AiCoConsultUtterance({
    required this.speaker,
    required this.message,
    required this.timestamp,
  });

  final AiCoConsultSpeaker speaker;
  final String message;
  final DateTime timestamp;

  String get normalized => message.toLowerCase();
}

enum ConsultReportStatus {
  idle,
  reportPendingReview,
  reportRejected,
  reportApproved,
  recordingDeleted,
}

/// Represents a single doctor-patient AI co-consult session.
class AiCoConsultSession {
  AiCoConsultSession({
    required this.id,
    required this.conversationId,
    required this.contactName,
    required this.startedAt,
  });

  final String id;
  final String conversationId;
  final String contactName;
  final DateTime startedAt;

  final List<AiCoConsultUtterance> transcript = [];
  DateTime? completedAt;

  ConsultReportStatus reportStatus = ConsultReportStatus.idle;
  bool doctorApproved = false;
  String? doctorSignature;
  DateTime? approvalTime;
  bool recordingDeleted = false;

  void record(AiCoConsultSpeaker speaker, String message, DateTime time) {
    if (message.trim().isEmpty) return;
    transcript.add(
      AiCoConsultUtterance(
        speaker: speaker,
        message: message.trim(),
        timestamp: time,
      ),
    );
  }
}

/// Represents the listening lifecycle for the Co-Consult feature.
enum AiCoConsultListeningStatus { idle, listening, paused, completed }

typedef AiCoConsultClock = DateTime Function();

/// Coordinates transcript capture and summary generation.
class AiCoConsultSessionController {
  AiCoConsultSessionController({
    Uuid? uuid,
    AiCoConsultClock? clock,
  })  : _uuid = uuid ?? const Uuid(),
        _clock = clock ?? DateTime.now;

  final Uuid _uuid;
  final AiCoConsultClock _clock;

  AiCoConsultSession? _activeSession;

  AiCoConsultSession? get activeSession => _activeSession;

  AiCoConsultSession start({
    required String conversationId,
    required String contactName,
  }) {
    final now = _clock();
    final session = AiCoConsultSession(
      id: _uuid.v4(),
      conversationId: conversationId,
      contactName: contactName,
      startedAt: now,
    );
    _activeSession = session;
    return session;
  }

  void ensureActive() {
    if (_activeSession == null) {
      throw StateError('AI Co-Consult session has not been started.');
    }
  }

  void recordPatientMessage(String message) {
    ensureActive();
    _activeSession!.record(AiCoConsultSpeaker.patient, message, _clock());
  }

  void recordClinicianMessage(String message) {
    ensureActive();
    _activeSession!.record(AiCoConsultSpeaker.clinician, message, _clock());
  }

  AiCoConsultOutcome complete({
    required AiConsentRecord consentRecord,
    Map<String, String>? metadataOverrides,
  }) {
    ensureActive();
    final session = _activeSession!;
    session.completedAt = _clock();
    final clinicianStatements = session.transcript
        .where((u) => u.speaker == AiCoConsultSpeaker.clinician)
        .toList();
    final patientStatements = session.transcript
        .where((u) => u.speaker == AiCoConsultSpeaker.patient)
        .toList();

    final planUpdates = _extractPlanUpdates(clinicianStatements);
    final goalProposals = _extractGoalProposals(clinicianStatements);
    final medicationChanges = _extractMedicationChanges(clinicianStatements);
    final timeline = _buildTimeline(
      session: session,
      planUpdates: planUpdates,
      goalProposals: goalProposals,
      medicationChanges: medicationChanges,
    );
    final followUps = _generatePatientQuestions(
      planUpdates: planUpdates,
      goalProposals: goalProposals,
      medicationChanges: medicationChanges,
      patientStatements: patientStatements,
    );
    final alerts = _detectAlerts(session.transcript);
    final chiefComplaint =
        _deriveChiefComplaint(patientStatements, clinicianStatements);
    final historySummary = _deriveHistorySummary(patientStatements);
    final diagnosisSummary = _deriveDiagnosisSummary(
      clinicianStatements,
      planUpdates,
    );
    final recommendations = _deriveRecommendations(
      planUpdates: planUpdates,
      medicationChanges: medicationChanges,
      followUps: followUps,
    );

    final summary = _composeSummary(
      contactName: session.contactName,
      chiefComplaint: chiefComplaint,
      historySummary: historySummary,
      diagnosisSummary: diagnosisSummary,
      recommendations: recommendations,
      planUpdates: planUpdates,
      goalProposals: goalProposals,
      medicationChanges: medicationChanges,
      clinicianStatements: clinicianStatements,
      followUps: followUps,
      alerts: alerts,
    );

    final transcriptSegments = session.transcript
        .map(
          (utterance) => AiCoConsultTranscriptSegment(
            speaker: utterance.speaker,
            text: utterance.message,
            startedAt: utterance.timestamp,
            endedAt: utterance.timestamp,
          ),
        )
        .toList();
    final transcript = transcriptSegments
        .map(
          (segment) =>
              '${segment.speaker == AiCoConsultSpeaker.clinician ? 'Clinician' : 'Patient'}: ${segment.text}',
        )
        .join('\n');

    final outcome = AiCoConsultOutcome(
      sessionId: session.id,
      conversationId: session.conversationId,
      contactName: session.contactName,
      startedAt: session.startedAt,
      completedAt: session.completedAt!,
      summary: summary,
      chiefComplaint: chiefComplaint,
      historySummary: historySummary,
      diagnosisSummary: diagnosisSummary,
      recommendations: recommendations,
      planUpdates: planUpdates,
      goalProposals: goalProposals,
      medicationChanges: medicationChanges,
      followUpQuestions: followUps,
      alerts: alerts,
      timeline: timeline,
      generatedAt: session.completedAt!,
      transcript: transcript,
      transcriptSegments: transcriptSegments,
      consentRecord: consentRecord,
      metadata: {
        'session_duration_seconds':
            '${session.completedAt!.difference(session.startedAt).inSeconds}',
        'clinician_statement_count': '${clinicianStatements.length}',
        'patient_statement_count': '${patientStatements.length}',
        'transcript_length': '${transcript.length}',
        if (metadataOverrides != null) ...metadataOverrides,
      },
    );

    _activeSession = null;
    return outcome;
  }

  String _composeSummary({
    required String contactName,
    required String chiefComplaint,
    required String historySummary,
    required String diagnosisSummary,
    required String recommendations,
    required List<String> planUpdates,
    required List<AiCoConsultGoalProposal> goalProposals,
    required List<AiCoConsultMedicationChange> medicationChanges,
    required List<AiCoConsultUtterance> clinicianStatements,
    required List<String> followUps,
    required List<AiCoConsultAlert> alerts,
  }) {
    final topClinicianLines = clinicianStatements
        .map((u) => u.message)
        .where((line) => line.length > 12)
        .toList();
    final highlights = topClinicianLines.take(2).toList();

    final buffer = <String>[];
    buffer.add('Dr. $contactName reviewed today\'s updates with you.');
    if (chiefComplaint.isNotEmpty) {
      buffer.add('Chief complaint: $chiefComplaint');
    }
    if (historySummary.isNotEmpty) {
      buffer.add('History summary: $historySummary');
    }
    if (diagnosisSummary.isNotEmpty) {
      buffer.add('Diagnosis summary: $diagnosisSummary');
    }
    if (recommendations.isNotEmpty) {
      buffer.add('Recommendations: $recommendations');
    }

    if (planUpdates.isNotEmpty) {
      buffer.add(
          'Care plan focus: ${planUpdates.take(2).join('; ')}${planUpdates.length > 2 ? '…' : '.'}');
    }
    if (goalProposals.isNotEmpty) {
      final goalTitles = goalProposals.map((g) => g.title).take(2).join('; ');
      buffer.add(
          'Goals to work on: $goalTitles${goalProposals.length > 2 ? '…' : '.'}');
    }
    if (medicationChanges.isNotEmpty) {
      final medSummary = medicationChanges
          .map((m) =>
              '${m.action == AiMedicationAction.add ? 'start' : m.action == AiMedicationAction.update ? 'adjust' : 'stop'} ${m.name}${m.dose != null ? ' (${m.dose})' : ''}')
          .take(2)
          .join('; ');
      buffer.add(
          'Medication updates: $medSummary${medicationChanges.length > 2 ? '…' : '.'}');
    }
    if (highlights.isNotEmpty) {
      buffer.add('Key takeaways: ${highlights.join(' · ')}');
    }
    if (followUps.isNotEmpty) {
      buffer.add(
          'Suggested follow-ups: ${followUps.take(2).join('; ')}${followUps.length > 2 ? '…' : '.'}');
    }
    if (alerts.isNotEmpty) {
      buffer.add(
          'Alerts flagged: ${alerts.map((a) => a.title).take(2).join('; ')}${alerts.length > 2 ? '…' : '.'}');
    }

    return buffer.join(' ');
  }

  List<String> _extractPlanUpdates(List<AiCoConsultUtterance> statements) {
    final keywords = [
      'plan',
      'schedule',
      'routine',
      'monitor',
      'track',
      'review',
      'check-in',
      'therapy',
      'session',
    ];
    final updates = <String>{};
    for (final statement in statements) {
      final lower = statement.normalized;
      if (keywords.any(lower.contains)) {
        updates.add(_cleanSentence(statement.message));
      }
    }
    return updates.take(4).toList();
  }

  List<AiCoConsultGoalProposal> _extractGoalProposals(
      List<AiCoConsultUtterance> statements) {
    final proposals = <AiCoConsultGoalProposal>[];
    for (final statement in statements) {
      final lower = statement.normalized;
      if (!(lower.contains('goal') ||
          lower.contains('walk') ||
          lower.contains('exercise') ||
          lower.contains('sleep') ||
          lower.contains('hydrate') ||
          lower.contains('breathing') ||
          lower.contains('stretch'))) {
        continue;
      }
      final title = _generateGoalTitle(statement.message);
      final category = _inferGoalCategory(lower);
      final freq = _inferGoalFrequency(lower);
      final times = _inferTimesPerPeriod(lower);
      final importance = _inferImportance(lower);
      final instructions = _deriveInstructions(statement.message);
      proposals.add(
        AiCoConsultGoalProposal(
          title: title,
          instructions: instructions,
          category: category,
          frequency: freq,
          timesPerPeriod: times,
          importance: importance,
        ),
      );
    }
    return proposals.take(3).toList();
  }

  List<AiCoConsultMedicationChange> _extractMedicationChanges(
      List<AiCoConsultUtterance> statements) {
    final changes = <AiCoConsultMedicationChange>[];
    for (final statement in statements) {
      final lower = statement.normalized;
      if (!(lower.contains('med') ||
          lower.contains('dose') ||
          lower.contains('mg') ||
          lower.contains('tablet') ||
          lower.contains('pill'))) {
        continue;
      }
      final name = _inferMedicationName(statement.message);
      final action = _inferMedicationAction(lower);
      final dose = _extractDose(statement.message);
      final effect = _inferEffect(statement.message);
      final sideEffects = _inferSideEffects(statement.message);
      changes.add(
        AiCoConsultMedicationChange(
          name: name,
          action: action,
          dose: dose,
          effect: effect,
          sideEffects: sideEffects,
        ),
      );
    }
    return changes.take(3).toList();
  }

  List<String> _generatePatientQuestions({
    required List<String> planUpdates,
    required List<AiCoConsultGoalProposal> goalProposals,
    required List<AiCoConsultMedicationChange> medicationChanges,
    required List<AiCoConsultUtterance> patientStatements,
  }) {
    final followUps = <String>{};
    if (planUpdates.isNotEmpty) {
      followUps.add('How should I track progress on "${planUpdates.first}"?');
    }
    if (goalProposals.isNotEmpty) {
      followUps.add(
          'When should we revisit the goal "${goalProposals.first.title}"?');
    }
    final medUpdate = medicationChanges.firstWhere(
      (m) => m.action != AiMedicationAction.discontinue,
      orElse: () => medicationChanges.isEmpty
          ? const AiCoConsultMedicationChange(
              name: '', action: AiMedicationAction.update)
          : medicationChanges.first,
    );
    if (medicationChanges.isNotEmpty) {
      followUps.add(
          'What side effects should I watch for with the new medication ${medUpdate.name.isNotEmpty ? medUpdate.name : ''}?');
    }
    for (final patient in patientStatements
        .where((u) => u.message.contains('?') && u.message.length < 140)) {
      followUps.add(
          'Is there anything else I should share about "${_cleanSentence(patient.message)}"?');
    }
    if (followUps.length < 3) {
      followUps.addAll({
        'Could we review any warning signs that should trigger a call before the next visit?',
        'Are there lifestyle changes I should focus on before our follow-up?',
        'Would it help if I share symptom or medication logs ahead of our next check-in?'
      });
    }
    return followUps.take(5).toList();
  }

  List<TimelineItem> _buildTimeline({
    required AiCoConsultSession session,
    required List<String> planUpdates,
    required List<AiCoConsultGoalProposal> goalProposals,
    required List<AiCoConsultMedicationChange> medicationChanges,
  }) {
    final completedAt = session.completedAt ?? _clock();
    final items = <TimelineItem>[
      TimelineItem(
        when: session.startedAt,
        title: 'Session Started',
        detail: 'AI co-consult session began recording.',
        category: 'administrative',
      ),
      TimelineItem(
        when: completedAt,
        title: 'Session Completed',
        detail: 'Recording stopped and summary generated.',
        category: 'administrative',
      ),
    ];

    if (planUpdates.isNotEmpty) {
      items.add(
        TimelineItem(
          when: completedAt.add(const Duration(days: 3)),
          title: 'Care Plan Review',
          detail:
              'Review progress on ${planUpdates.take(2).join('; ')}${planUpdates.length > 2 ? '…' : ''}',
          category: 'care-plan',
        ),
      );
    }

    for (final proposal in goalProposals.take(2)) {
      items.add(
        TimelineItem(
          when: completedAt.add(const Duration(days: 7)),
          title: 'Goal Check-in',
          detail: proposal.title,
          category: 'goal',
        ),
      );
    }

    for (final change in medicationChanges.take(2)) {
      final category = change.action == AiMedicationAction.discontinue
          ? 'medication-stop'
          : 'medication';
      items.add(
        TimelineItem(
          when: completedAt.add(
            Duration(
              days: change.action == AiMedicationAction.add ? 2 : 5,
            ),
          ),
          title: change.action == AiMedicationAction.discontinue
              ? 'Stop ${change.name}'
              : '${change.action == AiMedicationAction.add ? 'Start' : 'Adjust'} ${change.name}',
          detail:
              change.dose != null ? change.dose! : 'Follow dosing guidance.',
          category: category,
        ),
      );
    }

    if (!items.any((item) => item.category == 'follow-up')) {
      items.add(
        TimelineItem(
          when: completedAt.add(const Duration(days: 14)),
          title: 'Follow-up Visit',
          detail: 'Schedule visit to review medication and goals.',
          category: 'follow-up',
        ),
      );
    }

    items.sort((a, b) => a.when.compareTo(b.when));
    return items;
  }

  String _deriveChiefComplaint(
    List<AiCoConsultUtterance> patientStatements,
    List<AiCoConsultUtterance> clinicianStatements,
  ) {
    final prioritized = [
      'pain',
      '疼',
      'chest',
      'breath',
      'shortness',
      'headache',
      'dizzy',
      '晕',
      'fever',
      '发烧',
      'chief complaint',
      '主诉',
    ];
    for (final statement in patientStatements) {
      final lower = statement.normalized;
      if (prioritized.any(lower.contains)) {
        return _cleanSentence(statement.message);
      }
    }
    final clinicianNote = clinicianStatements.firstWhere(
      (u) => u.normalized.contains('chief complaint'),
      orElse: () => clinicianStatements.isNotEmpty
          ? clinicianStatements.first
          : AiCoConsultUtterance(
              speaker: AiCoConsultSpeaker.clinician,
              message: '',
              timestamp: DateTime.now(),
            ),
    );
    if (clinicianNote.message.isNotEmpty) {
      return _cleanSentence(clinicianNote.message);
    }
    return 'No chief complaint captured.';
  }

  String _deriveHistorySummary(List<AiCoConsultUtterance> patientStatements) {
    if (patientStatements.isEmpty) {
      return 'Patient did not provide additional history during this consult.';
    }
    final lines = patientStatements
        .take(3)
        .map((u) => _cleanSentence(u.message))
        .toList();
    return lines.join(' ');
  }

  String _deriveDiagnosisSummary(
    List<AiCoConsultUtterance> clinicianStatements,
    List<String> planUpdates,
  ) {
    final keywords = ['diagnos', 'assessment', '评估', '判断', '诊断'];
    final matches = clinicianStatements
        .where((u) => keywords.any(u.normalized.contains))
        .map((u) => _cleanSentence(u.message))
        .toList();
    if (matches.isNotEmpty) {
      return matches.take(2).join(' ');
    }
    if (planUpdates.isNotEmpty) {
      return 'Focus area: ${planUpdates.first}';
    }
    return 'No clear diagnostic summary recorded for this visit.';
  }

  String _deriveRecommendations({
    required List<String> planUpdates,
    required List<AiCoConsultMedicationChange> medicationChanges,
    required List<String> followUps,
  }) {
    final segments = <String>[];
    if (planUpdates.isNotEmpty) {
      segments.add('Plan: ${planUpdates.take(2).join('; ')}');
    }
    if (medicationChanges.isNotEmpty) {
      final meds = medicationChanges
          .map((m) =>
              '${m.action == AiMedicationAction.add ? 'Start' : m.action == AiMedicationAction.update ? 'Adjust' : 'Stop'} ${m.name}${m.dose != null ? ' (${m.dose})' : ''}')
          .take(2)
          .join('; ');
      segments.add('Medication guidance: $meds');
    }
    if (followUps.isNotEmpty) {
      segments.add('Follow-up reminder: ${followUps.first}');
    }
    if (segments.isEmpty) {
      return 'Continue current plan and monitor symptoms.';
    }
    return segments.join(' ');
  }

  List<AiCoConsultAlert> _detectAlerts(
    List<AiCoConsultUtterance> transcript,
  ) {
    final alerts = <String, AiCoConsultAlert>{};

    void addAlert(AiCoConsultAlert alert) {
      alerts.putIfAbsent('${alert.severity}_${alert.title}', () => alert);
    }

    for (final entry in transcript) {
      final lower = entry.normalized;
      if (lower.contains('chest pain') || lower.contains('胸痛')) {
        addAlert(
          AiCoConsultAlert(
            severity: AiCoConsultAlertSeverity.high,
            title: 'Possible chest pain — assess for acute cardiac issues',
            detail: _cleanSentence(entry.message),
          ),
        );
      }
      if (lower.contains('shortness of breath') || lower.contains('呼吸困难')) {
        addAlert(
          AiCoConsultAlert(
            severity: AiCoConsultAlertSeverity.high,
            title: 'Shortness of breath reported — evaluate immediately',
            detail: _cleanSentence(entry.message),
          ),
        );
      }
      if (lower.contains('suicid') ||
          lower.contains('自杀') ||
          lower.contains('self-harm') ||
          lower.contains('自残')) {
        addAlert(
          AiCoConsultAlert(
            severity: AiCoConsultAlertSeverity.high,
            title: 'Self-harm or suicide risk detected',
            detail: _cleanSentence(entry.message),
          ),
        );
      }
      if (lower.contains('overdose') || lower.contains('过量')) {
        addAlert(
          AiCoConsultAlert(
            severity: AiCoConsultAlertSeverity.high,
            title: 'Potential medication overdose risk',
            detail: _cleanSentence(entry.message),
          ),
        );
      }
      if (lower.contains('severe') && lower.contains('allergy') ||
          lower.contains('过敏')) {
        addAlert(
          AiCoConsultAlert(
            severity: AiCoConsultAlertSeverity.medium,
            title: 'Signs of an acute allergic reaction reported',
            detail: _cleanSentence(entry.message),
          ),
        );
      }
      if (lower.contains('rash') || lower.contains('皮疹')) {
        addAlert(
          AiCoConsultAlert(
            severity: AiCoConsultAlertSeverity.medium,
            title: 'Rash symptoms noted — schedule a review',
            detail: _cleanSentence(entry.message),
          ),
        );
      }
      if (lower.contains('dizzy') ||
          lower.contains('dizziness') ||
          lower.contains('眩晕') ||
          lower.contains('头晕')) {
        addAlert(
          AiCoConsultAlert(
            severity: AiCoConsultAlertSeverity.medium,
            title: 'Patient reports significant dizziness',
            detail: _cleanSentence(entry.message),
          ),
        );
      }
      if (lower.contains('missed dose') ||
          lower.contains('漏服') ||
          lower.contains('忘记吃药')) {
        addAlert(
          AiCoConsultAlert(
            severity: AiCoConsultAlertSeverity.low,
            title: 'Medication adherence concern flagged',
            detail: _cleanSentence(entry.message),
          ),
        );
      }
    }

    return alerts.values.take(4).toList();
  }

  String _cleanSentence(String input) {
    final trimmed = input.trim();
    if (trimmed.endsWith('.')) return trimmed;
    if (trimmed.endsWith('。')) return trimmed;
    return '$trimmed.';
  }

  String _generateGoalTitle(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('walk') || lower.contains('steps')) {
      return 'Complete planned daily walks';
    }
    if (lower.contains('sleep')) {
      return 'Maintain a consistent sleep routine';
    }
    if (lower.contains('hydrate') || lower.contains('water')) {
      return 'Log daily hydration';
    }
    if (lower.contains('breathing') || lower.contains('relax')) {
      return 'Practice relaxation or breathing exercises';
    }
    if (lower.contains('stretch')) {
      return 'Add gentle stretching before bed';
    }
    return 'Work toward the updated consult goal';
  }

  GoalCategory _inferGoalCategory(String lower) {
    if (lower.contains('walk') ||
        lower.contains('exercise') ||
        lower.contains('steps') ||
        lower.contains('movement')) {
      return GoalCategory.exercises;
    }
    if (lower.contains('sleep') || lower.contains('bed')) {
      return GoalCategory.sleep;
    }
    if (lower.contains('hydrate') ||
        lower.contains('water') ||
        lower.contains('drink')) {
      return GoalCategory.hydration;
    }
    if (lower.contains('meditation') ||
        lower.contains('breathing') ||
        lower.contains('relax')) {
      return GoalCategory.meditation;
    }
    if (lower.contains('diet') || lower.contains('nutrition')) {
      return GoalCategory.diet;
    }
    return GoalCategory.custom;
  }

  GoalFrequency _inferGoalFrequency(String lower) {
    if (lower.contains('daily') || lower.contains('every day')) {
      return GoalFrequency.daily;
    }
    if (lower.contains('weekly') || lower.contains('each week')) {
      return GoalFrequency.weekly;
    }
    if (lower.contains('monthly')) {
      return GoalFrequency.monthly;
    }
    return GoalFrequency.weekly;
  }

  int _inferTimesPerPeriod(String lower) {
    final match = RegExp(r'(\d+)\s*(x|times|次)').firstMatch(lower);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '')?.clamp(1, 6) ?? 1;
    }
    if (lower.contains('twice') || lower.contains('两次')) return 2;
    if (lower.contains('three') || lower.contains('三次')) return 3;
    return 1;
  }

  GoalImportance _inferImportance(String lower) {
    if (lower.contains('important') ||
        lower.contains('关键') ||
        lower.contains('priority')) {
      return GoalImportance.high;
    }
    if (lower.contains('optional') || lower.contains('尝试')) {
      return GoalImportance.low;
    }
    return GoalImportance.medium;
  }

  String? _deriveInstructions(String message) {
    if (message.length < 18) return null;
    return _cleanSentence(message);
  }

  String _inferMedicationName(String message) {
    final match =
        RegExp(r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)').firstMatch(message);
    if (match != null) {
      return match.group(1) ?? 'Medication';
    }
    final chineseMatch = RegExp(r'([\u4e00-\u9fa5]{2,})').firstMatch(message);
    if (chineseMatch != null) {
      return chineseMatch.group(1) ?? 'Medication';
    }
    return 'Medication';
  }

  AiMedicationAction _inferMedicationAction(String lower) {
    if (lower.contains('start') ||
        lower.contains('add') ||
        lower.contains('begin') ||
        lower.contains('启用') ||
        lower.contains('增加')) {
      return AiMedicationAction.add;
    }
    if (lower.contains('stop') ||
        lower.contains('discontinue') ||
        lower.contains('停')) {
      return AiMedicationAction.discontinue;
    }
    return AiMedicationAction.update;
  }

  String? _extractDose(String message) {
    final match =
        RegExp(r'(\d+)\s?mg', caseSensitive: false).firstMatch(message);
    if (match != null) {
      return '${match.group(1)} mg';
    }
    final times = RegExp(r'(\d+)\s*(日|天|次)').firstMatch(message);
    if (times != null) {
      return '${times.group(1)} times/day';
    }
    return null;
  }

  String? _inferEffect(String message) {
    if (message.toLowerCase().contains('sleep')) {
      return 'Improve sleep quality';
    }
    if (message.toLowerCase().contains('anxiety') || message.contains('焦虑')) {
      return 'Ease anxiety symptoms';
    }
    return null;
  }

  String? _inferSideEffects(String message) {
    if (message.toLowerCase().contains('nausea') || message.contains('恶心')) {
      return 'Watch for possible mild nausea';
    }
    if (message.toLowerCase().contains('drowsy') || message.contains('嗜睡')) {
      return 'May cause drowsiness or fatigue';
    }
    return null;
  }
}

/// Coordinates listening lifecycle, permissions, and latest outcomes.
class AiCoConsultCoordinator extends ChangeNotifier {
  AiCoConsultCoordinator._()
      : _sessionController = AiCoConsultSessionController();

  static final AiCoConsultCoordinator instance = AiCoConsultCoordinator._();

  final AiCoConsultSessionController _sessionController;
  final List<Duration> _bookmarks = [];

  AiCoConsultOutcome? _latestOutcome;
  AiCoConsultOutcome? get latestOutcome => _latestOutcome;

  AiCoConsultOutcome? _pendingOutcome;
  AiCoConsultOutcome? get pendingOutcome => _pendingOutcome;

  AiCoConsultSession? _lastSession;
  AiCoConsultSession? get lastSession => _lastSession;

  ConsultReportStatus _reportStatus = ConsultReportStatus.idle;
  ConsultReportStatus get reportStatus => _reportStatus;

  bool get isReportPendingReview =>
      _reportStatus == ConsultReportStatus.reportPendingReview;

  bool get canPatientViewReport =>
      _reportStatus == ConsultReportStatus.reportApproved ||
      _reportStatus == ConsultReportStatus.recordingDeleted;

  bool get hasRecordingDeleted => _lastSession?.recordingDeleted ?? false;

  bool get doctorApproved => _lastSession?.doctorApproved ?? false;

  String? get approvalSignature => _lastSession?.doctorSignature;
  DateTime? get approvalTime => _lastSession?.approvalTime;

  AiCoConsultListeningStatus _status = AiCoConsultListeningStatus.idle;
  AiCoConsultListeningStatus get status => _status;

  bool _hasPermission = true;
  bool get hasPermission => _hasPermission;

  AiConsentRecord? _consentRecord;
  AiConsentRecord? get consentRecord => _consentRecord;
  bool get hasRecordingConsent => _consentRecord?.granted ?? false;

  String? _activeContactName;
  String? get activeContactName => _activeContactName;

  String? _activeConversationId;
  String? get activeConversationId => _activeConversationId;

  DateTime? _pausedAt;
  Duration _pausedAccumulated = Duration.zero;

  AiCoConsultSession? get activeSession => _sessionController.activeSession;

  Duration get activeListeningDuration {
    final session = activeSession;
    if (session == null) return Duration.zero;
    DateTime effectiveEnd;
    if (_status == AiCoConsultListeningStatus.paused && _pausedAt != null) {
      effectiveEnd = _pausedAt!;
    } else if (session.completedAt != null) {
      effectiveEnd = session.completedAt!;
    } else {
      effectiveEnd = DateTime.now();
    }
    final elapsed =
        effectiveEnd.difference(session.startedAt) - _pausedAccumulated;
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  List<AiCoConsultAlert> get activeAlerts => _latestOutcome?.alerts ?? const [];

  bool get canStartSession => hasPermission && hasRecordingConsent;
  List<Duration> get bookmarks => List.unmodifiable(_bookmarks);

  void updatePermission(bool allowed) {
    if (_hasPermission == allowed) return;
    _hasPermission = allowed;
    notifyListeners();
  }

  void updateRecordingConsent(bool consent) {
    final previous = hasRecordingConsent;
    _consentRecord = AiConsentRecord(
      granted: consent,
      recordedAt: DateTime.now(),
      method: 'in-app toggle',
      version: '1.0.0',
      notes: consent ? null : 'Consent revoked by clinician',
    );
    if (previous != consent) {
      notifyListeners();
    }
  }

  AiCoConsultSession? startSession({
    required String conversationId,
    required String contactName,
  }) {
    if (!canStartSession) return null;
    final session = _sessionController.start(
      conversationId: conversationId,
      contactName: contactName,
    );
    _status = AiCoConsultListeningStatus.listening;
    _activeContactName = contactName;
    _activeConversationId = conversationId;
    _pausedAt = null;
    _pausedAccumulated = Duration.zero;
    _latestOutcome = null;
    _pendingOutcome = null;
    _lastSession = null;
    _reportStatus = ConsultReportStatus.idle;
    _bookmarks.clear();
    notifyListeners();
    return session;
  }

  void recordPatientMessage(String message) {
    if (activeSession == null ||
        _status != AiCoConsultListeningStatus.listening) {
      return;
    }
    _sessionController.recordPatientMessage(message);
  }

  void recordClinicianMessage(String message) {
    if (activeSession == null ||
        _status != AiCoConsultListeningStatus.listening) {
      return;
    }
    _sessionController.recordClinicianMessage(message);
  }

  void pauseListening() {
    if (_status != AiCoConsultListeningStatus.listening) {
      return;
    }
    _pausedAt = DateTime.now();
    _status = AiCoConsultListeningStatus.paused;
    notifyListeners();
  }

  void resumeListening() {
    if (_status != AiCoConsultListeningStatus.paused) {
      return;
    }
    if (_pausedAt != null) {
      _pausedAccumulated += DateTime.now().difference(_pausedAt!);
    }
    _pausedAt = null;
    _status = AiCoConsultListeningStatus.listening;
    notifyListeners();
  }

  AiCoConsultOutcome? completeSession() {
    if (activeSession == null) return _latestOutcome;
    try {
      if (_pausedAt != null) {
        _pausedAccumulated += DateTime.now().difference(_pausedAt!);
        _pausedAt = null;
      }
      final session = activeSession;
      final outcome = _sessionController.complete(
        consentRecord: _consentRecord ??
            AiConsentRecord(
              granted: false,
              recordedAt: DateTime.now(),
              method: 'system',
              notes: 'Consent record missing at completion',
            ),
        metadataOverrides: {
          if (_bookmarks.isNotEmpty) 'bookmark_count': '${_bookmarks.length}',
          if (_pausedAccumulated > Duration.zero)
            'paused_seconds': '${_pausedAccumulated.inSeconds}',
        },
      );
      _status = AiCoConsultListeningStatus.completed;
      _pendingOutcome = outcome;
      _lastSession = session;
      _reportStatus = ConsultReportStatus.reportPendingReview;
      session?.reportStatus = ConsultReportStatus.reportPendingReview;
      _consentRecord = outcome.consentRecord;
      _activeContactName = outcome.contactName;
      _activeConversationId = outcome.conversationId;
      _pausedAccumulated = Duration.zero;
      _pausedAt = null;
      _latestOutcome = null;
      notifyListeners();
      return outcome;
    } on StateError {
      return _latestOutcome;
    }
  }

  void resetSessionState() {
    _status = AiCoConsultListeningStatus.idle;
    _activeContactName = null;
    _activeConversationId = null;
    _pausedAt = null;
    _pausedAccumulated = Duration.zero;
    _latestOutcome = null;
    _pendingOutcome = null;
    _lastSession = null;
    _reportStatus = ConsultReportStatus.idle;
    _bookmarks.clear();
    notifyListeners();
  }

  void publish(AiCoConsultOutcome outcome) {
    _pendingOutcome = null;
    _lastSession = null;
    _reportStatus = ConsultReportStatus.reportApproved;
    _latestOutcome = outcome;
    _activeContactName = outcome.contactName;
    _activeConversationId = outcome.conversationId;
    _status = AiCoConsultListeningStatus.completed;
    _consentRecord = outcome.consentRecord;
    _pausedAt = null;
    _pausedAccumulated = Duration.zero;
    _bookmarks.clear();
    notifyListeners();
  }

  AiCoConsultOutcome? approvePendingReport({required String signature}) {
    return markDoctorReviewed(
      approved: true,
      signature: null,
      timestamp: DateTime.now(),
      signatureLabel: signature,
    );
  }

  AiCoConsultOutcome? markDoctorReviewed({
    required bool approved,
    Uint8List? signature,
    required DateTime timestamp,
    String? signatureLabel,
  }) {
    final pending = _pendingOutcome;
    final session = _lastSession;
    if (pending == null || session == null) return null;

    final doctorName = _normalizeDoctorName(session.contactName);
    session.doctorApproved = approved;
    session.approvalTime = timestamp;
    session.doctorSignature = signature != null ? base64Encode(signature) : signatureLabel;
    session.recordingDeleted = true;
    session.reportStatus = ConsultReportStatus.reportApproved;

    final metadata = <String, String>{
      ...pending.metadata,
      'doctor_approved': approved.toString(),
      'approval_time': timestamp.toIso8601String(),
      'doctor_name': doctorName,
      if (signature != null) 'doctor_signature': base64Encode(signature),
      if (signatureLabel != null) 'doctor_signature_text': signatureLabel,
    };

    final finalSummary = _composeDoctorReviewedSummary(
      pending.summary,
      doctorName,
      timestamp,
      signature,
      signatureLabel,
    );

    final finalOutcome = pending.copyWith(
      summary: finalSummary,
      metadata: metadata,
      doctorReviewed: true,
      doctorSignature: signature,
      doctorSignatureLabel: signatureLabel,
      doctorApprovalTime: timestamp,
      doctorName: doctorName,
    );

    _pendingOutcome = null;
    _latestOutcome = finalOutcome;
    _reportStatus = ConsultReportStatus.reportApproved;
    _consentRecord = pending.consentRecord;
    _activeContactName = pending.contactName;
    _activeConversationId = pending.conversationId;
    _pausedAt = null;
    _pausedAccumulated = Duration.zero;
    _bookmarks.clear();
    _publishApprovedSummary(finalOutcome);
    _logRecordingDeletion(session.id, session.conversationId);
    session.transcript.clear();

    notifyListeners();
    return finalOutcome;
  }

  void rejectPendingReport() {
    if (_pendingOutcome == null) return;
    _reportStatus = ConsultReportStatus.reportRejected;
    notifyListeners();
  }

  void _publishApprovedSummary(AiCoConsultOutcome outcome) {
    aiCare_onCoConsultSummary(
      consultId: outcome.sessionId,
      summaryMarkdown: outcome.summary,
      highlights: outcome.planUpdates,
      followUps: outcome.followUpQuestions,
      rawTranscript: '',
      generatedAt: outcome.generatedAt,
    );
  }

  void _logRecordingDeletion(String sessionId, String conversationId) {
    debugPrint(
      'Audio recording deleted for session $sessionId '
      '(conversation $conversationId) at ${DateTime.now().toIso8601String()}',
    );
  }

  String _normalizeDoctorName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Dr. Clinician';
    }
    final trimmed = name.trim();
    if (trimmed.toLowerCase().startsWith('dr.')) {
      return trimmed;
    }
    return 'Dr. $trimmed';
  }

  String _composeDoctorReviewedSummary(
    String baseSummary,
    String doctorName,
    DateTime timestamp,
    Uint8List? signature,
    String? signatureLabel,
  ) {
    final buffer = StringBuffer();
    buffer.writeln(baseSummary.trim());
    buffer.writeln();
    buffer.writeln('Doctor Approval:');
    buffer.writeln('Reviewed and approved by: $doctorName');
    buffer.writeln('Approval time: ${formatDateTime(timestamp)}');
    if (signature != null && _looksLikePng(signature)) {
      final encoded = base64Encode(signature);
      buffer.writeln('Signature:');
      buffer.writeln('![Signature](data:image/png;base64,$encoded)');
    } else if (signatureLabel != null && signatureLabel.trim().isNotEmpty) {
      buffer.writeln('Signature: $signatureLabel');
    }
    return buffer.toString().trim();
  }

  bool _looksLikePng(Uint8List data) {
    const pngHeader = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    if (data.length < pngHeader.length) return false;
    for (var i = 0; i < pngHeader.length; i++) {
      if (data[i] != pngHeader[i]) return false;
    }
    return true;
  }

  bool addBookmark(Duration elapsed) {
    if (_status != AiCoConsultListeningStatus.listening &&
        _status != AiCoConsultListeningStatus.paused) {
      return false;
    }
    final normalized = elapsed.isNegative ? Duration.zero : elapsed;
    _bookmarks.add(normalized);
    notifyListeners();
    return true;
  }
}

/// Utility to convert an AI goal proposal into a [Goal] model.
Goal buildGoalFromProposal(
  AiCoConsultGoalProposal proposal,
) {
  final now = DateUtils.dateOnly(DateTime.now());
  return Goal(
    title: proposal.title,
    instructions: proposal.instructions,
    progress: 0,
    category: proposal.category ?? GoalCategory.custom,
    frequency: proposal.frequency ?? GoalFrequency.weekly,
    timesPerPeriod: max(1, proposal.timesPerPeriod ?? 1),
    startDate: now,
    endDate: now.add(const Duration(days: 60)),
    reminder: const TimeOfDay(hour: 9, minute: 0),
    importance: proposal.importance ?? GoalImportance.medium,
    customCategoryName:
        proposal.category == GoalCategory.custom ? proposal.title : null,
    customCategoryIcon: null,
  );
}

/// Utility to convert a medication change into a [RxMedication] entry.
RxMedication buildMedicationFromChange(
  AiCoConsultMedicationChange change,
) {
  return RxMedication(
    name: change.name,
    dose: change.dose ?? 'Take as directed',
    effect: change.effect ?? 'Follow the latest consult plan',
    sideEffects:
        change.sideEffects ?? 'Contact your clinician if concerns arise',
  );
}
