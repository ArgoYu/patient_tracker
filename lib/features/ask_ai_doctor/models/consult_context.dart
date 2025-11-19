import '../../my_ai/ai_care_context.dart';

/// Lightweight projection of the latest consult for Ask-AI-Doctor.
class ConsultContext {
  const ConsultContext({
    required this.consultId,
    required this.summary,
    required this.highlights,
    required this.generatedAt,
  });

  final String consultId;
  final String summary;
  final List<String> highlights;
  final DateTime generatedAt;

  bool get hasContent =>
      summary.trim().isNotEmpty || highlights.any((h) => h.trim().isNotEmpty);

  static final empty = ConsultContext(
    consultId: '',
    summary: '',
    highlights: <String>[],
    generatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  factory ConsultContext.fromAiCare(AiCareContext ctx) {
    return ConsultContext(
      consultId: ctx.consultId,
      summary: ctx.summaryMarkdown,
      highlights: ctx.highlights,
      generatedAt: ctx.generatedAt,
    );
  }
}
