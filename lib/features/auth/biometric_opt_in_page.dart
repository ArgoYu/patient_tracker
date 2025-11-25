import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/routing/app_routes.dart';
import '../../features/auth/auth_service.dart';
import '../../shared/utils/toast.dart';

class BiometricOptInScreen extends StatefulWidget {
  const BiometricOptInScreen({super.key});

  static const routeName = '/post-login';

  @override
  State<BiometricOptInScreen> createState() => _BiometricOptInScreenState();
}

class _BiometricOptInScreenState extends State<BiometricOptInScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _biometricAvailable = false;
  bool _enabling = false;
  bool _enabled = false;
  String? _statusMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _detectBiometricSupport();
  }

  Future<void> _detectBiometricSupport() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final available = await _localAuth.getAvailableBiometrics();
      if (!mounted) return;
      setState(() {
        _biometricAvailable = canCheck && available.isNotEmpty;
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() {
        _biometricAvailable = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (!_biometricAvailable) return;
    if (!enable) {
      await AuthService.instance.disableBiometricLogin();
      if (!mounted) return;
      setState(() {
        _enabled = false;
        _statusMessage = 'Password + 2FA will be required on this device.';
        _errorMessage = null;
      });
      return;
    }
    setState(() {
      _enabling = true;
      _errorMessage = null;
    });
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Confirm your identity to enable Face ID / fingerprint.',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!authenticated) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Biometric confirmation was canceled.';
        });
        return;
      }
      final enabled = await AuthService.instance.enableBiometricLogin();
      if (!enabled) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Unable to save biometric preferences right now.';
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _enabled = true;
        _statusMessage = 'Face ID / fingerprint is enabled for future logins on this device.';
      });
      showToast(context, 'Biometric login enabled for this device.');
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            e.message ?? 'Biometric confirmation failed. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Biometric confirmation failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _enabling = false);
      }
    }
  }

  void _continueToApp() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome back'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: colorScheme.primary.withOpacity(0.15),
                  child: Icon(
                    Icons.check_circle,
                    size: 44,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sign-in preferences',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Your account is ready. Enable Face ID or fingerprint to skip entering your password and 2FA on this device.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text(
                  'Use Face ID / fingerprint next time (skip password & 2FA on this device)',
                ),
                subtitle: Text(
                  _biometricAvailable
                      ? 'You can always change this in Account settings.'
                      : 'Biometrics are not available on this device.',
                ),
                value: _enabled,
                onChanged: _biometricAvailable && !_enabling ? _toggleBiometric : null,
              ),
              if (_statusMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _statusMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _continueToApp,
                child: const Text('Continue to the app'),
              ),
              const SizedBox(height: 12),
              Text(
                'You can revisit this later at any time from Settings → Account → Sign-in method.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
