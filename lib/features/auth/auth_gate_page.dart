import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/routing/app_routes.dart';
import '../../core/theme/theme_tokens.dart';
import '../../shared/prefs_keys.dart';
import '../onboarding/global_onboarding_screen.dart';
import 'demo_credentials.dart';
import 'mock_auth_api.dart';
import 'auth_service.dart';
import 'two_factor_setup_screen.dart';
import 'welcome_back_screen.dart';

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
  bool _pageVisible = false;

  /// Controls whether the secure token/refresh info is persisted for future runs.
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _pageVisible = true);
      }
    });
  }

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

  InputDecoration _inputDecoration({
    required ColorScheme colorScheme,
    required String label,
    required IconData icon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      helperMaxLines: 2,
      prefixIcon: Icon(
        icon,
        size: 18,
        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    );
  }

  Widget _buildSegmentedControl(ThemeData theme, ColorScheme colorScheme) {
    final radius = BorderRadius.circular(AppThemeTokens.smallRadius);
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.6),
          ),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              alignment:
                  _isLogin ? Alignment.centerLeft : Alignment.centerRight,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    borderRadius: radius,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _busy ? null : () => _switchMode(true),
                    style: TextButton.styleFrom(
                      foregroundColor: _isLogin
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant.withOpacity(0.8),
                      textStyle: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: radius),
                    ),
                    child: const Text('Log in'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: _busy ? null : () => _switchMode(false),
                    style: TextButton.styleFrom(
                      foregroundColor: !_isLogin
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant.withOpacity(0.8),
                      textStyle: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: radius),
                    ),
                    child: const Text('Create account'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(ThemeData theme, ColorScheme colorScheme) {
    final mutedBlue = colorScheme.primary.withOpacity(0.65);
    final secondaryStyle = TextButton.styleFrom(
      foregroundColor: mutedBlue,
      textStyle: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w500,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (kDebugMode && _isLogin)
          TextButton(
            onPressed: _busy ? null : _useDemoCredentials,
            style: secondaryStyle,
            child: const Text('Use demo account'),
          ),
        TextButton(
          onPressed: _busy ? null : () => _switchMode(!_isLogin),
          style: secondaryStyle,
          child: Text(
            _isLogin
                ? 'Need an account? Create one'
                : 'Already registered? Log in',
          ),
        ),
        Text(
          'After signing in, you will move directly into the main app.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withOpacity(0.8),
          ),
        ),
      ],
    );
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
      _emailController.text = demoEmail;
      _passwordController.text = demoPassword;
      _confirmController.text = demoPassword;
      _codeController.clear();
      _rememberMe = true;
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
          rememberMe: _rememberMe,
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
      await MockAuthApi.instance.register(
        email: email,
        password: password,
      );
      final result = await AuthService.instance.login(
        email: email,
        password: password,
        rememberMe: _rememberMe,
        showGlobalOnboarding: true,
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
    final account = AuthService.instance.currentUserAccount;
    final displayName = account?.preferredName ??
        account?.legalName ??
        account?.displayName ??
        email;
    // Used after login for returning users; first-time users go to onboarding flow.
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WelcomeBackScreen(displayName: displayName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = _isLogin ? 'Welcome back' : 'Create your account';
    final subtitle = _isLogin
        ? 'Securely access your care plan, Echo AI, and health history.'
        : 'A secure space to track your health, mood, and care journey.';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 28,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: AnimatedOpacity(
                  opacity: _pageVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: AnimatedSlide(
                    offset: _pageVisible ? Offset.zero : const Offset(0, 0.02),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Patient Tracker',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    letterSpacing: 1.4,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  title,
                                  style:
                                      theme.textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  subtitle,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color:
                                        colorScheme.onSurface.withOpacity(0.72),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                _buildSegmentedControl(theme, colorScheme),
                                const SizedBox(height: 20),
                                Card(
                                  elevation: 2,
                                  shadowColor:
                                      colorScheme.shadow.withOpacity(0.18),
                                  color: colorScheme.surfaceContainerLow
                                      .withOpacity(0.9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppThemeTokens.cardRadius + 4,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        TextField(
                                          controller: _emailController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          autofillHints: const [
                                            AutofillHints.email
                                          ],
                                          decoration: _inputDecoration(
                                            colorScheme: colorScheme,
                                            label: 'Email',
                                            icon: Icons.email_outlined,
                                          ),
                                        ),
                                        const SizedBox(height: 22),
                                        TextField(
                                          controller: _passwordController,
                                          obscureText: true,
                                          decoration: _inputDecoration(
                                            colorScheme: colorScheme,
                                            label: 'Password',
                                            icon: Icons.lock_outline,
                                          ),
                                        ),
                                        if (!_isLogin) ...[
                                          const SizedBox(height: 22),
                                          TextField(
                                            controller: _confirmController,
                                            obscureText: true,
                                            decoration: _inputDecoration(
                                              colorScheme: colorScheme,
                                              label: 'Confirm password',
                                              icon: Icons.lock_reset_outlined,
                                            ),
                                          ),
                                          const SizedBox(height: 22),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  controller: _codeController,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration: _inputDecoration(
                                                    colorScheme: colorScheme,
                                                    label: 'Verification code',
                                                    icon:
                                                        Icons.verified_outlined,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              SizedBox(
                                                width: 160,
                                                child: AnimatedOpacity(
                                                  opacity: (_codeSent ||
                                                          _sendingCode ||
                                                          _secondsLeft > 0)
                                                      ? 0.6
                                                      : 1,
                                                  duration: const Duration(
                                                      milliseconds: 160),
                                                  curve: Curves.easeOut,
                                                  child: OutlinedButton(
                                                    onPressed: (_busy ||
                                                            _sendingCode ||
                                                            _secondsLeft > 0)
                                                        ? null
                                                        : _handleSendCode,
                                                    style: OutlinedButton
                                                        .styleFrom(
                                                      foregroundColor:
                                                          colorScheme.primary
                                                              .withOpacity(
                                                                  0.75),
                                                      side: BorderSide(
                                                        color: colorScheme
                                                            .outlineVariant
                                                            .withOpacity(0.6),
                                                      ),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          AppThemeTokens
                                                              .smallRadius,
                                                        ),
                                                      ),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        vertical: 10,
                                                      ),
                                                    ),
                                                    child: _sendingCode
                                                        ? const SizedBox(
                                                            height: 18,
                                                            width: 18,
                                                            child:
                                                                CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                            ),
                                                          )
                                                        : Text(
                                                            _secondsLeft > 0
                                                                ? 'Resend in ${_secondsLeft}s'
                                                                : _codeSent
                                                                    ? 'Resend code'
                                                                    : 'Send code',
                                                          ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'We\'ll send a short verification code to confirm your email.',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                        if (_error != null) ...[
                                          const SizedBox(height: 14),
                                          Text(
                                            _error!,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                    color: colorScheme.error),
                                          ),
                                        ],
                                        if (_isLogin) ...[
                                          const SizedBox(height: 18),
                                          // Remember me triggers secure storage so future launches can auto-login.
                                          CheckboxListTile(
                                            contentPadding: EdgeInsets.zero,
                                            controlAffinity:
                                                ListTileControlAffinity.leading,
                                            value: _rememberMe,
                                            onChanged: _busy
                                                ? null
                                                : (value) => setState(() {
                                                      _rememberMe =
                                                          value ?? false;
                                                    }),
                                            title: Text(
                                              'Remember me',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant
                                                    .withOpacity(0.8),
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 18),
                                        ElevatedButton(
                                          onPressed:
                                              _busy ? null : _handleSubmit,
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                AppThemeTokens.smallRadius,
                                              ),
                                            ),
                                            elevation: 0,
                                            shadowColor: Colors.transparent,
                                            disabledBackgroundColor: colorScheme
                                                .primary
                                                .withOpacity(0.35),
                                            disabledForegroundColor: colorScheme
                                                .onPrimary
                                                .withOpacity(0.7),
                                          ),
                                          child: _busy
                                              ? const SizedBox(
                                                  height: 18,
                                                  width: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : Text(_isLogin
                                                  ? 'Log in'
                                                  : 'Create account'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildBottomActions(theme, colorScheme),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
