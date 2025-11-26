// lib/data/models/patient_profile.dart

/// Basic patient profile metadata used throughout the app.
class PatientProfile {
  PatientProfile({
    required this.name,
    required this.patientId,
    this.avatarUrl,
    this.notes,
    this.email,
    this.phoneNumber,
  });

  String name;
  final String patientId;
  final String? avatarUrl;
  final String? notes;
  final String? email;
  final String? phoneNumber;

  PatientProfile copyWith({
    String? name,
    String? patientId,
    String? avatarUrl,
    String? notes,
    String? email,
    String? phoneNumber,
  }) {
    return PatientProfile(
      name: name ?? this.name,
      patientId: patientId ?? this.patientId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      notes: notes ?? this.notes,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}
