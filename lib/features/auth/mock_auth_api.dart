import 'dart:math';

import 'package:otp/otp.dart';

import '../user/mock_user_api.dart';
import 'demo_credentials.dart';
import 'user_identity.dart';

/// A lightweight stub for sending and verifying email codes.
///
/// This simulates backend calls so the UI can enforce verification without
/// depending on a real server.
class TotpProvision {
  const TotpProvision({
    required this.secret,
    required this.provisioningUri,
  });

  final String secret;
  final String provisioningUri;
}

class MockAuthApi {
  MockAuthApi._();

  static final MockAuthApi instance = MockAuthApi._();

  final Map<String, _CodeState> _codes = {};
  final Random _random = Random();
  final Map<String, bool> _onboardingCompleted = {};
  final Map<String, bool> _twoFactorEnabled = {};
  final Map<String, String> _twoFactorPhones = {};
  final Map<String, String> _totpSecrets = {};

  Future<String> sendEmailCode(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final code = isDemoEmail(email) ? demoVerificationCode : _generateCode();
    _codes[email] = _CodeState(
      code: code,
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    );
    return code;
  }

  Future<void> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final entry = _codes[email];
    if (entry == null) {
      throw const EmailCodeException(EmailCodeError.invalid);
    }
    if (DateTime.now().isAfter(entry.expiresAt)) {
      throw const EmailCodeException(EmailCodeError.expired);
    }
    if (entry.code != code) {
      throw const EmailCodeException(EmailCodeError.invalid);
    }
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // In a real implementation we would persist the user and return tokens.
    _codes.remove(email);
    final userId = _userIdForEmail(email);
    _onboardingCompleted[userId] = false;
    _twoFactorEnabled[userId] = false;
    await MockUserApi.instance.registerProfile(
      userId: userId,
    );
  }

  Future<String?> fetchTwoFactorPhone({
    required String userId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _twoFactorPhones[userId];
  }

  Future<void> updateTwoFactorPhone({
    required String userId,
    required String phoneNumber,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    _twoFactorPhones[userId] = phoneNumber;
  }

  Future<TotpProvision> generateTotpSetup({
    required String userId,
    required String email,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final secret = _generateBase32Secret();
    _totpSecrets[userId] = secret;
    final provisioningUri = _buildOtpProvisioningUri(secret: secret, email: email);
    return TotpProvision(
      secret: secret,
      provisioningUri: provisioningUri,
    );
  }

  Future<bool> verifyTotpCode({
    required String userId,
    required String code,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final secret = _totpSecrets[userId];
    if (secret == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    final validCodes = [
      OTP.generateTOTPCodeString(
        secret,
        now - 30000,
        algorithm: Algorithm.SHA1,
        length: 6,
      ),
      OTP.generateTOTPCodeString(
        secret,
        now,
        algorithm: Algorithm.SHA1,
        length: 6,
      ),
      OTP.generateTOTPCodeString(
        secret,
        now + 30000,
        algorithm: Algorithm.SHA1,
        length: 6,
      ),
    ];
    return validCodes.contains(code);
  }

  Future<bool> hasCompletedGlobalOnboarding({
    required String userId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _onboardingCompleted[userId] ?? true;
  }

  Future<void> setGlobalOnboardingCompleted({
    required String userId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _onboardingCompleted[userId] = true;
  }

  Future<bool> hasTwoFactorEnabled({
    required String userId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _twoFactorEnabled[userId] ?? true;
  }

  Future<void> markTwoFactorEnabled({
    required String userId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _twoFactorEnabled[userId] = true;
  }

  String _generateCode() {
    return List.generate(6, (_) => _random.nextInt(10)).join();
  }

  String _userIdForEmail(String email) => UserIdentity.idForEmail(email);

  String _generateBase32Secret([int length = 20]) {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    return List.generate(length, (_) => charset[_random.nextInt(charset.length)])
        .join();
  }

  String _buildOtpProvisioningUri({
    required String secret,
    required String email,
  }) {
    final label = Uri.encodeComponent('Patient Tracker:$email');
    final issuer = Uri.encodeComponent('Patient Tracker');
    return 'otpauth://totp/$label?secret=$secret&issuer=$issuer&digits=6&period=30&algorithm=SHA1';
  }
}

class _CodeState {
  _CodeState({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;
}

enum EmailCodeError { invalid, expired }

class EmailCodeException implements Exception {
  const EmailCodeException(this.type);
  final EmailCodeError type;
}
