import 'dart:math';

import 'demo_credentials.dart';
import 'auth_service.dart';

abstract class TwoFactorProvider {
  Future<void> sendCode({
    required TwoFactorMethod method,
    required String destination,
    required String sessionId,
  });

  Future<bool> verifyCode({
    required String code,
    required String sessionId,
  });
}

class MockTwoFactorProvider implements TwoFactorProvider {
  final Random _random = Random();

  @override
  Future<void> sendCode({
    required TwoFactorMethod method,
    required String destination,
    required String sessionId,
  }) async {
    final delayMs = 300 + _random.nextInt(301);
    await Future<void>.delayed(Duration(milliseconds: delayMs));
  }

  @override
  Future<bool> verifyCode({
    required String code,
    required String sessionId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return code == demoVerificationCode;
  }
}

class RealTwoFactorProvider implements TwoFactorProvider {
  @override
  Future<void> sendCode({
    required TwoFactorMethod method,
    required String destination,
    required String sessionId,
  }) async {
    throw UnimplementedError('TODO: Connect to real 2FA delivery backend.');
  }

  @override
  Future<bool> verifyCode({
    required String code,
    required String sessionId,
  }) async {
    throw UnimplementedError('TODO: Connect to real 2FA verification backend.');
  }
}
