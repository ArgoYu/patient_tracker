import 'dart:async';

import 'ai_care_bus.dart';
import 'ai_care_context.dart';

/// Called by AI Co-Consult when a summary is generated.
/// Use this instead of touching the Co-Consult code.
// ignore: non_constant_identifier_names
Future<void> aiCare_onCoConsultSummary({
  required String consultId,
  required String summaryMarkdown,
  required List<String> highlights,
  required List<String> followUps,
  String rawTranscript = '',
  DateTime? generatedAt,
}) async {
  final ctx = AiCareContext(
    consultId: consultId,
    summaryMarkdown: summaryMarkdown,
    highlights: highlights,
    followUps: followUps,
    rawTranscript: rawTranscript,
    generatedAt: generatedAt ?? DateTime.now(),
  );
  AiCareBus.I.publish(ctx);
}
