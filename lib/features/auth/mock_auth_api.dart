import 'dart:math';

import 'demo_credentials.dart';
import 'user_identity.dart';
import 'mock_user_profile_api.dart';

/// A lightweight stub for sending and verifying email codes.
///
/// This simulates backend calls so the UI can enforce verification without
/// depending on a real server.
class MockAuthApi {
  MockAuthApi._();

  static final MockAuthApi instance = MockAuthApi._();

  final Map<String, _CodeState> _codes = {};
  final Random _random = Random();

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
    final userId = UserIdentity.idForEmail(email);
    await MockUserProfileApi.instance.registerUser(userId);
  }

  String _generateCode() {
    return List.generate(6, (_) => _random.nextInt(10)).join();
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
