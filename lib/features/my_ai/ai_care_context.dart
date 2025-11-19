class AiCareContext {
  final String consultId;
  final String rawTranscript;
  final String summaryMarkdown;
  final List<String> highlights;
  final List<String> followUps;
  final DateTime generatedAt;

  const AiCareContext({
    required this.consultId,
    required this.summaryMarkdown,
    required this.highlights,
    required this.followUps,
    required this.generatedAt,
    this.rawTranscript = '',
  });

  bool get isEmpty => summaryMarkdown.trim().isEmpty && highlights.isEmpty;
}
