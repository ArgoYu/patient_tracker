import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/routing/app_routes.dart';
import '../../shared/prefs_keys.dart';
import '../onboarding/global_onboarding_screen.dart';
import 'demo_credentials.dart';
import 'mock_auth_api.dart';
import 'auth_service.dart';
import 'two_factor_setup_screen.dart';

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

  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isLogin = true;
  bool _busy = false;
  bool _sendingCode = false;
  bool _codeSent = false;
  int _secondsLeft = 0;
  String? _error;
  Timer? _timer;
  LoginMethod _preferredLoginMethod = LoginMethod.password2fa;
  bool _biometricAvailable = false;
  bool _biometricPrompting = false;
  bool _showPasswordForm = true;
  String? _biometricError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeBiometricPreference();
  }

  Future<void> _initializeBiometricPreference() async {
    final method = await AuthService.instance.loadPreferredLoginMethod();
    bool canUseBiometrics = false;
    if (method == LoginMethod.biometrics) {
      try {
        final canCheck = await _localAuth.canCheckBiometrics;
        final available = await _localAuth.getAvailableBiometrics();
        canUseBiometrics = canCheck && available.isNotEmpty;
      } on PlatformException {
        canUseBiometrics = false;
      }
    }
    if (!mounted) return;
    setState(() {
      _preferredLoginMethod = method;
      _biometricAvailable = method == LoginMethod.biometrics && canUseBiometrics;
      _showPasswordForm = method != LoginMethod.biometrics || !canUseBiometrics;
      _biometricError = !canUseBiometrics && method == LoginMethod.biometrics
          ? 'Biometrics are not available on this device.'
          : null;
    });
    if (method == LoginMethod.biometrics && canUseBiometrics) {
      await _promptBiometric();
    }
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

  Future<void> _promptBiometric() async {
    setState(() {
      _biometricPrompting = true;
      _biometricError = null;
    });
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Use Face ID or fingerprint to continue to Patient Tracker.',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!authenticated) {
        if (!mounted) return;
        setState(() {
          _showPasswordForm = true;
          _biometricError = 'Biometric authentication was canceled.';
        });
        return;
      }
      final restored = await AuthService.instance.restoreSessionFromStorage();
      if (!restored) {
        if (!mounted) return;
        setState(() {
          _showPasswordForm = true;
          _biometricError = 'Unable to use saved credentials. Sign in manually.';
        });
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _showPasswordForm = true;
        _biometricError =
            e.message ?? 'Biometric authentication failed. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _showPasswordForm = true;
        _biometricError = 'Biometric authentication failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _biometricPrompting = false;
        });
      }
    }
  }

  void _showPasswordLoginForm() {
    setState(() {
      _showPasswordForm = true;
      _biometricError = 'Use your password and 2FA to continue.';
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

  /// Demo-only helper to prefill the presentation account.
  void _useDemoCredentials() {
    if (!kDebugMode) return;
    if (!_isLogin) {
      _switchMode(true);
    }
    _timer?.cancel();
    setState(() {
      _emailController.text = demoAuthEmail;
      _passwordController.text = demoAuthPassword;
      _confirmController.text = demoAuthPassword;
      _codeController.clear();
      _codeSent = false;
      _secondsLeft = 0;
      _error = null;
    });
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
      if (_isLogin) {
        final result = await AuthService.instance.login(
          email: email,
          password: password,
        );
        await _completeLogin(email, result);
        return;
      }

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
      AuthService.instance.markPendingGlobalOnboarding();
      final result = await AuthService.instance.login(
        email: email,
        password: password,
<<<<<<< HEAD
=======
        rememberMe: _rememberMe,
        showGlobalOnboarding: true,
>>>>>>> 3d14e5a (2FA set up after sign up)
      );
      await _completeLogin(email, result);
      return;
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
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

  Future<void> _completeLogin(String email, AuthLoginResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.emailVerified, true);
    await prefs.setString(PrefsKeys.authEmail, email);

    if (result.requiresTwoFactorChallenge) {
      if (!mounted) return;
      Navigator.of(context).pushNamed(AppRoutes.twoFactor);
      return;
    }

    if (result.requiresTwoFactorSetup) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TwoFactorSetupScreen(
            userId: result.userId,
            email: email,
          ),
        ),
      );
      return;
    }

    if (result.showGlobalOnboarding) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GlobalOnboardingScreen(
            userId: result.userId,
            isNewlyRegistered: result.showGlobalOnboarding,
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  Widget _buildCredentialsCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
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
                      onPressed: (_busy || _sendingCode || _secondsLeft > 0)
                          ? null
                          : _handleSendCode,
                      child: _sendingCode
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
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
                  color: colorScheme.onBackground.withOpacity(0.7),
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isLogin ? 'Log in' : 'Create account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricPrompt(ThemeData theme, ColorScheme colorScheme) {
    final statusText = _biometricError ??
        'Authenticate with Face ID or fingerprint to continue.';
    return Card(
      elevation: 0,
      color: colorScheme.surface.withOpacity(0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primary.withOpacity(0.15),
                child: Icon(
                  Icons.fingerprint,
                  size: 32,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Use Face ID / fingerprint',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              statusText,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onBackground.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.fingerprint),
              onPressed: !_biometricAvailable || _biometricPrompting
                  ? null
                  : _promptBiometric,
              label: Text(
                _biometricPrompting ? 'Authenticating...' : 'Try Face ID / fingerprint',
              ),
            ),
            TextButton(
              onPressed: _biometricPrompting ? null : _showPasswordLoginForm,
              child: const Text('Sign in with password instead'),
            ),
          ],
        ),
      ),
    );
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
                  if (_preferredLoginMethod == LoginMethod.biometrics &&
                      !_showPasswordForm)
                    _buildBiometricPrompt(theme, colorScheme)
                  else
                    _buildCredentialsCard(theme, colorScheme),
                  const SizedBox(height: 12),
                  if (kDebugMode && _isLogin) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _busy ? null : _useDemoCredentials,
                        child: const Text('Use demo account'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
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
