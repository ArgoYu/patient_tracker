import 'mock_user_profile_api.dart';
import 'user_profile.dart';

/// Holds the in-memory copy of the active user's profile metadata.
class UserProfileStore {
  UserProfileStore._();

  static final UserProfileStore instance = UserProfileStore._();

  UserProfile? _currentProfile;

  UserProfile? get currentProfile => _currentProfile;

  Future<UserProfile> loadProfile(String userId) async {
    final profile = await MockUserProfileApi.instance.fetchProfile(userId);
    _currentProfile = profile;
    return profile;
  }

  Future<UserProfile> markGlobalOnboardingComplete(String userId) async {
    final profile =
        await MockUserProfileApi.instance.markGlobalOnboardingComplete(userId);
    if (_currentProfile?.userId == userId) {
      _currentProfile = profile;
    }
    return profile;
  }

  void clear() {
    _currentProfile = null;
  }
}
