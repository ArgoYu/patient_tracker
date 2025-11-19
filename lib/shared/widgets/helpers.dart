
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:patient_tracker/features/my_ai/ai_co_consult_coordinator.dart';

class AiTextStyles {
  static TextStyle title16(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!;
  }

  static TextStyle body13(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!;
  }
}

class AiDesignTokens {
  static const double pagePadding = 16.0;
}

Color? recColor(AiCoConsultListeningStatus status, bool canStart, bool hasConsent, BuildContext context) {
  if (status == AiCoConsultListeningStatus.listening) {
    return CupertinoColors.systemRed.resolveFrom(context);
  }
  if (status == AiCoConsultListeningStatus.completed) {
    return CupertinoColors.systemRed.resolveFrom(context);
  }
  if (status == AiCoConsultListeningStatus.idle && !(canStart && hasConsent)) {
    return CupertinoColors.systemGrey4.resolveFrom(context);
  }
  return CupertinoColors.systemRed.resolveFrom(context);
}

IconData recIcon(AiCoConsultListeningStatus status) {
  switch (status) {
    case AiCoConsultListeningStatus.listening:
      return Icons.pause;
    case AiCoConsultListeningStatus.paused:
    case AiCoConsultListeningStatus.idle:
      return Icons.fiber_manual_record;
    case AiCoConsultListeningStatus.completed:
      return Icons.stop;
  }
}

String formatDateTime(DateTime dateTime) {
  return DateFormat.yMMMd().add_jm().format(dateTime);
}
