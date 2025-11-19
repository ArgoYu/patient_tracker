import 'package:flutter/foundation.dart';

/// Conversation participant.
enum ChatRole { user, ai, system, error }

/// Voice pipeline state machine.
enum VoiceState { idle, holding, processing, speaking, error }

/// Single turn in the transcript.
@immutable
class ChatTurn {
  const ChatTurn({
    required this.role,
    required this.text,
    required this.timestamp,
    this.isStreaming = false,
    this.isError = false,
  });

  final ChatRole role;
  final String text;
  final DateTime timestamp;
  final bool isStreaming;
  final bool isError;

  ChatTurn copyWith({
    ChatRole? role,
    String? text,
    DateTime? timestamp,
    bool? isStreaming,
    bool? isError,
  }) {
    return ChatTurn(
      role: role ?? this.role,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      isError: isError ?? this.isError,
    );
  }
}

/// Message payload used when calling the AI backend.
@immutable
class VoiceMessage {
  const VoiceMessage({
    required this.role,
    required this.content,
  });

  final ChatRole role;
  final String content;
}
