import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'two_factor_provider.dart';

enum TwoFactorState {
  idle,
  sending,
  codeSent,
  verifying,
  success,
  error,
}

class TwoFactorController extends ChangeNotifier {
  TwoFactorController({
    required PendingTwoFactorSession session,
    required TwoFactorProvider provider,
    required TwoFactorMethod initialMethod,
    required String initialDestination,
    AuthService? authService,
  })  : _session = session,
        _provider = provider,
        _authService = authService ?? AuthService.instance,
        _selectedMethod = initialMethod,
        _destination = initialDestination;

  final PendingTwoFactorSession _session;
  final TwoFactorProvider _provider;
  final AuthService _authService;

  TwoFactorMethod _selectedMethod;
  String _destination;
  String _code = '';
  TwoFactorState _state = TwoFactorState.idle;
  String? _errorMessage;

  List<TwoFactorMethod> get availableMethods => _session.availableMethods;
  TwoFactorMethod get selectedMethod => _selectedMethod;
  String get destination => _destination;
  String get code => _code;
  TwoFactorState get state => _state;
  String? get errorMessage => _errorMessage;

  bool get isCodeComplete => _code.length == 6;
  bool get isBusy =>
      _state == TwoFactorState.sending || _state == TwoFactorState.verifying;
  bool get canVerify => isCodeComplete && _state != TwoFactorState.verifying;

  void setMethod(TwoFactorMethod method) {
    if (method == _selectedMethod) return;
    _selectedMethod = method;
    _errorMessage = null;
    _state = TwoFactorState.idle;
    _authService.setPendingTwoFactorMethod(method);
    notifyListeners();
  }

  void setDestination(String destination) {
    _destination = destination;
    notifyListeners();
  }

  void setCode(String value) {
    if (_code == value) return;
    _code = value;
    if (_state == TwoFactorState.error) {
      _state = TwoFactorState.idle;
    }
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> sendCode() async {
    if (isBusy) return false;
    _state = TwoFactorState.sending;
    _errorMessage = null;
    notifyListeners();
    try {
      await _provider.sendCode(
        method: _selectedMethod,
        destination: _destination,
        sessionId: _session.userId,
      );
      _state = TwoFactorState.codeSent;
      notifyListeners();
      return true;
    } catch (_) {
      _state = TwoFactorState.error;
      _errorMessage = 'Unable to send a code right now.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verify() async {
    if (!canVerify) return false;
    _state = TwoFactorState.verifying;
    _errorMessage = null;
    notifyListeners();
    try {
      final success = await _provider.verifyCode(
        code: _code,
        sessionId: _session.userId,
      );
      if (!success) {
        _state = TwoFactorState.error;
        _errorMessage = 'Invalid code. Try again.';
        notifyListeners();
        return false;
      }
      await _authService.completeTwoFactorWithoutRemoteCheck();
      _state = TwoFactorState.success;
      notifyListeners();
      return true;
    } catch (_) {
      _state = TwoFactorState.error;
      _errorMessage = 'Unable to verify the code right now.';
      notifyListeners();
      return false;
    }
  }
}
