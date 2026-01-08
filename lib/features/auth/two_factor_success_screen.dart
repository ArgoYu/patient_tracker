import 'dart:async';

import 'package:flutter/material.dart';

const _kAnimationDuration = Duration(milliseconds: 1100);
const _kBadgeSize = 140.0;
const _kCheckSize = 72.0;
const _kBadgeColor = Color(0xFF34A853);

/// Show this animation after storing the authenticated session and pass a [nextRoute]
/// for automatic continuation, or omit it to pop with `true`.
class TwoFactorSuccessScreen extends StatelessWidget {
  const TwoFactorSuccessScreen({
    super.key,
    this.nextRoute,
    this.nextRouteArguments,
    this.duration = _kAnimationDuration,
  });

  final String? nextRoute;
  final Object? nextRouteArguments;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: _TwoFactorSuccessAnimation(
            duration: duration,
            badgeColor: _kBadgeColor,
            nextRoute: nextRoute,
            nextRouteArguments: nextRouteArguments,
          ),
        ),
      ),
    );
  }
}

class _TwoFactorSuccessAnimation extends StatefulWidget {
  const _TwoFactorSuccessAnimation({
    required this.duration,
    required this.badgeColor,
    this.nextRoute,
    this.nextRouteArguments,
  });

  final Duration duration;
  final Color badgeColor;
  final String? nextRoute;
  final Object? nextRouteArguments;

  @override
  State<_TwoFactorSuccessAnimation> createState() =>
      _TwoFactorSuccessAnimationState();
}

class _TwoFactorSuccessAnimationState extends State<_TwoFactorSuccessAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
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
    curve: const Interval(0.15, 0.9, curve: Curves.easeInOut),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _controller.addStatusListener(_handleStatus);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleStatus);
    _controller.dispose();
    super.dispose();
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _navigateNext();
    }
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;
    if (widget.nextRoute != null) {
      await Navigator.of(context).pushReplacementNamed(
        widget.nextRoute!,
        arguments: widget.nextRouteArguments,
      );
      return;
    }
    Navigator.of(context).maybePop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                    width: _kBadgeSize,
                    height: _kBadgeSize,
                    decoration: BoxDecoration(
                      color: widget.badgeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.badgeColor.withOpacity(0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Center(
                      child: CustomPaint(
                        size: const Size(_kCheckSize, _kCheckSize),
                        painter: _CheckMarkPainter(
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
          const SizedBox(height: 20),
          Text(
            'Verified',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Verification successful',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckMarkPainter extends CustomPainter {
  _CheckMarkPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) {
      return;
    }

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.55)
      ..lineTo(size.width * 0.45, size.height * 0.75)
      ..lineTo(size.width * 0.82, size.height * 0.3);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final extractPath = metric.extractPath(
      0,
      metric.length * progress,
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckMarkPainter oldDelegate) {
    return progress != oldDelegate.progress || color != oldDelegate.color;
  }
}
