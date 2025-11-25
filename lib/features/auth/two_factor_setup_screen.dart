import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/routing/app_routes.dart';
import '../../shared/prefs_keys.dart';
import '../auth/auth_service.dart';
import '../auth/demo_credentials.dart';

class TwoFactorSetupScreen extends StatefulWidget {
  const TwoFactorSetupScreen({
    super.key,
    required this.userId,
    this.email,
  });

  static const routeName = '/two-factor-setup';

  final String userId;
  final String? email;

  @override
  State<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends State<TwoFactorSetupScreen> {
  TwoFactorMethod? _selectedMethod;
  final TextEditingController _codeController = TextEditingController();
  bool _isPreparing = true;
  bool _isRequestingCode = false;
  bool _isVerifying = false;
  bool _codeSent = false;
  String? _error;
  String? _statusMessage;
  String? _emailForSetup;

  PendingTwoFactorSession? get _pending =>
      AuthService.instance.pendingTwoFactorSession;

  @override
  void initState() {
    super.initState();
    _prepareSetup();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _prepareSetup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = widget.email ?? prefs.getString(PrefsKeys.authEmail);
      if (email == null) {
        setState(() {
          _error = 'Unable to determine your email for configuring 2FA.';
          _isPreparing = false;
        });
        return;
      }
      _emailForSetup = email;
      await AuthService.instance.startTwoFactorSetup(
        userId: widget.userId,
        email: email,
      );
      final methods = AuthService.instance.pendingTwoFactorSession?.availableMethods;
      if (methods != null && methods.isNotEmpty) {
        setState(() {
          _selectedMethod = methods.first;
          _isPreparing = false;
        });
        await _sendCode();
      } else {
        if (!mounted) return;
        setState(() => _isPreparing = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to start the 2FA setup process right now.';
        _isPreparing = false;
      });
    }
  }

  Future<void> _sendCode() async {
    if (_pending == null || _selectedMethod == null) return;
    setState(() {
      _isRequestingCode = true;
      _error = null;
    });
    try {
      await AuthService.instance.requestTwoFactorCode(_selectedMethod!);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _statusMessage = 'Code sent via ${_methodLabel(_selectedMethod!)}.';
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
    if (pending == null) return;
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _error = 'Enter the 6-digit code we sent to you.';
      });
      return;
    }
    setState(() {
      _isVerifying = true;
      _error = null;
    });
    final success = await AuthService.instance.verifyTwoFactorCode(code);
    if (success) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _error = 'The code is incorrect or expired. Please try again.';
      _isVerifying = false;
    });
  }

  String _methodLabel(TwoFactorMethod method) {
    switch (method) {
      case TwoFactorMethod.sms:
        return 'SMS to your phone';
      case TwoFactorMethod.phoneCall:
        return 'Phone call';
      case TwoFactorMethod.googleDuo:
        return 'Authenticator app';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pending;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Set up Two-Factor Authentication')),
      body: SafeArea(
        child: _isPreparing || pending == null
            ? Center(
                child: _isPreparing
                    ? const CircularProgressIndicator()
                    : Text(
                        _error ?? 'Unable to initialize 2FA setup.',
                      ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secure your account',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Two-factor authentication keeps your medical history and care team '
                      'conversations safe. Complete setup before entering the app.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.onBackground.withOpacity(0.7)),
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Development builds skip real SMS/email delivery. Enter '
                        '$demoVerificationCode to finish setup.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                    if (_emailForSetup != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'We will send codes to the contact we have on file (${_emailForSetup!}).',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colorScheme.onBackground.withOpacity(0.7)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Choose how to receive your code:',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<TwoFactorMethod>(
                      value: _selectedMethod,
                      isExpanded: true,
                      onChanged: _isRequestingCode ? null : (value) {
                        setState(() {
                          _selectedMethod = value;
                        });
                      },
                      items: pending.availableMethods
                          .map(
                            (method) => DropdownMenuItem(
                              value: method,
                              child: Text(_methodLabel(method)),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Verification code',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_error != null)
                      Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                      ),
                    if (_statusMessage != null)
                      Text(
                        _statusMessage!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colorScheme.onBackground.withOpacity(0.7)),
                      ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isRequestingCode ? null : _sendCode,
                      icon: const Icon(Icons.send),
                      label: Text(_codeSent ? 'Resend code' : 'Send code'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _isVerifying ? null : _verifyCode,
                      child: _isVerifying
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Verify and finish setup'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
