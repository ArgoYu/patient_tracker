/// Central place for SharedPreferences keys used across the app.
class PrefsKeys {
  const PrefsKeys._();

  static const onboardingCompleted = 'onboarding_completed';
  static const onboardingVersion = 'onboarding_version';

  static const isLoggedIn = 'is_logged_in';
  static const authToken = 'auth_token';
  static const authEmail = 'auth_email';
  static const emailVerified = 'email_verified';
  static const preferredLanguageCode = 'preferred_language_code';
  static const preferredTimeZone = 'preferred_time_zone';
}
