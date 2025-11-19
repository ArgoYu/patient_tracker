// lib/data/models/patient_profile.dart

/// Basic patient profile metadata used throughout the app.
class PatientProfile {
  PatientProfile({
    required this.name,
    required this.patientId,
    this.avatarUrl,
    this.notes,
  });

  final String name;
  final String patientId;
  final String? avatarUrl;
  final String? notes;
}
