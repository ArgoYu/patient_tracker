// lib/data/models/lab_result.dart

/// Represents a lab result with its value and metadata.
class LabResult {
  LabResult({
    required this.name,
    required this.value,
    required this.unit,
    required this.collectedOn,
    this.notes,
  });

  final String name;
  final String value;
  final String unit;
  final DateTime collectedOn;
  final String? notes;

  String valueWithUnit() => unit.trim().isEmpty ? value : '$value $unit';
}
