import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/routing/app_routes.dart';
import '../onboarding/global_onboarding_screen.dart';
import 'auth_service.dart';
import 'demo_credentials.dart';

class TwoFactorScreen extends StatefulWidget {
  const TwoFactorScreen({super.key});

  static const routeName = '/two-factor';

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  TwoFactorMethod? _selectedMethod;
  final TextEditingController _codeController = TextEditingController();
  bool _isRequestingCode = false;
  bool _isVerifying = false;
  bool _codeSent = false;
  String? _error;
  String? _statusMessage;

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

  @override
  void initState() {
    super.initState();
    final methods = _pending?.availableMethods;
    _selectedMethod =
        (methods != null && methods.isNotEmpty) ? methods.first : null;
    if (_selectedMethod != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
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
    // 2FA is required by the backend, so only this path lets the user finish login.
    final success = await AuthService.instance.verifyTwoFactorCode(code);
    if (success) {
      if (!mounted) return;
      if (pending.showOnboardingAfterSuccess) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => GlobalOnboardingScreen(
              userId: pending.userId,
              isNewlyRegistered: pending.showOnboardingAfterSuccess,
            ),
          ),
        );
        return;
      }
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
      );
      return;
    }
    if (mounted) {
      setState(() {
        _error = 'The code is incorrect or expired. Please try again.';
      });
    }
    if (!mounted) return;
    setState(() {
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
                'We need one more proof of identity before giving you access.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onBackground.withOpacity(0.7)),
              ),
              const SizedBox(height: 24),
              if (codeHint != null) ...[
                Text(
                  codeHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Choose how to receive your 6-digit code:',
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
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                ),
              if (_statusMessage != null)
                Text(
                  _statusMessage!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onBackground.withOpacity(0.7)),
                ),
              const SizedBox(height: 16),
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
                    : const Text('Verify'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
