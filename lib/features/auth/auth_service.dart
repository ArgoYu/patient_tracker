import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'demo_credentials.dart';
<<<<<<< HEAD
import 'user_identity.dart';
import 'user_profile_store.dart';
=======
import 'mock_auth_api.dart';
>>>>>>> 3d14e5a (2FA set up after sign up)

enum TwoFactorMethod {
  sms,
  phoneCall,
  googleDuo,
}

<<<<<<< HEAD
enum LoginMethod {
  password2fa,
  biometrics,
=======
enum TwoFactorFlowType {
  challenge,
  enrollment,
>>>>>>> 3d14e5a (2FA set up after sign up)
}

/// Represents the data needed to continue a pending two-factor verification.
class PendingTwoFactorSession {
  PendingTwoFactorSession({
    required this.email,
    required this.userId,
    required this.token,
    required this.refreshToken,
    required this.availableMethods,
    required this.showOnboardingAfterSuccess,
    required this.hasCompletedGlobalOnboarding,
    required this.flowType,
  });

  final String email;
  final String userId;
  final String token;
  final String refreshToken;
  final List<TwoFactorMethod> availableMethods;
  final bool showOnboardingAfterSuccess;
  final bool hasCompletedGlobalOnboarding;
  final TwoFactorFlowType flowType;
}

/// Holds the authenticated session details.
class AuthSession {
  AuthSession({
    required this.userId,
    required this.token,
    required this.refreshToken,
<<<<<<< HEAD
=======
    required this.rememberMe,
    required this.hasCompletedGlobalOnboarding,
>>>>>>> 3d14e5a (2FA set up after sign up)
  });

  final String userId;
  final String token;
  final String refreshToken;
<<<<<<< HEAD
=======
  final bool rememberMe;
  final bool hasCompletedGlobalOnboarding;

  AuthSession copyWith({
    bool? hasCompletedGlobalOnboarding,
  }) {
    return AuthSession(
      userId: userId,
      token: token,
      refreshToken: refreshToken,
      rememberMe: rememberMe,
      hasCompletedGlobalOnboarding:
          hasCompletedGlobalOnboarding ?? this.hasCompletedGlobalOnboarding,
    );
  }
>>>>>>> 3d14e5a (2FA set up after sign up)
}

/// Result returned when attempting to log in.
class AuthLoginResult {
  AuthLoginResult({
    required this.userId,
    required this.token,
    required this.refreshToken,
    required this.requiresTwoFactorChallenge,
    required this.requiresTwoFactorSetup,
    required this.availableMethods,
    required this.showGlobalOnboarding,
    required this.hasCompletedGlobalOnboarding,
  });

  final String userId;
  final String token;
  final String refreshToken;
  final bool requiresTwoFactorChallenge;
  final bool requiresTwoFactorSetup;
  final List<TwoFactorMethod> availableMethods;
  final bool showGlobalOnboarding;
  final bool hasCompletedGlobalOnboarding;
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

<<<<<<< HEAD
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
=======
  String? get currentUserId => _currentSession?.userId;
>>>>>>> 3d14e5a (2FA set up after sign up)

  /// Attempts to authenticate with the provided credentials.
  Future<AuthLoginResult> login({
    required String email,
    required String password,
<<<<<<< HEAD
=======
    required bool rememberMe,
    bool showGlobalOnboarding = false,
>>>>>>> 3d14e5a (2FA set up after sign up)
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
<<<<<<< HEAD
    // Demo users are always forced through the two-factor flow so the demo can
    // showcase the complete experience before landing in the app.
    const methods = TwoFactorMethod.values;
    _pendingSession = PendingTwoFactorSession(
      email: email,
      userId: userId,
      token: token,
      refreshToken: refreshToken,
      availableMethods: methods,
=======
    final hasCompletedOnboarding =
        await MockAuthApi.instance.hasCompletedGlobalOnboarding(userId: userId);
    final hasTwoFactorEnabled =
        await MockAuthApi.instance.hasTwoFactorEnabled(userId: userId);
    const methods = TwoFactorMethod.values;
    final requiresTwoFactorChallenge =
        isDemoLogin || hasTwoFactorEnabled;
    final requiresTwoFactorSetup =
        !requiresTwoFactorChallenge && !showGlobalOnboarding;

    if (requiresTwoFactorChallenge) {
      _pendingSession = PendingTwoFactorSession(
        email: email,
        userId: userId,
        token: token,
        refreshToken: refreshToken,
        rememberMe: rememberMe,
        availableMethods: methods,
        showOnboardingAfterSuccess: showGlobalOnboarding,
        hasCompletedGlobalOnboarding: hasCompletedOnboarding,
        flowType: TwoFactorFlowType.challenge,
      );
      return AuthLoginResult(
        userId: userId,
        token: token,
        refreshToken: refreshToken,
        requiresTwoFactorChallenge: true,
        requiresTwoFactorSetup: false,
        availableMethods: methods,
        showGlobalOnboarding: showGlobalOnboarding,
        hasCompletedGlobalOnboarding: hasCompletedOnboarding,
      );
    }
    final session = AuthSession(
      userId: userId,
      token: token,
      refreshToken: refreshToken,
      rememberMe: rememberMe,
      hasCompletedGlobalOnboarding: hasCompletedOnboarding,
>>>>>>> 3d14e5a (2FA set up after sign up)
    );
    return AuthLoginResult(
      userId: userId,
      token: token,
      refreshToken: refreshToken,
<<<<<<< HEAD
      requiresTwoFactor: true,
=======
      requiresTwoFactorChallenge: false,
      requiresTwoFactorSetup: requiresTwoFactorSetup,
>>>>>>> 3d14e5a (2FA set up after sign up)
      availableMethods: methods,
      showGlobalOnboarding: showGlobalOnboarding,
      hasCompletedGlobalOnboarding: hasCompletedOnboarding,
    );
  }

<<<<<<< HEAD
  void markPendingGlobalOnboarding() {
    _pendingGlobalOnboarding = true;
  }

  bool consumePendingGlobalOnboarding() {
    final pending = _pendingGlobalOnboarding;
    _pendingGlobalOnboarding = false;
    return pending;
=======
  /// Prepares a two-factor enrollment session for the current user.
  Future<void> startTwoFactorSetup({
    required String userId,
    required String email,
  }) async {
    final currentSession = _currentSession;
    final methods = TwoFactorMethod.values;
    _pendingSession = PendingTwoFactorSession(
      email: email,
      userId: userId,
      token: currentSession?.token ?? '',
      refreshToken: currentSession?.refreshToken ?? '',
      rememberMe: currentSession?.rememberMe ?? false,
      availableMethods: methods,
      showOnboardingAfterSuccess: false,
      hasCompletedGlobalOnboarding:
          currentSession?.hasCompletedGlobalOnboarding ?? false,
      flowType: TwoFactorFlowType.enrollment,
    );
    _pendingCode = null;
>>>>>>> 3d14e5a (2FA set up after sign up)
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

<<<<<<< HEAD
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
=======
    if (pending.flowType == TwoFactorFlowType.challenge) {
      final session = AuthSession(
        userId: pending.userId,
        token: pending.token,
        refreshToken: pending.refreshToken,
        rememberMe: pending.rememberMe,
        hasCompletedGlobalOnboarding: pending.hasCompletedGlobalOnboarding,
      );
      _currentSession = session;
      if (session.rememberMe) {
        await _persistSession(session);
      }
    } else {
      await MockAuthApi.instance.markTwoFactorEnabled(userId: pending.userId);
    }
    _pendingSession = null;
    _pendingCode = null;
>>>>>>> 3d14e5a (2FA set up after sign up)
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

<<<<<<< HEAD
    return AuthSession(
      userId: userId,
      token: token,
      refreshToken: refreshToken ?? '',
=======
    final hasCompletedOnboarding =
        await MockAuthApi.instance.hasCompletedGlobalOnboarding(userId: userId);
    _currentSession = AuthSession(
      userId: userId,
      token: token,
      refreshToken: refreshToken ?? '',
      rememberMe: true,
      hasCompletedGlobalOnboarding: hasCompletedOnboarding,
>>>>>>> 3d14e5a (2FA set up after sign up)
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

<<<<<<< HEAD
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
=======
  void markGlobalOnboardingCompleted() {
    final current = _currentSession;
    if (current == null) return;
    _currentSession = current.copyWith(hasCompletedGlobalOnboarding: true);
  }

  /// Securely stores tokens and metadata so auto-login can restore the session.
>>>>>>> 3d14e5a (2FA set up after sign up)
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
