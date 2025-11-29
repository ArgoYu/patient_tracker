import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
  final TextEditingController _phoneController = TextEditingController();
  bool _isPreparing = true;
  bool _isRequestingCode = false;
  bool _isVerifying = false;
  bool _codeSent = false;
  String? _error;
  String? _statusMessage;
  String? _phoneError;
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
    _phoneController.dispose();
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
      final savedPhone = AuthService.instance.pendingTwoFactorPhoneNumber;
      if (savedPhone != null) {
        _phoneController.text = savedPhone;
      }
      if (methods != null && methods.isNotEmpty) {
        final defaultMethod = methods.firstWhere(
          (method) => !_requiresPhone(method),
          orElse: () => methods.first,
        );
        if (!mounted) return;
        setState(() {
          _selectedMethod = defaultMethod;
          _isPreparing = false;
        });
        _maybeAutoSendCode();
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
    if (_pending == null) return;
    final method = _selectedMethod;

    if (method == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a verification method.')),
      );
      return;
    }

    final requiresPhone = _requiresPhone(method);
    String? phoneNumber;

    if (requiresPhone) {
      final raw = _phoneController.text.trim();
      if (raw.isEmpty) {
        setState(() {
          _phoneError = 'Enter a phone number to use this option.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your phone number.')),
        );
        return;
      }
      if (!_isPhoneValid(raw)) {
        setState(() {
          _phoneError = 'Enter a valid phone number to use this option.';
        });
        return;
      }
      phoneNumber = raw;
    } else {
      phoneNumber = null;
    }

    setState(() {
      _isRequestingCode = true;
      _error = null;
      _phoneError = null;
      _statusMessage = null;
    });

    try {
      // DEBUG: make sure we really pass the number down
      // (You can remove these prints later.)
      debugPrint(
        '[_sendCode] method=$method, phoneNumber="$phoneNumber" (requiresPhone=$requiresPhone)',
      );
      await AuthService.instance.requestTwoFactorCode(
        method,
        phoneNumber: phoneNumber,
      );
      _goToCodeEntryStep(method);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Failed to start verification.'),
        ),
      );
      setState(() {
        _error = e.message ?? 'Unable to send a code right now. Try again shortly.';
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

  void _goToCodeEntryStep(TwoFactorMethod method) {
    if (!mounted) return;
    setState(() {
      _codeSent = true;
      _statusMessage = method == TwoFactorMethod.googleDuo
          ? 'Authenticator app setup ready. Scan the QR code or enter the secret manually.'
          : 'Code sent via ${_methodLabel(method)}.';
    });
  }

  Future<void> _verifyCode() async {
    final pending = _pending;
    if (pending == null) return;
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _error = _selectedMethod == TwoFactorMethod.googleDuo
            ? 'Enter the 6-digit code from your app.'
            : 'Enter the 6-digit code we sent to you.';
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

  bool get _hasValidPhone => _isPhoneValid(_phoneController.text);

  bool _requiresPhone(TwoFactorMethod method) =>
      method == TwoFactorMethod.sms || method == TwoFactorMethod.phoneCall;

  bool get _hasPhoneMethodAvailable =>
      _pending?.availableMethods.any(_requiresPhone) ?? false;

  void _onPhoneChanged(String value) {
    setState(() {
      if (_phoneError != null && _isPhoneValid(value)) {
        _phoneError = null;
      }
    });
  }

  bool _isPhoneValid(String value) {
    final normalized = value.replaceAll(RegExp(r'[^+0-9]'), '');
    final digitsOnly = normalized.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 7 || digitsOnly.length > 15) {
      return false;
    }
    return digitsOnly.isNotEmpty;
  }

  void _maybeAutoSendCode() {
    if (!mounted) return;
    if (_selectedMethod == null) return;
    final method = _selectedMethod!;
    if (method == TwoFactorMethod.googleDuo) {
      _sendCode();
      return;
    }
    if (_hasValidPhone) {
      _sendCode();
    }
  }

  Widget _buildAuthenticatorSetupPanel(
    ThemeData theme,
    ColorScheme colorScheme,
    TotpProvision? provision,
  ) {
    final textTheme = theme.textTheme;
    final manualSecret = provision?.secret ?? '';
    final formattedSecret = _formatSecret(manualSecret);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Download an authenticator app (we recommend Google Authenticator) on your phone.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Scan this QR code or enter the code manually.',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: provision == null
              ? const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                )
              : QrImageView(
                  data: provision.provisioningUri,
                  version: QrVersions.auto,
                  size: 180,
                  gapless: true,
                ),
        ),
        const SizedBox(height: 12),
        Text(
          'Manual secret key',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        provision != null
            ? SelectableText(
                formattedSecret,
                style: textTheme.bodyMedium?.copyWith(letterSpacing: 1),
              )
            : Text(
                'Secret will appear here once the QR is ready.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
      ],
    );
  }

  String _formatSecret(String secret) {
    final cleaned = secret.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (cleaned.isEmpty) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleaned[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pending;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totpProvision = AuthService.instance.pendingTwoFactorTotpProvision;
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
                          ?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
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
                            ?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (_hasPhoneMethodAvailable) ...[
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s\(\)]')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Phone number',
                          hintText: 'Enter your mobile number',
                          helperText: 'Required for SMS and phone call methods.',
                          prefixIcon: const Icon(Icons.phone),
                          errorText: _phoneError,
                        ),
                        onChanged: _onPhoneChanged,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Choose how to receive your code:',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<TwoFactorMethod>(
                      value: _selectedMethod,
                      isExpanded: true,
                      onChanged: _isRequestingCode
                          ? null
                          : (value) {
                              if (value == null) return;
                              if (_requiresPhone(value) && !_hasValidPhone) {
                                setState(() {
                                  _phoneError =
                                      'Enter a valid phone number to use this option.';
                                });
                                return;
                              }
                              setState(() {
                                _codeSent = false;
                                _selectedMethod = value;
                                _phoneError = null;
                                _statusMessage = null;
                              });
                              _codeController.clear();
                              _maybeAutoSendCode();
                            },
                      items: pending.availableMethods
                          .map(
                            (method) {
                              final enabled = !_requiresPhone(method) || _hasValidPhone;
                              return DropdownMenuItem(
                                value: method,
                                enabled: enabled,
                                child: Text(_methodLabel(method)),
                              );
                            },
                          )
                          .toList(),
                    ),
                    if (_selectedMethod == TwoFactorMethod.googleDuo) ...[
                      const SizedBox(height: 16),
                      _buildAuthenticatorSetupPanel(theme, colorScheme, totpProvision),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _selectedMethod == TwoFactorMethod.googleDuo
                            ? 'Enter 6-digit code from your app'
                            : 'Verification code',
                        prefixIcon: const Icon(Icons.lock_outline),
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
                            ?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
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
