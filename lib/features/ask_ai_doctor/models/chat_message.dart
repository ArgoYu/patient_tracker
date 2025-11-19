/// Represents a single utterance within the Ask-AI-Doctor chat.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    required this.createdAt,
    this.meta,
  });

  final String id;
  final bool isUser;
  final String text;
  final DateTime createdAt;
  final Map<String, dynamic>? meta;

  ChatMessage copyWith({
    String? text,
    Map<String, dynamic>? meta,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id,
      isUser: isUser,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      meta: meta ?? this.meta,
    );
  }
}

/// Groups a set of messages for persistence when threads are introduced.
class ChatThread {
  const ChatThread({required this.threadId, required this.messages});

  final String threadId;
  final List<ChatMessage> messages;

  ChatThread copyWith({List<ChatMessage>? messages}) {
    return ChatThread(
      threadId: threadId,
      messages: messages ?? this.messages,
    );
  }
}
