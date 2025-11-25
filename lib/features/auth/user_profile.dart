/// Represents the subset of user metadata we currently track.
class UserProfile {
  const UserProfile({
    required this.userId,
    this.hasCompletedGlobalOnboarding = false,
  });

  final String userId;
  final bool hasCompletedGlobalOnboarding;

  UserProfile copyWith({
    bool? hasCompletedGlobalOnboarding,
  }) {
    return UserProfile(
      userId: userId,
      hasCompletedGlobalOnboarding:
          hasCompletedGlobalOnboarding ?? this.hasCompletedGlobalOnboarding,
    );
  }
}
