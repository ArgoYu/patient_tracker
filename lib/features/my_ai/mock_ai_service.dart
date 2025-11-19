import 'dart:async';

/// Provides sample responses that emulate asynchronous AI calls.
class MockAiService {
  const MockAiService();

  Future<Map<String, String>> fetchHubSummaries() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const {
      'coConsult': 'Collaborate with AI specialists on complex cases.',
      'reportGenerator': 'Generate on-demand summaries and patient reports.',
      'askAiDoctor': 'Get instant answers to medical questions.',
      'timelinePlanner': 'Plan treatment milestones with AI suggestions.',
    };
  }

  Future<List<String>> fetchAdvancedHighlights() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      'Voice Chat AI is ready to assist with spoken conversations.',
      'Multi-language support helps reach more patients.',
      'Risk alerts surface potential complications early.',
    ];
  }
}
