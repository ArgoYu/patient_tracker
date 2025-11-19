// lib/data/models/next_visit.dart

/// Details about the next scheduled visit for the patient.
class NextVisit {
  NextVisit({
    required this.title,
    required this.when,
    required this.location,
    required this.doctor,
    this.mode = 'Online',
    this.notes,
  });

  final String title;
  final DateTime when;
  final String location;
  final String doctor;
  final String mode;
  final String? notes;
}
