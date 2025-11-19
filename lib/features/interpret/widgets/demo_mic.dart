// lib/features/interpret/widgets/demo_mic.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

enum DemoInterpState { idle, holding, processing }

class DemoMic extends StatefulWidget {
  const DemoMic({super.key, this.onCaption});

  final Future<void> Function(String source, String target)? onCaption;

  @override
  State<DemoMic> createState() => _DemoMicState();
}

class _DemoMicState extends State<DemoMic> with TickerProviderStateMixin {
  DemoInterpState state = DemoInterpState.idle;

  late final AnimationController pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) pulse.reverse();
      if (status == AnimationStatus.dismissed) pulse.forward();
    });

  late final Animation<double> scale = Tween(begin: 1.0, end: 1.08).animate(
    CurvedAnimation(parent: pulse, curve: Curves.easeInOut),
  );

  final Random rng = Random();
  final List<double> amps = List<double>.filled(28, 0);
  Timer? waveTimer;

  void startHolding() {
    if (state == DemoInterpState.holding) return;
    setState(() => state = DemoInterpState.holding);
    pulse.forward();
    waveTimer?.cancel();
    waveTimer = Timer.periodic(const Duration(milliseconds: 70), (_) {
      for (var i = 0; i < amps.length; i++) {
        final target = (rng.nextDouble() * 0.9) + 0.1;
        amps[i] =
            amps[i] + (target - amps[i]) * (0.45 + 0.3 * rng.nextDouble());
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> stopHolding() async {
    if (state != DemoInterpState.holding) return;
    setState(() => state = DemoInterpState.processing);
    pulse.stop();
    waveTimer?.cancel();
    for (var k = 0; k < 10; k++) {
      for (var i = 0; i < amps.length; i++) {
        amps[i] *= 0.6;
      }
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 30));
    }
    const demoSource = 'Okay, let\'s try a demo sentence for live captions.';
    const demoPieces = <String>[
      "Okay, let's try ",
      'a demo sentence ',
      'for live captions.',
    ];
    var shown = '';
    for (final piece in demoPieces) {
      shown += piece;
      await widget.onCaption?.call('[partial] $shown', '（部分）正在翻译…');
      await Future.delayed(const Duration(milliseconds: 320));
    }
    await widget.onCaption?.call(
      demoSource,
      '好的，我们来试一条用于直播字幕的演示句子。',
    );

    if (!mounted) return;
    setState(() => state = DemoInterpState.idle);
  }

  @override
  void dispose() {
    pulse.dispose();
    waveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 96.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 260,
          height: 40,
          child: CustomPaint(painter: _Bars(amps)),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTapDown: (_) => startHolding(),
          onTapUp: (_) => stopHolding(),
          onTapCancel: () => stopHolding(),
          child: ScaleTransition(
            scale: scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state == DemoInterpState.holding
                        ? const Color(0xFFD7E5FF)
                        : const Color(0xFFE7EEFF),
                    boxShadow: state == DemoInterpState.holding
                        ? [
                            BoxShadow(
                              blurRadius: 20,
                              spreadRadius: 2,
                              color: Colors.black.withValues(alpha: 0.08),
                            )
                          ]
                        : [],
                  ),
                ),
                Icon(Icons.mic, size: 30, color: theme.colorScheme.primary),
                if (state == DemoInterpState.processing)
                  const Positioned.fill(
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          state == DemoInterpState.holding
              ? 'Release to translate'
              : 'Hold to talk (demo)',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Bars extends CustomPainter {
  _Bars(this.a);

  final List<double> a;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF2D6BFF);
    final n = a.length;
    final w = size.width / n;
    for (var i = 0; i < n; i++) {
      final height =
          (a[i].clamp(0.0, 1.0) * size.height).clamp(2.0, size.height);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
            i * w + w * 0.2, (size.height - height) / 2, w * 0.6, height),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _Bars oldDelegate) => oldDelegate.a != a;
}
