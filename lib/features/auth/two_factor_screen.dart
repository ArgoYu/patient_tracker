import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/routing/app_routes.dart';
import '../onboarding/global_onboarding_screen.dart';
import 'auth_service.dart';
import 'demo_credentials.dart';
import 'two_factor_success_screen.dart';

class TwoFactorScreen extends StatefulWidget {
  const TwoFactorScreen({super.key});

  static const routeName = '/two-factor';

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  static final RegExp _sixDigitCodeRegExp = RegExp(r'^\d{6}$');

  TwoFactorMethod? _selectedMethod;
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _isRequestingCode = false;
  bool _isVerifying = false;
  bool _codeSent = false;
  bool _hasSavedPhoneOnAccount = false;
  bool _isEditingPhone = true;
  String? _error;
  String? _statusMessage;
  String? _phoneError;
  String? _codeError;

  PendingTwoFactorSession? get _pending =>
      AuthService.instance.pendingTwoFactorSession;

  bool get _isDemoUser => AuthService.instance.currentUserIsDemo;

  String? get _codeHint {
    if (_isDemoUser) {
      return 'Demo accounts always require a second factor. Enter '
          '$demoVerificationCode to proceed.';
    }
    if (kDebugMode) {
      return 'Development builds skip real SMS/email delivery. Enter '
          '$demoVerificationCode to continue.';
    }
    return null;
  }

  bool get _needsPhone =>
      _selectedMethod != null && _isPhoneMethod(_selectedMethod!);

  String get _trimmedCode => _codeController.text.trim();

  bool get _isDemoBypass => _isDemoUser && _trimmedCode == demoVerificationCode;

  String get _subtitleText {
    if (_selectedMethod == null) {
      return 'We need one more proof of identity before giving you access.';
    }
    if (_needsPhone) {
      return 'We need one more proof of identity. We’ll send a 6-digit code to your phone number.';
    }
    return 'We need one more proof of identity. Use your Google Authenticator app to get a 6-digit code.';
  }

  String? get _codeHelperText {
    switch (_selectedMethod) {
      case TwoFactorMethod.sms:
        return 'Code will be sent via SMS to your phone number.';
      case TwoFactorMethod.phoneCall:
        return 'Code will be read to you via an automated phone call.';
      case TwoFactorMethod.authenticatorApp:
        return 'Open your Google Authenticator (or any TOTP app) and enter the 6-digit code.';
      default:
        return null;
    }
  }

  bool get _canVerify {
    if (_selectedMethod == null) return false;
    if (_isDemoBypass) return true;
    if (!_codeIsValid(_trimmedCode)) return false;
    if (_needsPhone && !_isPhoneValid(_phoneController.text.trim())) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    final methods = _pending?.availableMethods;
    _selectedMethod =
        (methods != null && methods.isNotEmpty) ? methods.first : null;
    final savedPhone = _pending?.savedPhoneNumber ??
        AuthService.instance.pendingTwoFactorPhoneNumber ??
        '';
    if (savedPhone.isNotEmpty) {
      _phoneController.text = savedPhone;
      _hasSavedPhoneOnAccount = true;
      _isEditingPhone = false;
    }
    if (_selectedMethod == TwoFactorMethod.authenticatorApp) {
      AuthService.instance.setPendingTwoFactorMethod(
        TwoFactorMethod.authenticatorApp,
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  bool _isPhoneMethod(TwoFactorMethod method) {
    return method == TwoFactorMethod.sms || method == TwoFactorMethod.phoneCall;
  }

  bool _isPhoneValid(String value) {
    final normalized = value.replaceAll(RegExp(r'[^+0-9]'), '');
    final digitsOnly = normalized.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 7 || digitsOnly.length > 15) {
      return false;
    }
    return digitsOnly.isNotEmpty;
  }

  bool _codeIsValid(String value) {
    return _sixDigitCodeRegExp.hasMatch(value.trim());
  }

  Future<void> _sendCode() async {
    final method = _selectedMethod;
    if (method == null || _pending == null || !_isPhoneMethod(method)) return;
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      setState(() {
        _phoneError = 'Enter a phone number to use this option.';
      });
      return;
    }
    if (!_isPhoneValid(rawPhone)) {
      setState(() {
        _phoneError = 'Enter a valid phone number to use this option.';
      });
      return;
    }
    setState(() {
      _isRequestingCode = true;
      _error = null;
      _phoneError = null;
      _statusMessage = null;
    });
    try {
      await AuthService.instance.requestTwoFactorCode(
        method,
        phoneNumber: rawPhone,
      );
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _statusMessage = 'Code sent via ${_methodLabel(method)}.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to send a code right now. Try again shortly.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isRequestingCode = false;
      });
    }
  }

  Future<void> _verifyCode() async {
    final pending = _pending;
    final method = _selectedMethod;
    if (pending == null || method == null) return;
    final code = _trimmedCode;
    final isDemoBypassCode = _isDemoBypass;
    if (!isDemoBypassCode && !_codeIsValid(code)) {
      setState(() {
        _codeError = method == TwoFactorMethod.authenticatorApp
            ? 'Enter the 6-digit code from your authenticator app.'
            : 'Enter the 6-digit code we sent to you.';
      });
      return;
    }
    if (_isPhoneMethod(method) && !isDemoBypassCode) {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        setState(() {
          _phoneError = 'Enter a phone number to use this option.';
        });
        return;
      }
      if (!_isPhoneValid(phone)) {
        setState(() {
          _phoneError = 'Enter a valid phone number to use this option.';
        });
        return;
      }
    }
    setState(() {
      _isVerifying = true;
      _error = null;
      _codeError = null;
    });
    final authService = AuthService.instance;
    final bool success;
    if (isDemoBypassCode) {
      await authService.completeTwoFactorWithoutRemoteCheck();
      success = true;
    } else {
      success = await authService.verifyTwoFactorCode(code);
    }
    if (success) {
      if (!mounted) return;
      final nextRoute = pending.showOnboardingAfterSuccess
          ? AppRoutes.globalOnboarding
          : AppRoutes.home;
      final nextArguments = pending.showOnboardingAfterSuccess
          ? GlobalOnboardingFlowArguments(
              userId: pending.userId,
              isNewlyRegistered: pending.showOnboardingAfterSuccess,
            )
          : null;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TwoFactorSuccessScreen(
            nextRoute: nextRoute,
            nextRouteArguments: nextArguments,
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _error = 'The code is incorrect or expired. Please try again.';
      _isVerifying = false;
    });
  }

  void _onPhoneChanged(String value) {
    if (_phoneError != null && _isPhoneValid(value.trim())) {
      setState(() => _phoneError = null);
    }
  }

  void _onCodeChanged(String value) {
    if (_codeError != null && _codeIsValid(value)) {
      setState(() => _codeError = null);
    }
  }

  void _startEditingPhone() {
    if (_isEditingPhone) return;
    setState(() {
      _isEditingPhone = true;
    });
    FocusScope.of(context).requestFocus(_phoneFocusNode);
  }

  void _onMethodChanged(TwoFactorMethod? method) {
    if (method == null) return;
    _codeController.clear();
    setState(() {
      _selectedMethod = method;
      _codeSent = false;
      _statusMessage = null;
      _error = null;
      _phoneError = null;
      _codeError = null;
    });
    if (method == TwoFactorMethod.authenticatorApp) {
      AuthService.instance.setPendingTwoFactorMethod(method);
    }
  }

  void _switchToPhoneMethod() {
    final pending = _pending;
    if (pending == null) return;
    final fallback = pending.availableMethods.firstWhere(
      _isPhoneMethod,
      orElse: () => _selectedMethod ?? TwoFactorMethod.sms,
    );
    if (!_isPhoneMethod(fallback) || fallback == _selectedMethod) {
      return;
    }
    _onMethodChanged(fallback);
  }

  String _methodLabel(TwoFactorMethod method) {
    switch (method) {
      case TwoFactorMethod.sms:
        return 'Text message (SMS)';
      case TwoFactorMethod.phoneCall:
        return 'Phone call';
      case TwoFactorMethod.authenticatorApp:
        return 'Authenticator app';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pending == null) {
      // Guard against deep links arriving here without a pending two-factor state.
      return Scaffold(
        appBar: AppBar(title: const Text('Two-Factor Verification')),
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Return to login'),
          ),
        ),
      );
    }
    final pending = _pending!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final codeHint = _codeHint;
    return Scaffold(
      appBar: AppBar(title: const Text('Two-Factor Verification')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Two-Factor Verification',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                _subtitleText,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
              ),
              if (codeHint != null) ...[
                const SizedBox(height: 12),
                Text(
                  codeHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Choose how to receive your 6-digit code:',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              DropdownButton<TwoFactorMethod>(
                value: _selectedMethod,
                isExpanded: true,
                onChanged: _isRequestingCode ? null : _onMethodChanged,
                items: pending.availableMethods
                    .map(
                      (method) => DropdownMenuItem(
                        value: method,
                        child: Text(_methodLabel(method)),
                      ),
                    )
                    .toList(),
              ),
              if (_needsPhone) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9+\-\s\(\)]'),
                    ),
                  ],
                  readOnly: _hasSavedPhoneOnAccount && !_isEditingPhone,
                  onTap: _hasSavedPhoneOnAccount && !_isEditingPhone
                      ? _startEditingPhone
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Phone number',
                    hintText: 'Enter your mobile number',
                    helperText:
                        'Required for Text message (SMS) and Phone call methods.',
                    prefixIcon: const Icon(Icons.phone),
                    errorText: _phoneError,
                    suffix: _hasSavedPhoneOnAccount && !_isEditingPhone
                        ? TextButton(
                            onPressed: _startEditingPhone,
                            child: const Text('Change'),
                          )
                        : null,
                  ),
                  onChanged: _onPhoneChanged,
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Verification code',
                  prefixIcon: const Icon(Icons.lock_outline),
                  helperText: _codeHelperText,
                  errorText: _codeError,
                ),
                onChanged: _onCodeChanged,
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              if (_statusMessage != null)
                Text(
                  _statusMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              const SizedBox(height: 16),
              if (_needsPhone)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isRequestingCode ? null : _sendCode,
                        icon: const Icon(Icons.send),
                        label: Text(_codeSent ? 'Resend code' : 'Send code'),
                      ),
                    ),
                  ],
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _isRequestingCode ? null : _switchToPhoneMethod,
                    child: const Text('Use a different method'),
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: (!_isVerifying && _canVerify) ? _verifyCode : null,
                child: _isVerifying
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
