// lib/features/my_ai/services/consultation_notes_source.dart

import '../ai_care_bus.dart';
import '../ai_care_context.dart';
import '../controller/ai_co_consult_service.dart'
    show AiCoConsultCoordinator, AiCoConsultSession;
import '../../../data/models/ai_co_consult_outcome.dart'
    show AiCoConsultOutcome, AiCoConsultSpeaker;

typedef _SessionResolver = AiCoConsultSession? Function();
typedef _OutcomeResolver = AiCoConsultOutcome? Function();
typedef _CareContextResolver = AiCareContext? Function();

/// Pulls the most recent consultation text from local caches or the mock API.
class ConsultationNotesSource {
  ConsultationNotesSource({
    _SessionResolver? sessionResolver,
    _OutcomeResolver? outcomeResolver,
    _CareContextResolver? careContextResolver,
    ConsultationNotesApi? remoteApi,
  })  : _sessionResolver = sessionResolver ??
            (() => AiCoConsultCoordinator.instance.activeSession),
        _outcomeResolver = outcomeResolver ??
            (() => AiCoConsultCoordinator.instance.latestOutcome),
        _careContextResolver =
            careContextResolver ?? (() => AiCareBus.I.latest),
        _remoteApi = remoteApi ?? const ConsultationNotesApi();

  final _SessionResolver _sessionResolver;
  final _OutcomeResolver _outcomeResolver;
  final _CareContextResolver _careContextResolver;
  final ConsultationNotesApi _remoteApi;

  Future<String?> fetchLatestConsultationNotes() async {
    final fromSession = _transcriptFromSession();
    if (_hasText(fromSession)) return fromSession!.trim();

    final outcomeTranscript = _outcomeResolver()?.transcript;
    if (_hasText(outcomeTranscript)) return outcomeTranscript!.trim();

    final context = _careContextResolver();
    if (_hasText(context?.rawTranscript)) return context!.rawTranscript.trim();
    if (_hasText(context?.summaryMarkdown)) {
      return context!.summaryMarkdown.trim();
    }

    final fallback = await _remoteApi.fetchFallbackNotes();
    if (_hasText(fallback)) return fallback!.trim();
    return null;
  }

  String? _transcriptFromSession() {
    final session = _sessionResolver();
    if (session == null || session.transcript.isEmpty) return null;

    final buffer = StringBuffer();
    for (final utterance in session.transcript) {
      final speaker = utterance.speaker == AiCoConsultSpeaker.clinician
          ? 'Clinician'
          : 'Patient';
      buffer.writeln('$speaker: ${utterance.message}');
    }
    return buffer.toString();
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
}

/// Simulates a remote consultation notes API.
class ConsultationNotesApi {
  const ConsultationNotesApi();

  Future<String?> fetchFallbackNotes() async {
    await Future.delayed(const Duration(milliseconds: 320));
    return '''
Clinician: Patient reported disrupted sleep, increased use of rescue inhaler.
Patient: Mentioned heightened stress caring for a family member.
Clinician: Adjusted evening medication timing and suggested CBT homework.
Patient: Agreed to log symptom changes and notify if chest tightness increases.
Clinician: Scheduled pulmonary follow-up for two weeks out.
''';
  }
}

Future<String?> fetchLatestConsultationNotes() {
  return ConsultationNotesSource().fetchLatestConsultationNotes();
}
