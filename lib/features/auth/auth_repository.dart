import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/prefs_keys.dart';

/// Stubbed auth-facing repository so UI flows can call into a single place.
class AuthRepository {
  AuthRepository._();

  static final AuthRepository instance = AuthRepository._();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (currentPassword.trim().isEmpty || newPassword.trim().isEmpty) {
      throw const AuthRepositoryException(
        'Current and new passwords are required.',
      );
    }
    if (currentPassword.trim() == newPassword.trim()) {
      throw const AuthRepositoryException(
        'Choose a password different from the current one.',
      );
    }
  }

  Future<void> deleteAccount() async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    await signOut();
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.isLoggedIn, false);
    await prefs.remove(PrefsKeys.authToken);
  }

  Future<String?> currentEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefsKeys.authEmail);
  }
}

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);
  final String message;
}
