// lib/data/models/vital_entry.dart

/// Captures a single vital measurement entry.
class VitalEntry {
  VitalEntry({
    required this.date,
    required this.systolic,
    required this.diastolic,
    required this.heartRate,
  });

  final DateTime date;
  final int systolic;
  final int diastolic;
  final int heartRate;

  String label() => '$systolic/$diastolic mmHg · HR $heartRate';
}
