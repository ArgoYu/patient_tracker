import 'dart:async';

import 'user_profile.dart';

/// Simple in-memory representation of user metadata within the demo backend.
class MockUserProfileApi {
  MockUserProfileApi._();

  static final MockUserProfileApi instance = MockUserProfileApi._();

  final Map<String, UserProfile> _profiles = {};

  /// Returns the profile for [userId], creating a fresh entry if needed.
  Future<UserProfile> fetchProfile(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return _profiles.putIfAbsent(
      userId,
      () => UserProfile(userId: userId),
    );
  }

  /// Marks the onboarding flag as completed for the given user.
  Future<UserProfile> markGlobalOnboardingComplete(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final existing = await fetchProfile(userId);
    final updated = existing.copyWith(hasCompletedGlobalOnboarding: true);
    _profiles[userId] = updated;
    return updated;
  }

  /// Ensures a profile exists for a newly registered user and resets
  /// the onboarding flag so they see the flow once.
  Future<void> registerUser(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    _profiles[userId] = UserProfile(userId: userId);
  }
}
