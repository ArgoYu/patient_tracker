import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/prefs_keys.dart';
import '../user/mock_user_api.dart';
import 'demo_credentials.dart';
import 'mock_auth_api.dart';
import 'user_account.dart' hide isDemoAccount;
import 'user_identity.dart';

export 'mock_auth_api.dart' show TotpProvision;

enum TwoFactorMethod {
  sms,
  phoneCall,
  authenticatorApp,
}

enum TwoFactorFlowType {
  challenge,
  enrollment,
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
    required this.showOnboardingAfterSuccess,
    required this.hasCompletedGlobalOnboarding,
    this.savedPhoneNumber,
    required this.flowType,
    required this.userAccount,
  });

  final String email;
  final String userId;
  final String token;
  final String refreshToken;
  final bool rememberMe;
  final List<TwoFactorMethod> availableMethods;
  final bool showOnboardingAfterSuccess;
  final bool hasCompletedGlobalOnboarding;
  final String? savedPhoneNumber;
  final TwoFactorFlowType flowType;
  final UserAccount userAccount;
}

/// Holds the authenticated session details.
class AuthSession {
  AuthSession({
    required this.userId,
    required this.token,
    required this.refreshToken,
    required this.rememberMe,
    required this.hasCompletedGlobalOnboarding,
    required this.userAccount,
  });

  final String userId;
  final String token;
  final String refreshToken;
  final bool rememberMe;
  final bool hasCompletedGlobalOnboarding;
  final UserAccount userAccount;

  AuthSession copyWith({
    bool? hasCompletedGlobalOnboarding,
    UserAccount? userAccount,
  }) {
    return AuthSession(
      userId: userId,
      token: token,
      refreshToken: refreshToken,
      rememberMe: rememberMe,
      hasCompletedGlobalOnboarding:
          hasCompletedGlobalOnboarding ?? this.hasCompletedGlobalOnboarding,
      userAccount: userAccount ?? this.userAccount,
    );
  }
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
      // On desktop, remember-me persistence is currently disabled to avoid
      // keychain entitlement issues; safe to enable later once entitlements are
      // configured.
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
      debugPrint('SecureStorage deleteAll skipped on ${Platform.operatingSystem}');
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
  String? _pendingPhoneNumber;
  TwoFactorMethod? _pendingMethod;
  TotpProvision? _pendingTotpProvision;
  AuthSession? _currentSession;
  bool _currentUserIsDemo = false;
  final ValueNotifier<UserAccount?> _accountNotifier = ValueNotifier(null);

  static const _tokenKey = 'auth_token';
  static const _refreshKey = 'refresh_token';
  static const _userIdKey = 'auth_user_id';
  static const _expiryKey = 'auth_token_expiry';
  static const _rememberMeKey = 'remember_me';
  static const _accountKey = 'auth_user_account';

  /// Indicates whether the active session or pending login belongs to the demo account.
  bool get currentUserIsDemo => _currentUserIsDemo;

  bool get isAuthenticated => _currentSession != null;

  PendingTwoFactorSession? get pendingTwoFactorSession => _pendingSession;

  String? get pendingTwoFactorPhoneNumber => _pendingPhoneNumber;
  TotpProvision? get pendingTwoFactorTotpProvision => _pendingTotpProvision;
  TwoFactorMethod? get pendingTwoFactorMethod => _pendingMethod;

  String? get currentUserId => _currentSession?.userId;
  ValueListenable<UserAccount?> get currentUserAccountListenable =>
      _accountNotifier;
  UserAccount? get currentUserAccount => _accountNotifier.value;

  /// Attempts to authenticate with the provided credentials.
  Future<AuthLoginResult> login({
    required String email,
    required String password,
    required bool rememberMe,
    bool showGlobalOnboarding = false,
    String? displayName,
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
    final account = isDemoLogin
        ? demoUserAccount
        : await _buildAccount(
            userId: userId,
            email: email,
            displayName: displayName,
          );
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
      final savedPhone = await MockAuthApi.instance.fetchTwoFactorPhone(
        userId: userId,
      );
      _pendingPhoneNumber = savedPhone;
      _pendingSession = PendingTwoFactorSession(
        email: email,
        userId: userId,
        token: token,
        refreshToken: refreshToken,
        rememberMe: rememberMe,
        availableMethods: methods,
        showOnboardingAfterSuccess: showGlobalOnboarding,
        hasCompletedGlobalOnboarding: hasCompletedOnboarding,
        savedPhoneNumber: savedPhone,
        flowType: TwoFactorFlowType.challenge,
        userAccount: account,
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
      userAccount: account,
    );
    _currentSession = session;
    _updateCurrentAccount(account);
    // Persist the session if the user asked to be remembered.
    if (rememberMe) {
      await _persistSession(session);
    }
    return AuthLoginResult(
      userId: userId,
      token: token,
      refreshToken: refreshToken,
      requiresTwoFactorChallenge: false,
      requiresTwoFactorSetup: requiresTwoFactorSetup,
      availableMethods: methods,
      showGlobalOnboarding: showGlobalOnboarding,
      hasCompletedGlobalOnboarding: hasCompletedOnboarding,
    );
  }

  /// Prepares a two-factor enrollment session for the current user.
  Future<void> startTwoFactorSetup({
    required String userId,
    required String email,
  }) async {
    final currentSession = _currentSession;
    const methods = TwoFactorMethod.values;
    final fallbackAccount = currentSession?.userAccount ??
        await _buildAccount(
          userId: userId,
          email: email,
        );
    final savedPhone = await MockAuthApi.instance.fetchTwoFactorPhone(userId: userId);
    _pendingPhoneNumber = savedPhone;
    _pendingMethod = null;
    _pendingTotpProvision = null;
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
      savedPhoneNumber: savedPhone,
      flowType: TwoFactorFlowType.enrollment,
      userAccount: fallbackAccount,
    );
    _pendingCode = null;
  }

  /// Generates or resends a 2FA code via the selected [method].
  Future<void> requestTwoFactorCode(
    TwoFactorMethod method, {
    String? phoneNumber,
  }) async {
    final pending = _pendingSession;
    if (pending == null) {
      throw const AuthException('No pending verification available.');
    }
    final requiresPhone = method == TwoFactorMethod.sms ||
        method == TwoFactorMethod.phoneCall;
    await Future<void>.delayed(const Duration(milliseconds: 360));
    if (requiresPhone) {
      final candidate = (phoneNumber ?? _pendingPhoneNumber ?? '').trim();
      final normalizedPhone = _normalizePhoneNumber(candidate);

      if (normalizedPhone.isEmpty) {
        // Do not crash the app if some caller forgot to provide a phone number.
        // UI-level validation (in the 2FA setup screen) already enforces this
        // for enrollment flows. For other flows (e.g. resend), we just skip
        // requesting a new code when there is no phone available.
        debugPrint(
          'AuthService.requestTwoFactorCode: empty phone for $method; '
          'skipping phone update / code request.',
        );
        return;
      }

      await MockAuthApi.instance.updateTwoFactorPhone(
        userId: pending.userId,
        phoneNumber: normalizedPhone,
      );
      _pendingPhoneNumber = normalizedPhone;
      _pendingTotpProvision = null;
    } else {
      if (pending.flowType == TwoFactorFlowType.enrollment) {
        _pendingTotpProvision = await MockAuthApi.instance.generateTotpSetup(
          userId: pending.userId,
          email: pending.email,
        );
      } else {
        _pendingTotpProvision = null;
      }
    }
    _pendingMethod = method;
    final useFixedCode = kDebugMode || _currentUserIsDemo;
    if (requiresPhone) {
      _pendingCode = useFixedCode ? demoVerificationCode : _generateCode();
    } else {
      _pendingCode = null;
    }
    if (requiresPhone && kDebugMode) {
      final sourceLabel =
          _currentUserIsDemo ? '(demo fixed code)' : '(dev fixed code)';
      debugPrint(
        '2FA code for ${pending.email} via $method: $_pendingCode $sourceLabel',
      );
    }
    if (!requiresPhone && _pendingTotpProvision != null && kDebugMode) {
      debugPrint(
        'Authenticator secret for ${pending.email}: ${_pendingTotpProvision!.secret}',
      );
    }
  }

  void setPendingTwoFactorMethod(TwoFactorMethod method) {
    _pendingMethod = method;
  }

  Future<void> _finalizePendingTwoFactorSession(
    PendingTwoFactorSession pending,
  ) async {
    if (pending.flowType == TwoFactorFlowType.challenge) {
      final account = pending.userAccount;
      final session = AuthSession(
        userId: pending.userId,
        token: pending.token,
        refreshToken: pending.refreshToken,
        rememberMe: pending.rememberMe,
        hasCompletedGlobalOnboarding: pending.hasCompletedGlobalOnboarding,
        userAccount: account,
      );
      _currentSession = session;
      _updateCurrentAccount(account);
      if (session.rememberMe) {
        await _persistSession(session);
      }
    } else {
      await MockAuthApi.instance.markTwoFactorEnabled(userId: pending.userId);
    }
    _pendingSession = null;
    _pendingCode = null;
    _pendingMethod = null;
    _pendingTotpProvision = null;
    _pendingPhoneNumber = null;
  }

  Future<void> completeTwoFactorWithoutRemoteCheck() async {
    final pending = _pendingSession;
    if (pending == null) {
      throw const AuthException('No pending verification available.');
    }
    await _finalizePendingTwoFactorSession(pending);
  }

  /// Validates the submitted code and finalizes the auth session.
  Future<bool> verifyTwoFactorCode(String code) async {
    final pending = _pendingSession;
    if (pending == null) {
      throw const AuthException('No pending verification available.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 360));
    final isDevOverride = (kDebugMode || _currentUserIsDemo) &&
        code == demoVerificationCode;
    if (!isDevOverride) {
      final method = _pendingMethod;
      if (method == TwoFactorMethod.authenticatorApp) {
        final totpValid = await MockAuthApi.instance.verifyTotpCode(
          userId: pending.userId,
          code: code,
        );
        if (!totpValid) {
          return false;
        }
      } else {
        final expectedCode = _pendingCode;
        if (expectedCode == null || code != expectedCode) {
          return false;
        }
      }
    }

    await _finalizePendingTwoFactorSession(pending);
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

    final hasCompletedOnboarding =
        await MockAuthApi.instance.hasCompletedGlobalOnboarding(userId: userId);
    final storedAccountJson = await _secureStorage.read(key: _accountKey);
    final storedAccount = UserAccount.tryFromJson(storedAccountJson);
    final account = await _buildFallbackAccount(
      userId,
      email: storedAccount?.email,
      displayName: storedAccount?.displayName,
    );
    _currentSession = AuthSession(
      userId: userId,
      token: token,
      refreshToken: refreshToken ?? '',
      rememberMe: true,
      hasCompletedGlobalOnboarding: hasCompletedOnboarding,
      userAccount: account,
    );
    _updateCurrentAccount(account);
    return true;
  }

  /// Clears secure storage and resets all session state.
  Future<void> signOut() async {
    _currentSession = null;
    _pendingSession = null;
    _pendingCode = null;
    _updateCurrentAccount(null);
    await _clearSecureSession();
  }

  void markGlobalOnboardingCompleted() {
    final current = _currentSession;
    if (current == null) return;
    _currentSession = current.copyWith(hasCompletedGlobalOnboarding: true);
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
      _secureStorage.write(key: _accountKey, value: session.userAccount.toJson()),
    ]);
  }

  Future<void> _clearSecureSession() {
    return Future.wait([
      _secureStorage.delete(key: _tokenKey),
      _secureStorage.delete(key: _refreshKey),
      _secureStorage.delete(key: _userIdKey),
      _secureStorage.delete(key: _rememberMeKey),
      _secureStorage.delete(key: _expiryKey),
      _secureStorage.delete(key: _accountKey),
    ]).then((_) {});
  }

  void _updateCurrentAccount(UserAccount? account) {
    _currentUserIsDemo = account?.id == demoUserAccount.id;
    _accountNotifier.value = account;
  }

  Future<void> refreshCurrentUserAccount() async {
    final current = _currentSession;
    if (current == null) return;
    final refreshedAccount = await _buildAccount(
      userId: current.userId,
      email: current.userAccount.email,
      displayName: current.userAccount.displayName,
    );
    _currentSession = current.copyWith(userAccount: refreshedAccount);
    _updateCurrentAccount(refreshedAccount);
    if (_currentSession?.rememberMe ?? false) {
      await _persistSession(_currentSession!);
    }
  }

  Future<UserAccount> _buildAccount({
    required String userId,
    required String email,
    String? displayName,
  }) async {
    final profile = await MockUserApi.instance.fetchProfile(userId: userId);
    final legalName = _normalizeName(profile?.legalName);
    final preferredName = _normalizeName(profile?.preferredName);
    final fallback = _normalizeName(displayName);
    final finalName = preferredName ??
        legalName ??
        fallback ??
        _suggestDisplayName(email);
    return UserAccount(
      id: userId,
      email: email,
      displayName: finalName,
      legalName: legalName,
      preferredName: preferredName,
    );
  }

  String? _normalizeName(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<UserAccount> _buildFallbackAccount(
    String userId, {
    String? email,
    String? displayName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = email ?? prefs.getString(PrefsKeys.authEmail) ?? '';
    return await _buildAccount(
      userId: userId,
      email: storedEmail,
      displayName: displayName,
    );
  }

  String _suggestDisplayName(String email) {
    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) {
      return 'Guest';
    }
    return localPart;
  }

  String _generateCode() =>
      List.generate(6, (_) => _random.nextInt(10)).join();

  String _normalizePhoneNumber(String value) {
    return value.replaceAll(RegExp(r'[^+0-9]'), '');
  }
}
