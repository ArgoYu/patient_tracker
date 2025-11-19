// lib/data/models/rx_medication.dart

/// Medication entry with tracking metadata for intake logging.
class RxMedication {
  RxMedication({
    required this.name,
    required this.dose,
    required this.effect,
    required this.sideEffects,
    List<DateTime>? intakeLog,
  }) : intakeLog = intakeLog ?? <DateTime>[];

  final String name;
  final String dose;
  final String effect;
  final String sideEffects;
  final List<DateTime> intakeLog;
}
