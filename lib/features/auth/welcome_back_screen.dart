import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_modules.dart' show RootShell;
import 'success_animation_shared.dart';

typedef NextRouteBuilder = Route<void> Function(BuildContext context);

class WelcomeBackScreen extends StatefulWidget {
  const WelcomeBackScreen({
    super.key,
    required this.displayName,
    this.nextRouteBuilder,
    this.onFinished,
  });

  final String displayName;
  final NextRouteBuilder? nextRouteBuilder;
  final VoidCallback? onFinished;

  @override
  State<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends State<WelcomeBackScreen>
    with SingleTickerProviderStateMixin {
  static const _kNavigationDelay = Duration(milliseconds: 200);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: welcomeBackAnimationDuration,
  );

  late final Animation<double> _circleScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 0.85, end: 1.05)
          .chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 60,
    ),
    TweenSequenceItem(
      tween:
          Tween(begin: 1.05, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
  ]).animate(_controller);

  late final Animation<double> _circleOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
  );

  late final Animation<double> _checkProgress = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.2, 0.9, curve: Curves.easeInOut),
  );

  late final Animation<double> _titleOffset = Tween<double>(begin: 8.0, end: 0.0)
      .animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
        ),
      );

  late final Animation<double> _titleOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
  );

  late final Animation<double> _nameOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
  );

  late final Animation<double> _nameScale = Tween<double>(begin: 0.95, end: 1.0)
      .animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
        ),
      );

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_handleStatus);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleStatus);
    _controller.dispose();
    super.dispose();
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _completeAnimation();
    }
  }

  Future<void> _completeAnimation() async {
    if (_hasNavigated) return;
    _hasNavigated = true;
    widget.onFinished?.call();
    await Future<void>.delayed(_kNavigationDelay);
    if (!mounted) return;
    final builder = widget.nextRouteBuilder ?? _defaultRouteBuilder;
    final route = builder(context);
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(route);
  }

  Route<void> _defaultRouteBuilder(BuildContext context) {
    return MaterialPageRoute(builder: (_) => const RootShell());
  }

  String get _resolvedName {
    final trimmed = widget.displayName.trim();
    return trimmed.isEmpty ? 'there' : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _circleOpacity.value,
                      child: Transform.scale(
                        scale: _circleScale.value,
                        child: Container(
                          width: successBadgeSize,
                          height: successBadgeSize,
                          decoration: BoxDecoration(
                            color: successBadgeColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: successBadgeColor.withOpacity(0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Center(
                            child: CustomPaint(
                              size: const Size(successCheckSize, successCheckSize),
                              painter: SuccessCheckPainter(
                                progress: _checkProgress.value,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _titleOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _titleOffset.value),
                        child: Text(
                          'Welcome back',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _nameOpacity.value,
                      child: Transform.scale(
                        scale: _nameScale.value,
                        child: Text(
                          _resolvedName,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
