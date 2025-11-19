import 'dart:async';

import '../models/voice_chat_models.dart';

/// Contract for future AI streaming implementations.
abstract class VoiceAiService {
  const VoiceAiService();

  Future<Stream<String>> chatStream(
    List<VoiceMessage> history,
    String userText,
  );
}

/// Mock streaming service that emits faux tokens word-by-word.
class MockVoiceAiService extends VoiceAiService {
  const MockVoiceAiService({
    this.latency = const Duration(milliseconds: 280),
  });

  final Duration latency;

  static const List<String> _fallbackReplies = [
    'Sure, let me walk you through a calming breathing exercise.',
    'I can summarize your latest consultation and highlight risks.',
    'Here is a quick plan to stay on track this week.',
  ];

  @override
  Future<Stream<String>> chatStream(
    List<VoiceMessage> history,
    String userText,
  ) async {
    final controller = StreamController<String>();
    final reply = _buildReply(history, userText);
    final tokens = reply.split(' ');
    Future<void>.delayed(latency, () async {
      for (final token in tokens) {
        controller.add('$token ');
        await Future<void>.delayed(latency);
      }
      await controller.close();
    });
    return controller.stream;
  }

  String _buildReply(List<VoiceMessage> history, String userText) {
    if (userText.trim().isEmpty) {
      return _fallbackReplies.first;
    }
    if (history.isEmpty) {
      return 'Hi there! ${_fallbackReplies[0]}';
    }
    final lastUser = history.lastWhere(
      (m) => m.role == ChatRole.user,
      orElse: () => VoiceMessage(role: ChatRole.user, content: userText),
    );
    return 'You said "${lastUser.content.trim()}". '
        'Based on your recent history I recommend a short reflection break. '
        'When you are ready, ask for hands-free guidance again.';
  }
}
