
import 'dart:convert';
import 'dart:typed_data';

import 'goal.dart';

/// Identifies which party spoke in the consult.
enum AiCoConsultSpeaker { patient, clinician }

/// Represents a single item on the follow-up timeline.
class TimelineItem {
  TimelineItem({
    required this.when,
    required this.title,
    required this.detail,
    this.code,
    this.category,
  });

  final DateTime when;
  final String title;   // e.g., "Follow-up Visit"
  final String detail;  // e.g., "Schedule tele-visit within 2 weeks"
  final String? code;   // optional Rx/order code
  final String? category;
}

/// Transcript snippet with optional timing metadata.
class AiCoConsultTranscriptSegment {
  const AiCoConsultTranscriptSegment({
    required this.speaker,
    required this.text,
    required this.startedAt,
    required this.endedAt,
  });

  final AiCoConsultSpeaker speaker;
  final String text;
  final DateTime startedAt;
  final DateTime endedAt;
}

/// Categorises how a medication entry should be updated.
enum AiMedicationAction { add, update, discontinue }

/// Captures an AI-derived medication recommendation.
class AiCoConsultMedicationChange {
  const AiCoConsultMedicationChange({
    required this.name,
    required this.action,
    this.dose,
    this.effect,
    this.sideEffects,
  });

  final String name;
  final AiMedicationAction action;
  final String? dose;
  final String? effect;
  final String? sideEffects;
}

/// Indicates severity classification for an AI alert.
enum AiCoConsultAlertSeverity { high, medium, low }

/// Represents a smart alert surfaced during a session.
class AiCoConsultAlert {
  const AiCoConsultAlert({
    required this.severity,
    required this.title,
    this.detail,
  });

  final AiCoConsultAlertSeverity severity;
  final String title;
  final String? detail;
}

/// Captures an AI-derived goal suggestion.
class AiCoConsultGoalProposal {
  const AiCoConsultGoalProposal({
    required this.title,
    this.instructions,
    this.category,
    this.frequency,
    this.timesPerPeriod,
    this.importance,
  });

  final String title;
  final String? instructions;
  final GoalCategory? category;
  final GoalFrequency? frequency;
  final int? timesPerPeriod;
  final GoalImportance? importance;
}

/// Persisted record of how consent was collected prior to recording.
class AiConsentRecord {
  const AiConsentRecord({
    required this.granted,
    required this.recordedAt,
    required this.method,
    this.version,
    this.notes,
  });

  final bool granted;
  final DateTime recordedAt;
  final String method;
  final String? version;
  final String? notes;
}

/// Container for all derived insights from an AI Co-Consult session.
class AiCoConsultOutcome {
  AiCoConsultOutcome({
    required this.sessionId,
    required this.conversationId,
    required this.contactName,
    required this.startedAt,
    required this.completedAt,
    required this.generatedAt,
    required this.summary,
    required this.chiefComplaint,
    required this.historySummary,
    required this.diagnosisSummary,
    required this.recommendations,
    required this.transcript,
    required this.transcriptSegments,
    required this.timeline,
    required this.followUpQuestions,
    required this.planUpdates,
    required this.goalProposals,
    required this.medicationChanges,
    required this.alerts,
    required this.consentRecord,
    required this.metadata,
    this.doctorReviewed = false,
    this.doctorSignature,
    this.doctorSignatureLabel,
    this.doctorApprovalTime,
    this.doctorName,
  });

  final String sessionId;
  final String conversationId;
  final String contactName;
  final DateTime startedAt;
  final DateTime completedAt;
  final DateTime generatedAt;

  final String summary;
  final String chiefComplaint;
  final String historySummary;
  final String diagnosisSummary;
  final String recommendations;

  final String transcript;
  final List<AiCoConsultTranscriptSegment> transcriptSegments;

  final List<TimelineItem> timeline;
  final List<String> followUpQuestions;
  final List<String> planUpdates;
  final List<AiCoConsultGoalProposal> goalProposals;
  final List<AiCoConsultMedicationChange> medicationChanges;
  final List<AiCoConsultAlert> alerts;

  final AiConsentRecord consentRecord;
  final Map<String, String> metadata;
  final bool doctorReviewed;
  final Uint8List? doctorSignature;
  final String? doctorSignatureLabel;
  final DateTime? doctorApprovalTime;
  final String? doctorName;

  bool get hasAlerts => alerts.isNotEmpty;

  AiCoConsultOutcome copyWith({
    String? summary,
    String? chiefComplaint,
    String? historySummary,
    String? diagnosisSummary,
    String? recommendations,
    String? transcript,
    List<AiCoConsultTranscriptSegment>? transcriptSegments,
    List<TimelineItem>? timeline,
    List<String>? followUpQuestions,
    List<String>? planUpdates,
    List<AiCoConsultGoalProposal>? goalProposals,
    List<AiCoConsultMedicationChange>? medicationChanges,
    List<AiCoConsultAlert>? alerts,
    AiConsentRecord? consentRecord,
    Map<String, String>? metadata,
    bool? doctorReviewed,
    Uint8List? doctorSignature,
    String? doctorSignatureLabel,
    DateTime? doctorApprovalTime,
    String? doctorName,
  }) {
    return AiCoConsultOutcome(
      sessionId: sessionId,
      conversationId: conversationId,
      contactName: contactName,
      startedAt: startedAt,
      completedAt: completedAt,
      generatedAt: generatedAt,
      summary: summary ?? this.summary,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      historySummary: historySummary ?? this.historySummary,
      diagnosisSummary: diagnosisSummary ?? this.diagnosisSummary,
      recommendations: recommendations ?? this.recommendations,
      transcript: transcript ?? this.transcript,
      transcriptSegments:
          transcriptSegments ?? List<AiCoConsultTranscriptSegment>.from(this.transcriptSegments),
      timeline: timeline ?? List<TimelineItem>.from(this.timeline),
      followUpQuestions:
          followUpQuestions ?? List<String>.from(this.followUpQuestions),
      planUpdates: planUpdates ?? List<String>.from(this.planUpdates),
      goalProposals:
          goalProposals ?? List<AiCoConsultGoalProposal>.from(this.goalProposals),
      medicationChanges: medicationChanges ??
          List<AiCoConsultMedicationChange>.from(this.medicationChanges),
      alerts: alerts ?? List<AiCoConsultAlert>.from(this.alerts),
      consentRecord: consentRecord ?? this.consentRecord,
      metadata: metadata ?? Map<String, String>.from(this.metadata),
      doctorReviewed: doctorReviewed ?? this.doctorReviewed,
      doctorSignature: doctorSignature ?? this.doctorSignature,
      doctorSignatureLabel: doctorSignatureLabel ?? this.doctorSignatureLabel,
      doctorApprovalTime: doctorApprovalTime ?? this.doctorApprovalTime,
      doctorName: doctorName ?? this.doctorName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'conversationId': conversationId,
      'contactName': contactName,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
      'generatedAt': generatedAt.toIso8601String(),
      'summary': summary,
      'chiefComplaint': chiefComplaint,
      'historySummary': historySummary,
      'diagnosisSummary': diagnosisSummary,
      'recommendations': recommendations,
      'transcript': transcript,
      'transcriptSegments': transcriptSegments
          .map(
            (segment) => {
              'speaker': segment.speaker.name,
              'text': segment.text,
              'startedAt': segment.startedAt.toIso8601String(),
              'endedAt': segment.endedAt.toIso8601String(),
            },
          )
          .toList(),
      'timeline': timeline
          .map(
            (item) => {
              'when': item.when.toIso8601String(),
              'title': item.title,
              'detail': item.detail,
              'code': item.code,
              'category': item.category,
            },
          )
          .toList(),
      'followUpQuestions': followUpQuestions,
      'planUpdates': planUpdates,
      'goalProposals': goalProposals
          .map(
            (proposal) => {
              'title': proposal.title,
              'instructions': proposal.instructions,
              'category': proposal.category?.name,
              'frequency': proposal.frequency?.name,
              'timesPerPeriod': proposal.timesPerPeriod,
              'importance': proposal.importance?.name,
            },
          )
          .toList(),
      'medicationChanges': medicationChanges
          .map(
            (change) => {
              'name': change.name,
              'action': change.action.name,
              'dose': change.dose,
              'effect': change.effect,
              'sideEffects': change.sideEffects,
            },
          )
          .toList(),
      'alerts': alerts
          .map(
            (alert) => {
              'severity': alert.severity.name,
              'title': alert.title,
              'detail': alert.detail,
            },
          )
          .toList(),
      'consentRecord': {
        'granted': consentRecord.granted,
        'recordedAt': consentRecord.recordedAt.toIso8601String(),
        'method': consentRecord.method,
        'version': consentRecord.version,
        'notes': consentRecord.notes,
      },
      'metadata': metadata,
      'doctorReviewed': doctorReviewed,
      if (doctorSignature != null)
        'doctorSignature': base64Encode(doctorSignature!),
      if (doctorSignatureLabel != null)
        'doctorSignatureLabel': doctorSignatureLabel,
      if (doctorApprovalTime != null)
        'doctorApprovalTime': doctorApprovalTime!.toIso8601String(),
      if (doctorName != null) 'doctorName': doctorName,
    };
  }

  @override
  String toString() {
    return 'AiCoConsultOutcome(sessionId: $sessionId, summary: ${summary.length} chars, timeline: ${timeline.length} items)';
  }
}
