class UserProfile {
  const UserProfile({
    required this.userId,
    required this.preferredName,
    required this.preferredLanguage,
    this.pronouns,
    this.timeZone,
    required this.updatedAt,
  });

  final String userId;
  final String preferredName;
  final String preferredLanguage;
  final String? pronouns;
  final String? timeZone;
  final DateTime updatedAt;
}

class MockUserApi {
  MockUserApi._();

  static final MockUserApi instance = MockUserApi._();

  final Map<String, UserProfile> _profiles = {};

  Future<UserProfile?> fetchProfile({required String userId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _profiles[userId];
  }

  Future<void> updateProfile({
    required String userId,
    required String preferredName,
    required String preferredLanguage,
    String? pronouns,
    String? timeZone,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    _profiles[userId] = UserProfile(
      userId: userId,
      preferredName: preferredName,
      preferredLanguage: preferredLanguage,
      pronouns: pronouns,
      timeZone: timeZone,
      updatedAt: DateTime.now(),
    );
  }
}
