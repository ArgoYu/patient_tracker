import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'demo_credentials.dart';

enum TwoFactorMethod {
  sms,
  phoneCall,
  googleDuo,
}

/// Represents the data needed to continue a pending two-factor verification.
class PendingTwoFactorSession {
  PendingTwoFactorSession({
    required this.email,
    required this.userId,
    required this.token,
    required this.refreshToken,
    required this.rememberMe,
    required this.availableMethods,
  });

  final String email;
  final String userId;
  final String token;
  final String refreshToken;
  final bool rememberMe;
  final List<TwoFactorMethod> availableMethods;
}

/// Holds the authenticated session details.
class AuthSession {
  AuthSession({
    required this.userId,
    required this.token,
    required this.refreshToken,
    required this.rememberMe,
  });

  final String userId;
  final String token;
  final String refreshToken;
  final bool rememberMe;
}

/// Result returned when attempting to log in.
class AuthLoginResult {
  AuthLoginResult({
    required this.userId,
    required this.token,
    required this.refreshToken,
    required this.requiresTwoFactor,
    required this.availableMethods,
  });

  final String userId;
  final String token;
  final String refreshToken;
  final bool requiresTwoFactor;
  final List<TwoFactorMethod> availableMethods;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}

/// Handles authentication, secure persistence, and two-factor interactions.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Random _random = Random();

  PendingTwoFactorSession? _pendingSession;
  String? _pendingCode;
  AuthSession? _currentSession;

  static const _tokenKey = 'auth_token';
  static const _refreshKey = 'refresh_token';
  static const _userIdKey = 'auth_user_id';
  static const _expiryKey = 'auth_token_expiry';
  static const _rememberMeKey = 'remember_me';

  bool get isAuthenticated => _currentSession != null;

  PendingTwoFactorSession? get pendingTwoFactorSession => _pendingSession;

  /// Attempts to authenticate with the provided credentials.
  Future<AuthLoginResult> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (email.isEmpty || password.isEmpty) {
      throw const AuthException('Email and password are required.');
    }

    final userId = 'user-${email.hashCode}';
    final token = 'token-${DateTime.now().millisecondsSinceEpoch}';
    final refreshToken = 'refresh-${email.hashCode}-${_random.nextInt(9999)}';
    final requiresTwoFactor = !isDemoAccount(email: email, password: password);
    const methods = TwoFactorMethod.values;

    if (requiresTwoFactor) {
      _pendingCode = _generateCode();
      _pendingSession = PendingTwoFactorSession(
        email: email,
        userId: userId,
        token: token,
        refreshToken: refreshToken,
        rememberMe: rememberMe,
        availableMethods: methods,
      );
      if (kDebugMode) {
        debugPrint('2FA code for $email: $_pendingCode');
      }
      return AuthLoginResult(
        userId: userId,
        token: token,
        refreshToken: refreshToken,
        requiresTwoFactor: true,
        availableMethods: methods,
      );
    }
    final session = AuthSession(
      userId: userId,
      token: token,
      refreshToken: refreshToken,
      rememberMe: rememberMe,
    );
    _currentSession = session;
    // Persist the session if the user asked to be remembered.
    if (rememberMe) {
      await _persistSession(session);
    }
    return AuthLoginResult(
      userId: userId,
      token: token,
      refreshToken: refreshToken,
      requiresTwoFactor: false,
      availableMethods: methods,
    );
  }

  /// Generates or resends a 2FA code via the selected [method].
  Future<void> requestTwoFactorCode(TwoFactorMethod method) async {
    final pending = _pendingSession;
    if (pending == null) {
      throw const AuthException('No pending verification available.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 360));
    _pendingCode = _generateCode();
    if (kDebugMode) {
      debugPrint('2FA code for ${pending.email} via $method: $_pendingCode');
    }
  }

  /// Validates the submitted code and finalizes the auth session.
  Future<bool> verifyTwoFactorCode(String code) async {
    final pending = _pendingSession;
    if (pending == null) {
      throw const AuthException('No pending verification available.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 360));
    if (code != _pendingCode) {
      return false;
    }

    final session = AuthSession(
      userId: pending.userId,
      token: pending.token,
      refreshToken: pending.refreshToken,
      rememberMe: pending.rememberMe,
    );
    _currentSession = session;
    _pendingSession = null;
    _pendingCode = null;
    if (session.rememberMe) {
      await _persistSession(session);
    }
    return true;
  }

  /// Tries to restore a remembered session from secure storage.
  Future<bool> tryAutoLogin() async {
    final rememberValue = await _secureStorage.read(key: _rememberMeKey);
    if (rememberValue != 'true') {
      return false;
    }
    final token = await _secureStorage.read(key: _tokenKey);
    final refreshToken = await _secureStorage.read(key: _refreshKey);
    final userId = await _secureStorage.read(key: _userIdKey);
    final expiryValue = await _secureStorage.read(key: _expiryKey);

    if (token == null || userId == null || expiryValue == null) {
      await _clearSecureSession();
      return false;
    }

    final expiry = DateTime.tryParse(expiryValue);
    if (expiry == null || expiry.isBefore(DateTime.now())) {
      await _clearSecureSession();
      return false;
    }

    _currentSession = AuthSession(
      userId: userId,
      token: token,
      refreshToken: refreshToken ?? '',
      rememberMe: true,
    );
    return true;
  }

  /// Clears secure storage and resets all session state.
  Future<void> signOut() async {
    _currentSession = null;
    _pendingSession = null;
    _pendingCode = null;
    await _clearSecureSession();
  }

  /// Securely stores tokens and metadata so auto-login can restore the session.
  Future<void> _persistSession(AuthSession session) async {
    final expiry = DateTime.now().add(const Duration(days: 7));
    await Future.wait([
      _secureStorage.write(key: _tokenKey, value: session.token),
      _secureStorage.write(key: _refreshKey, value: session.refreshToken),
      _secureStorage.write(key: _userIdKey, value: session.userId),
      _secureStorage.write(key: _rememberMeKey, value: session.rememberMe ? 'true' : 'false'),
      _secureStorage.write(key: _expiryKey, value: expiry.toIso8601String()),
    ]);
  }

  Future<void> _clearSecureSession() {
    return Future.wait([
      _secureStorage.delete(key: _tokenKey),
      _secureStorage.delete(key: _refreshKey),
      _secureStorage.delete(key: _userIdKey),
      _secureStorage.delete(key: _rememberMeKey),
      _secureStorage.delete(key: _expiryKey),
    ]).then((_) {});
  }

  String _generateCode() =>
      List.generate(6, (_) => _random.nextInt(10)).join();
}
