import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/voice_chat_models.dart';
import 'voice_typing_indicator.dart';

class VoiceChatBubble extends StatefulWidget {
  const VoiceChatBubble({super.key, required this.turn});

  final ChatTurn turn;

  @override
  State<VoiceChatBubble> createState() => _VoiceChatBubbleState();
}

class _VoiceChatBubbleState extends State<VoiceChatBubble>
    with AutomaticKeepAliveClientMixin {
  bool get _isUser => widget.turn.role == ChatRole.user;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final timestamp = DateFormat.jm().format(widget.turn.timestamp);
    final bubbleColor = _isUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = _isUser
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(_isUser ? 20 : 4),
      bottomRight: Radius.circular(_isUser ? 4 : 20),
    );

    return Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.turn.isError
                ? theme.colorScheme.errorContainer
                : bubbleColor,
            borderRadius: borderRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment:
                  _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timestamp,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _dimmed(textColor, 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                if (widget.turn.isStreaming)
                  VoiceTypingIndicator(
                    color: textColor,
                  )
                else
                  Text(
                    widget.turn.text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: widget.turn.isError
                          ? theme.colorScheme.onErrorContainer
                          : textColor,
                    ),
                  ),
                if (widget.turn.isStreaming) const SizedBox(height: 6),
                if (!widget.turn.isStreaming)
                  AnimatedOpacity(
                    opacity: widget.turn.isError ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      'Tap the mic to retry',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _dimmed(Color color, double opacity) {
  final alpha = (color.a * opacity).clamp(0.0, 1.0);
  return color.withValues(alpha: alpha);
}
