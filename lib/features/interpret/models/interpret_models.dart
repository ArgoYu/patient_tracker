// lib/features/interpret/models/interpret_models.dart
import 'package:flutter/material.dart';

/// High level states for the interpreter pipeline.
enum InterpState {
  idle,
  listening,
  translating,
  speaking,
  paused,
  error,
}

extension InterpStateX on InterpState {
  bool get isActive =>
      this == InterpState.listening ||
      this == InterpState.translating ||
      this == InterpState.speaking;

  String get label => switch (this) {
        InterpState.idle => 'Idle',
        InterpState.listening => 'Listening',
        InterpState.translating => 'Translating',
        InterpState.speaking => 'Speaking',
        InterpState.paused => 'Paused',
        InterpState.error => 'Error',
      };
}

/// Represents a caption row either for the speaker or listener.
class Segment {
  Segment({
    required this.text,
    required this.ts,
    this.isFinal = false,
  });

  String text;
  bool isFinal;
  final DateTime ts;

  Segment copyWith({String? text, bool? isFinal}) => Segment(
        text: text ?? this.text,
        ts: ts,
        isFinal: isFinal ?? this.isFinal,
      );
}

/// Export formats supported by the session saver.
enum InterpretExportFormat {
  txt('txt'),
  srt('srt');

  const InterpretExportFormat(this.extension);
  final String extension;
}

/// Simple mapping from BCP-47 codes to human friendly names.
String describeLanguage(String code) {
  const lookup = <String, String>{
    'en-US': 'English (US)',
    'en-GB': 'English (UK)',
    'es-ES': 'Spanish',
    'es-MX': 'Spanish (LatAm)',
    'fr-FR': 'French',
    'de-DE': 'German',
    'pt-BR': 'Portuguese (BR)',
    'ja-JP': 'Japanese',
    'ko-KR': 'Korean',
    'zh-CN': 'Chinese (Simplified)',
    'zh-TW': 'Chinese (Traditional)',
  };
  return lookup[code] ?? code;
}

/// Visual tokens for caption badges.
class CaptionBadge extends StatelessWidget {
  const CaptionBadge({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color ?? scheme.secondaryContainer,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSecondaryContainer),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: scheme.onSecondaryContainer),
          ),
        ],
      ),
    );
  }
}
