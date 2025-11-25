import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'demo_credentials.dart';
import 'user_identity.dart';
import 'user_profile_store.dart';

enum TwoFactorMethod {
  sms,
  phoneCall,
  googleDuo,
}

enum LoginMethod {
  password2fa,
  biometrics,
}

/// Represents the data needed to continue a pending two-factor verification.
class PendingTwoFactorSession {
  PendingTwoFactorSession({
    required this.email,
    required this.userId,
    required this.token,
    required this.refreshToken,
    required this.availableMethods,
  });

  final String email;
  final String userId;
  final String token;
  final String refreshToken;
  final List<TwoFactorMethod> availableMethods;
}

/// Holds the authenticated session details.
class AuthSession {
  AuthSession({
    required this.userId,
    required this.token,
    required this.refreshToken,
  });

  final String userId;
  final String token;
  final String refreshToken;
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

/// A safe wrapper around [FlutterSecureStorage] that only runs on mobile and
/// gracefully handles Keychain/credential errors instead of crashing.
class SafeSecureStorage {
  SafeSecureStorage();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool get _isMobilePlatform => Platform.isAndroid || Platform.isIOS;

  Future<void> write({required String key, String? value}) async {
    if (kIsWeb) return;

    if (!_isMobilePlatform) {
      // On desktop, secure persistence is currently disabled to avoid keychain
      // entitlement issues; safe to enable once entitlements are configured.
      debugPrint('SecureStorage write skipped on ${Platform.operatingSystem}');
      return;
    }

    try {
      await _storage.write(key: key, value: value);
    } on PlatformException catch (e) {
      debugPrint('SecureStorage write failed: $e');
    }
  }

  Future<String?> read({required String key}) async {
    if (kIsWeb) return null;

    if (!_isMobilePlatform) {
      debugPrint('SecureStorage read skipped on ${Platform.operatingSystem}');
      return null;
    }

    try {
      return await _storage.read(key: key);
    } on PlatformException catch (e) {
      debugPrint('SecureStorage read failed: $e');
      return null;
    }
  }

  Future<void> delete({required String key}) async {
    if (kIsWeb) return;

    if (!_isMobilePlatform) {
      debugPrint('SecureStorage delete skipped on ${Platform.operatingSystem}');
      return;
    }

    try {
      await _storage.delete(key: key);
    } on PlatformException catch (e) {
      debugPrint('SecureStorage delete failed: $e');
    }
  }

  Future<void> deleteAll() async {
    if (kIsWeb) return;

    if (!_isMobilePlatform) {
      debugPrint(
          'SecureStorage deleteAll skipped on ${Platform.operatingSystem}');
      return;
    }

    try {
      await _storage.deleteAll();
    } on PlatformException catch (e) {
      debugPrint('SecureStorage deleteAll failed: $e');
    }
  }
}

/// Handles authentication, secure persistence, and two-factor interactions.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final SafeSecureStorage _secureStorage = SafeSecureStorage();
  final Random _random = Random();

  PendingTwoFactorSession? _pendingSession;
  String? _pendingCode;
  AuthSession? _currentSession;
  bool _currentUserIsDemo = false;
  LoginMethod? _cachedLoginMethod;
  bool _pendingGlobalOnboarding = false;

  static const _tokenKey = 'auth_token';
  static const _refreshKey = 'refresh_token';
  static const _userIdKey = 'auth_user_id';
  static const _expiryKey = 'auth_token_expiry';
  static const _loginMethodKey = 'login_method';
  static const _loginMethodBiometricValue = 'biometrics';
  static const _loginMethodPasswordValue = 'password_2fa';

  /// Indicates whether the active session or pending login belongs to the demo
  /// account.
  bool get currentUserIsDemo => _currentUserIsDemo;

  bool get isAuthenticated => _currentSession != null;

  AuthSession? get currentSession => _currentSession;

  PendingTwoFactorSession? get pendingTwoFactorSession => _pendingSession;

  Future<LoginMethod> loadPreferredLoginMethod() async {
    final cached = _cachedLoginMethod;
    if (cached != null) {
      return cached;
    }
    final stored = await _secureStorage.read(key: _loginMethodKey);
    final method = stored == _loginMethodBiometricValue
        ? LoginMethod.biometrics
        : LoginMethod.password2fa;
    _cachedLoginMethod = method;
    return method;
  }

  Future<void> setPreferredLoginMethod(LoginMethod method) async {
    _cachedLoginMethod = method;
    await _secureStorage.write(
      key: _loginMethodKey,
      value: method == LoginMethod.biometrics
          ? _loginMethodBiometricValue
          : _loginMethodPasswordValue,
    );
  }

  /// Attempts to authenticate with the provided credentials.
  Future<AuthLoginResult> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (email.isEmpty || password.isEmpty) {
      throw const AuthException('Email and password are required.');
    }

    final userId = UserIdentity.idForEmail(email);
    final token = 'token-${DateTime.now().millisecondsSinceEpoch}';
    final refreshToken = 'refresh-${email.hashCode}-${_random.nextInt(9999)}';
    final isDemoLogin = isDemoAccount(email: email, password: password);
    _currentUserIsDemo = isDemoLogin;
    // Demo users are always forced through the two-factor flow so the demo can
    // showcase the complete experience before landing in the app.
    const methods = TwoFactorMethod.values;
    _pendingSession = PendingTwoFactorSession(
      email: email,
      userId: userId,
      token: token,
      refreshToken: refreshToken,
      availableMethods: methods,
    );
    return AuthLoginResult(
      userId: userId,
      token: token,
      refreshToken: refreshToken,
      requiresTwoFactor: true,
      availableMethods: methods,
    );
  }

  void markPendingGlobalOnboarding() {
    _pendingGlobalOnboarding = true;
  }

  bool consumePendingGlobalOnboarding() {
    final pending = _pendingGlobalOnboarding;
    _pendingGlobalOnboarding = false;
    return pending;
  }

  /// Generates or resends a 2FA code via the selected [method].
  Future<void> requestTwoFactorCode(TwoFactorMethod method) async {
    final pending = _pendingSession;
    if (pending == null) {
      throw const AuthException('No pending verification available.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 360));
    if (_currentUserIsDemo) {
      // The demo account always uses the fixed demo verification code (000000)
      // for testing and demo flows only so the two-factor screen can show the
      // complete experience without a backend call.
      _pendingCode = demoVerificationCode;
    } else {
      _pendingCode = _generateCode();
    }
    if (kDebugMode) {
      debugPrint(
        '2FA code for ${pending.email} via $method: $_pendingCode '
        '${_currentUserIsDemo ? '(demo fixed code)' : ''}',
      );
    }
  }

  /// Validates the submitted code and finalizes the auth session.
  Future<bool> verifyTwoFactorCode(String code) async {
    final pending = _pendingSession;
    if (pending == null) {
      throw const AuthException('No pending verification available.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 360));
    final expectedCode =
        _currentUserIsDemo ? demoVerificationCode : _pendingCode;
    if (expectedCode == null || code != expectedCode) {
      return false;
    }

    return true;
  }

  Future<void> finishTwoFactorLogin(PendingTwoFactorSession pending) async {
    final session = AuthSession(
      userId: pending.userId,
      token: pending.token,
      refreshToken: pending.refreshToken,
    );
    _currentSession = session;
    _pendingSession = null;
    _pendingCode = null;
  }

  /// Attempts to build a session from tokens previously stored for biometric
  /// sign-in.
  Future<bool> restoreSessionFromStorage() async {
    final session = await _loadStoredSession();
    if (session == null) return false;
    _currentSession = session;
    return true;
  }

  Future<AuthSession?> _loadStoredSession() async {
    final token = await _secureStorage.read(key: _tokenKey);
    final refreshToken = await _secureStorage.read(key: _refreshKey);
    final userId = await _secureStorage.read(key: _userIdKey);
    final expiryValue = await _secureStorage.read(key: _expiryKey);

    if (token == null || userId == null || expiryValue == null) {
      await _deleteStoredTokens();
      return null;
    }

    final expiry = DateTime.tryParse(expiryValue);
    if (expiry == null || expiry.isBefore(DateTime.now())) {
      await _deleteStoredTokens();
      return null;
    }

    return AuthSession(
      userId: userId,
      token: token,
      refreshToken: refreshToken ?? '',
    );
  }

  /// Clears the in-memory session state while leaving stored biometric tokens
  /// untouched so the device can still prompt for biometrics.
  Future<void> signOut() async {
    _currentSession = null;
    _pendingSession = null;
    _pendingCode = null;
    _currentUserIsDemo = false;
    UserProfileStore.instance.clear();
  }

  /// Enables biometric login for the current authenticated session.
  Future<bool> enableBiometricLogin() async {
    final session = _currentSession;
    if (session == null) {
      return false;
    }
    await _persistSession(session);
    await setPreferredLoginMethod(LoginMethod.biometrics);
    return true;
  }

  /// Disables biometric login on this device.
  Future<void> disableBiometricLogin() async {
    await _deleteStoredTokens();
    await setPreferredLoginMethod(LoginMethod.password2fa);
  }

  /// Securely stores tokens and metadata so biometric login can continue later.
  Future<void> _persistSession(AuthSession session) async {
    final expiry = DateTime.now().add(const Duration(days: 7));
    await Future.wait([
      _secureStorage.write(key: _tokenKey, value: session.token),
      _secureStorage.write(key: _refreshKey, value: session.refreshToken),
      _secureStorage.write(key: _userIdKey, value: session.userId),
      _secureStorage.write(key: _expiryKey, value: expiry.toIso8601String()),
    ]);
  }

  Future<void> _deleteStoredTokens() {
    return Future.wait([
      _secureStorage.delete(key: _tokenKey),
      _secureStorage.delete(key: _refreshKey),
      _secureStorage.delete(key: _userIdKey),
      _secureStorage.delete(key: _expiryKey),
    ]).then((_) {});
  }

  String _generateCode() => List.generate(6, (_) => _random.nextInt(10)).join();
}
