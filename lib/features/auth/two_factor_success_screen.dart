import 'dart:async';

import 'package:flutter/material.dart';

class TwoFactorSuccessScreen extends StatefulWidget {
  const TwoFactorSuccessScreen({
    super.key,
    required this.nextRoute,
    this.nextRouteArguments,
    this.displayDuration = const Duration(milliseconds: 1500),
  });

  final String nextRoute;
  final Object? nextRouteArguments;
  final Duration displayDuration;

  @override
  State<TwoFactorSuccessScreen> createState() => _TwoFactorSuccessScreenState();
}

class _TwoFactorSuccessScreenState extends State<TwoFactorSuccessScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.displayDuration, _navigateNext);
  }

  void _navigateNext() {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      widget.nextRoute,
      (route) => false,
      arguments: widget.nextRouteArguments,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_rounded,
                size: 96,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'All set!',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Two-factor verification succeeded.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                height: 40,
                width: 40,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
