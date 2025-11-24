import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/routing/app_routes.dart';
import '../../shared/prefs_keys.dart';
import 'mock_auth_api.dart';

class AuthGatePage extends StatefulWidget {
  const AuthGatePage({super.key});

  static const routeName = '/auth';

  @override
  State<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends State<AuthGatePage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _isLogin = true;
  bool _busy = false;
  bool _sendingCode = false;
  bool _codeSent = false;
  int _secondsLeft = 0;
  String? _error;
  Timer? _timer;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _switchMode(bool login) {
    setState(() {
      _isLogin = login;
      _error = null;
      if (login) {
        _timer?.cancel();
        _secondsLeft = 0;
        _codeSent = false;
        _codeController.clear();
      }
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() => _secondsLeft = 0);
        }
      } else {
        if (mounted) {
          setState(() => _secondsLeft -= 1);
        }
      }
    });
  }

  Future<void> _handleSendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_isValidEmail(email)) {
      setState(() {
        _error = 'Enter a valid email before requesting a code.';
      });
      return;
    }
    setState(() {
      _sendingCode = true;
      _error = null;
    });
    try {
      final code = await MockAuthApi.instance.sendEmailCode(email);
      if (!mounted) return;
      _startCountdown();
      setState(() {
        _codeSent = true;
      });
      // Demo helper so testers can complete the flow without email.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification code sent. Use $code to verify in this demo build.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to send a verification code right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _sendingCode = false;
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final code = _codeController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Enter your email and password to continue.';
      });
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() {
        _error = 'Enter a valid email address to continue.';
      });
      return;
    }
    if (!_isLogin && password != confirm) {
      setState(() {
        _error = 'Passwords must match.';
      });
      return;
    }
    if (!_isLogin && !_codeSent) {
      setState(() {
        _error = 'Please request a verification code first.';
      });
      return;
    }
    if (!_isLogin && code.isEmpty) {
      setState(() {
        _error = 'Enter the verification code we sent to your email.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      if (_isLogin) {
        final storedEmail = prefs.getString(PrefsKeys.authEmail);
        final emailVerified = prefs.getBool(PrefsKeys.emailVerified) ?? false;
        if (storedEmail != email || !emailVerified) {
          if (!mounted) return;
          setState(() {
            _error =
                'This email is not verified yet. Please complete sign up first.';
          });
          return;
        }
        await prefs.setString(PrefsKeys.authEmail, email);
      } else {
        try {
          await MockAuthApi.instance.verifyEmailCode(email: email, code: code);
        } on EmailCodeException catch (e) {
          if (!mounted) return;
          setState(() {
            _error = e.type == EmailCodeError.expired
                ? 'Verification code has expired. Please request a new one.'
                : 'Verification code is incorrect.';
          });
          return;
        }
        await MockAuthApi.instance.register(email: email, password: password);
        await prefs.setBool(PrefsKeys.emailVerified, true);
        await prefs.setString(PrefsKeys.authEmail, email);
      }
      await prefs.setBool(PrefsKeys.isLoggedIn, true);
      await prefs.setString(PrefsKeys.authToken, 'local-demo-token');

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to continue. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = _isLogin ? 'Welcome back' : 'Create your account';
    final subtitle = _isLogin
        ? 'Log in to sync your chats, Echo AI, and care plan.'
        : 'Sign up to unlock the main app experience.';

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patient Tracker',
                    style: theme.textTheme.labelLarge?.copyWith(
                      letterSpacing: 1.2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    children: [
                      ChoiceChip(
                        label: const Text('Log in'),
                        selected: _isLogin,
                        onSelected: (_) => _switchMode(true),
                      ),
                      ChoiceChip(
                        label: const Text('Create account'),
                        selected: !_isLogin,
                        onSelected: (_) => _switchMode(false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    color: colorScheme.surface.withOpacity(0.9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                          if (!_isLogin) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _confirmController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Confirm password',
                                prefixIcon: Icon(Icons.lock_reset_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _codeController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Verification code',
                                      prefixIcon: Icon(Icons.verified_outlined),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 170,
                                  child: ElevatedButton(
                                    onPressed: (_busy ||
                                            _sendingCode ||
                                            _secondsLeft > 0)
                                        ? null
                                        : _handleSendCode,
                                    child: _sendingCode
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : Text(
                                            _secondsLeft > 0
                                                ? 'Resend in ${_secondsLeft}s'
                                                : _codeSent
                                                    ? 'Resend code'
                                                    : 'Send verification code',
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'We have sent a 6-digit code to your email. Please enter it here to complete registration.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    colorScheme.onBackground.withOpacity(0.7),
                              ),
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: colorScheme.error),
                            ),
                          ],
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _busy ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _busy
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text(_isLogin ? 'Log in' : 'Create account'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _busy ? null : () => _switchMode(!_isLogin),
                    child: Text(
                      _isLogin
                          ? 'Need an account? Create one'
                          : 'Already registered? Log in',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'After signing in, you will move directly into the main app.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
