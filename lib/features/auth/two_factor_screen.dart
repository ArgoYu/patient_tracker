import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../onboarding/global_onboarding_screen.dart';
import 'auth_service.dart';
import 'two_factor_controller.dart';
import 'two_factor_provider.dart';
import 'welcome_back_screen.dart';

class TwoFactorScreen extends StatefulWidget {
  const TwoFactorScreen({super.key});

  static const routeName = '/two-factor';

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  static const int _otpLength = 6;

  final List<TextEditingController> _digitControllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _digitFocusNodes =
      List.generate(_otpLength, (_) => FocusNode());
  bool _isPasting = false;

  TwoFactorController? _controller;

  PendingTwoFactorSession? get _pending =>
      AuthService.instance.pendingTwoFactorSession;

  @override
  void initState() {
    super.initState();
    final pending = _pending;
    if (pending != null) {
      final initialMethod =
          AuthService.instance.pendingTwoFactorMethod ??
              (pending.availableMethods.isNotEmpty
                  ? pending.availableMethods.first
                  : TwoFactorMethod.sms);
      final initialDestination = pending.savedPhoneNumber ??
          AuthService.instance.pendingTwoFactorPhoneNumber ??
          '';
      _controller = TwoFactorController(
        session: pending,
        provider: MockTwoFactorProvider(),
        initialMethod: initialMethod,
        initialDestination: initialDestination,
      )..addListener(_onControllerChanged);
      AuthService.instance.setPendingTwoFactorMethod(initialMethod);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    for (final controller in _digitControllers) {
      controller.dispose();
    }
    for (final node in _digitFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _syncCodeFromDigits() {
    final code = _digitControllers.map((controller) => controller.text).join();
    _controller?.setCode(code);
  }

  void _clearDigits() {
    for (final controller in _digitControllers) {
      controller.clear();
    }
    _controller?.setCode('');
    _digitFocusNodes.first.requestFocus();
  }

  void _onDigitChanged(int index, String value) {
    if (_isPasting) return;
    if (value.length > 1) {
      _handlePaste(value);
      return;
    }
    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _digitFocusNodes[index + 1].requestFocus();
      } else {
        _digitFocusNodes[index].unfocus();
      }
    } else {
      if (index > 0) {
        _digitFocusNodes[index - 1].requestFocus();
      }
    }
    _syncCodeFromDigits();
  }

  void _handlePaste(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;
    _isPasting = true;
    for (var i = 0; i < _otpLength; i++) {
      _digitControllers[i].text = i < digits.length ? digits[i] : '';
    }
    _isPasting = false;
    _syncCodeFromDigits();
    final nextIndex =
        digits.length >= _otpLength ? _otpLength - 1 : digits.length;
    _digitFocusNodes[nextIndex].requestFocus();
  }

  Future<void> _handleVerify() async {
    final controller = _controller;
    final pending = _pending;
    if (controller == null || pending == null) return;
    final success = await controller.verify();
    if (!success || !mounted) return;
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
    final account = pending.userAccount;
    final fallbackName =
        account.preferredName ?? account.legalName ?? account.displayName;
    final displayName =
        fallbackName.isNotEmpty ? fallbackName : pending.email;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WelcomeBackScreen(displayName: displayName),
      ),
    );
  }

  Future<void> _handleResend() async {
    final controller = _controller;
    if (controller == null) return;
    final success = await controller.sendCode();
    if (!success || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code sent.')),
    );
  }

  void _showChangeMethodSheet() {
    final controller = _controller;
    if (controller == null) return;
    final methods = controller.availableMethods;
    if (methods.isEmpty) return;
    final initialMethod = controller.selectedMethod;
    final initialDestination = controller.destination;
    final phoneController = TextEditingController(text: initialDestination);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        TwoFactorMethod selected = initialMethod;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final needsPhone = selected == TwoFactorMethod.sms ||
                selected == TwoFactorMethod.phoneCall;
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose a verification method',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...methods.map(
                    (method) => RadioListTile<TwoFactorMethod>(
                      value: method,
                      groupValue: selected,
                      title: Text(_methodLabel(method)),
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() => selected = value);
                        if (!(value == TwoFactorMethod.sms ||
                            value == TwoFactorMethod.phoneCall)) {
                          controller.setMethod(value);
                          _clearDigits();
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                  if (needsPhone) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9+\-\s\(\)]'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        hintText: 'Enter your mobile number',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          controller.setDestination(
                            phoneController.text.trim(),
                          );
                          controller.setMethod(selected);
                          _clearDigits();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Use this method'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(phoneController.dispose);
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

  String _subtitleForMethod(TwoFactorMethod method) {
    switch (method) {
      case TwoFactorMethod.authenticatorApp:
        return 'Enter the 6-digit code from your authenticator app.';
      case TwoFactorMethod.sms:
      case TwoFactorMethod.phoneCall:
        return 'Enter the 6-digit code we sent to your phone.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pending;
    if (pending == null) {
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
    final controller = _controller;
    if (controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final errorText = controller.errorMessage;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 36,
                    color: colorScheme.primary.withOpacity(0.8),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Verify it\'s you',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _subtitleForMethod(controller.selectedMethod),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  _OtpInputRow(
                    controllers: _digitControllers,
                    focusNodes: _digitFocusNodes,
                    onChanged: _onDigitChanged,
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error.withOpacity(0.7),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        'Didn\'t get a code?',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      TextButton(
                        onPressed: controller.isBusy ? null : _handleResend,
                        child: const Text('Resend code'),
                      ),
                      TextButton(
                        onPressed: controller.isBusy ? null : _showChangeMethodSheet,
                        child: const Text('Change method'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: (!controller.isBusy && controller.canVerify)
                          ? _handleVerify
                          : null,
                      child: controller.state == TwoFactorState.verifying
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Verify'),
                    ),
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

class _OtpInputRow extends StatelessWidget {
  const _OtpInputRow({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        controllers.length,
        (index) => SizedBox(
          width: 46,
          child: TextField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            maxLengthEnforcement: MaxLengthEnforcement.none,
            autofocus: index == 0,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            style: theme.textTheme.titleLarge,
            onChanged: (value) => onChanged(index, value),
          ),
        ),
      ),
    );
  }
}
