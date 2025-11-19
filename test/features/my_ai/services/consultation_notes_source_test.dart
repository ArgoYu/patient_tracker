import 'package:flutter_test/flutter_test.dart';
import 'package:patient_tracker/data/models/ai_co_consult_outcome.dart';
import 'package:patient_tracker/features/my_ai/ai_care_context.dart';
import 'package:patient_tracker/features/my_ai/controller/ai_co_consult_service.dart';
import 'package:patient_tracker/features/my_ai/services/consultation_notes_source.dart';

void main() {
  group('ConsultationNotesSource', () {
    test('returns transcript from active session when available', () async {
      final session = AiCoConsultSession(
        id: 'session-1',
        conversationId: 'conv-1',
        contactName: 'Dr. Chen',
        startedAt: DateTime.now(),
      )..record(AiCoConsultSpeaker.clinician, 'Missed dose yesterday',
          DateTime.now());

      final source = ConsultationNotesSource(
        sessionResolver: () => session,
        outcomeResolver: () => null,
        careContextResolver: () => null,
        remoteApi: const _StubNotesApi(null),
      );

      final notes = await source.fetchLatestConsultationNotes();
      expect(notes, isNotNull);
      expect(notes!, contains('Clinician: Missed dose yesterday'));
    });

    test('falls back to latest outcome transcript', () async {
      final outcome = _buildOutcome(transcript: 'Outcome transcript sample');
      final source = ConsultationNotesSource(
        sessionResolver: () => null,
        outcomeResolver: () => outcome,
        careContextResolver: () => null,
        remoteApi: const _StubNotesApi(null),
      );

      final notes = await source.fetchLatestConsultationNotes();
      expect(notes, 'Outcome transcript sample');
    });

    test('falls back to care context then remote', () async {
      final context = AiCareContext(
        consultId: 'ctx',
        summaryMarkdown: '',
        highlights: const [],
        followUps: const [],
        generatedAt: DateTime.now(),
        rawTranscript: 'Context transcript',
      );
      final source = ConsultationNotesSource(
        sessionResolver: () => null,
        outcomeResolver: () => null,
        careContextResolver: () => context,
        remoteApi: const _StubNotesApi(null),
      );

      expect(await source.fetchLatestConsultationNotes(), 'Context transcript');

      final remoteSource = ConsultationNotesSource(
        sessionResolver: () => null,
        outcomeResolver: () => null,
        careContextResolver: () => null,
        remoteApi: const _StubNotesApi('Remote notes'),
      );
      expect(await remoteSource.fetchLatestConsultationNotes(), 'Remote notes');
    });

    test('returns null when every source is empty', () async {
      final source = ConsultationNotesSource(
        sessionResolver: () => null,
        outcomeResolver: () => null,
        careContextResolver: () => null,
        remoteApi: const _StubNotesApi(null),
      );

      expect(await source.fetchLatestConsultationNotes(), isNull);
    });

    test('propagates errors from remote API', () async {
      final source = ConsultationNotesSource(
        sessionResolver: () => null,
        outcomeResolver: () => null,
        careContextResolver: () => null,
        remoteApi: const _StubNotesApi(null, shouldThrow: true),
      );

      expect(
        () => source.fetchLatestConsultationNotes(),
        throwsA(isA<Exception>()),
      );
    });
  });
}

class _StubNotesApi extends ConsultationNotesApi {
  const _StubNotesApi(this.value, {this.shouldThrow = false});
  final String? value;
  final bool shouldThrow;

  @override
  Future<String?> fetchFallbackNotes() async {
    if (shouldThrow) throw Exception('network');
    return value;
  }
}

AiCoConsultOutcome _buildOutcome({required String transcript}) {
  final now = DateTime.now();
  return AiCoConsultOutcome(
    sessionId: 'session',
    conversationId: 'conversation',
    contactName: 'Dr. Smith',
    startedAt: now.subtract(const Duration(minutes: 30)),
    completedAt: now.subtract(const Duration(minutes: 5)),
    generatedAt: now,
    summary: 'Summary',
    chiefComplaint: 'Chief',
    historySummary: 'History',
    diagnosisSummary: 'Diagnosis',
    recommendations: 'Recommendations',
    transcript: transcript,
    transcriptSegments: const [],
    timeline: const [],
    followUpQuestions: const [],
    planUpdates: const [],
    goalProposals: const [],
    medicationChanges: const [],
    alerts: const [],
    consentRecord: AiConsentRecord(
      granted: true,
      recordedAt: now,
      method: 'test',
    ),
    metadata: const {},
  );
}
