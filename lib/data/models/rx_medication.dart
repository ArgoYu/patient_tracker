// lib/data/models/rx_medication.dart

enum MedTimeSlot { morning, noon, afternoon, evening, bedtime }

enum MedIntakeStatus { taken, skipped }

class MedIntakeLog {
  const MedIntakeLog({
    required this.medId,
    required this.takenAt,
    this.slot,
    this.status = MedIntakeStatus.taken,
  });

  final String medId;
  final DateTime takenAt;
  final MedTimeSlot? slot;
  final MedIntakeStatus status;
}

DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

extension MedTimeSlotLabel on MedTimeSlot {
  int get order {
    switch (this) {
      case MedTimeSlot.morning:
        return 0;
      case MedTimeSlot.noon:
        return 1;
      case MedTimeSlot.afternoon:
        return 2;
      case MedTimeSlot.evening:
        return 3;
      case MedTimeSlot.bedtime:
        return 4;
    }
  }

  String get label {
    switch (this) {
      case MedTimeSlot.morning:
        return 'morning';
      case MedTimeSlot.noon:
        return 'noon';
      case MedTimeSlot.afternoon:
        return 'afternoon';
      case MedTimeSlot.evening:
        return 'evening';
      case MedTimeSlot.bedtime:
        return 'bedtime';
    }
  }
}

String _defaultMedId(String name) {
  final cleaned = name.toLowerCase().trim();
  final slug = cleaned.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return slug.replaceAll(RegExp(r'^-+|-+$'), '');
}

/// Medication entry with tracking metadata for intake logging.
class RxMedication {
  RxMedication({
    String? id,
    required this.name,
    required this.dose,
    required this.effect,
    required this.sideEffects,
    List<DateTime>? intakeLog,
    List<MedIntakeLog>? intakeLogs,
    List<MedTimeSlot>? timesOfDay,
    bool? isActive,
  })  : id = id ?? _defaultMedId(name),
        intakeLog = intakeLog ?? <DateTime>[],
        timesOfDay = timesOfDay ?? <MedTimeSlot>[],
        isActive = isActive ?? true,
        intakeLogs = intakeLogs ??
            (intakeLog ?? const <DateTime>[])
                .map(
                  (entry) => MedIntakeLog(
                    medId: id ?? _defaultMedId(name),
                    takenAt: entry,
                  ),
                )
                .toList();

  final String id;
  final String name;
  final String dose;
  final String effect;
  final String sideEffects;
  final List<DateTime> intakeLog;
  final List<MedIntakeLog> intakeLogs;
  final List<MedTimeSlot> timesOfDay;
  final bool isActive;

  String get doseDisplay => dose;
}
