import '../../shared/language_preferences.dart';

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.legalName,
    this.preferredName,
    required this.preferredLanguage,
    this.pronouns,
    this.timeZone,
    this.dob,
    this.gender,
    this.country,
    this.raceEthnicity,
    this.accessibilityOptions,
    this.accessibilityNotes,
    required this.updatedAt,
  });

  final String userId;
  final String legalName;
  final String? preferredName;
  final String preferredLanguage;
  final String? pronouns;
  final String? timeZone;
  final String? dob;
  final String? gender;
  final String? country;
  final String? raceEthnicity;
  final List<String>? accessibilityOptions;
  final String? accessibilityNotes;
  final DateTime updatedAt;

  UserProfile copyWith({
    String? legalName,
    String? preferredName,
    String? preferredLanguage,
    String? pronouns,
    String? timeZone,
    String? dob,
    String? gender,
    String? country,
    String? raceEthnicity,
    List<String>? accessibilityOptions,
    String? accessibilityNotes,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId,
      legalName: legalName ?? this.legalName,
      preferredName: preferredName ?? this.preferredName,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      pronouns: pronouns ?? this.pronouns,
      timeZone: timeZone ?? this.timeZone,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      country: country ?? this.country,
      raceEthnicity: raceEthnicity ?? this.raceEthnicity,
      accessibilityOptions: accessibilityOptions ?? this.accessibilityOptions,
      accessibilityNotes: accessibilityNotes ?? this.accessibilityNotes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class MockUserApi {
  MockUserApi._();

  static final MockUserApi instance = MockUserApi._();

  final Map<String, UserProfile> _profiles = {};

  Future<UserProfile?> fetchProfile({required String userId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _profiles[userId];
  }

  Future<void> registerProfile({
    required String userId,
    required String legalName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    final existing = _profiles[userId];
    _profiles[userId] = UserProfile(
      userId: userId,
      legalName: legalName.trim(),
      preferredName: existing?.preferredName,
      preferredLanguage: existing?.preferredLanguage ?? LanguagePreferences.fallbackLanguageCode,
      pronouns: existing?.pronouns,
      timeZone: existing?.timeZone,
      dob: existing?.dob,
      gender: existing?.gender,
      country: existing?.country,
      raceEthnicity: existing?.raceEthnicity,
      accessibilityOptions: existing?.accessibilityOptions,
      accessibilityNotes: existing?.accessibilityNotes,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> updateProfile({
    required String userId,
    required String preferredName,
    required String preferredLanguage,
    String? pronouns,
    String? timeZone,
    String? dob,
    String? gender,
    String? country,
    String? raceEthnicity,
    List<String>? accessibilityOptions,
    String? accessibilityNotes,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final existing = _profiles[userId];
    if (existing != null) {
      _profiles[userId] = existing.copyWith(
        preferredName: preferredName.trim(),
        preferredLanguage: preferredLanguage,
        pronouns: pronouns,
        timeZone: timeZone,
        dob: dob,
        gender: gender,
        country: country,
        raceEthnicity: raceEthnicity,
        accessibilityOptions: accessibilityOptions,
        accessibilityNotes: accessibilityNotes,
        updatedAt: DateTime.now(),
      );
    } else {
      _profiles[userId] = UserProfile(
        userId: userId,
        legalName: preferredName.trim(),
        preferredName: preferredName.trim(),
        preferredLanguage: preferredLanguage,
        pronouns: pronouns,
        timeZone: timeZone,
        dob: dob,
        gender: gender,
        country: country,
        raceEthnicity: raceEthnicity,
        accessibilityOptions: accessibilityOptions,
        accessibilityNotes: accessibilityNotes,
        updatedAt: DateTime.now(),
      );
    }
  }
}
