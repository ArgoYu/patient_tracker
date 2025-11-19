import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/voice_chat_models.dart';

/// Press-and-hold mic button with fake waveform + mock processing states.
class HoldToTalkButton extends StatefulWidget {
  const HoldToTalkButton({
    super.key,
    this.onStateChanged,
    this.mockGenerate,
  });

  final ValueChanged<VoiceState>? onStateChanged;
  final Future<String> Function()? mockGenerate;

  @override
  State<HoldToTalkButton> createState() => _HoldToTalkButtonState();
}

class _HoldToTalkButtonState extends State<HoldToTalkButton>
    with TickerProviderStateMixin {
  VoiceState _state = VoiceState.idle;
  bool _completing = false;

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 1.08)
      .animate(
    CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
  );

  late final AnimationController _waveTick = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 60),
  );

  final Random _rng = Random();
  Timer? _waveTimer;
  List<double> _amplitudes = List<double>.filled(24, 0);

  @override
  void initState() {
    super.initState();
    _pulseController.addStatusListener((status) {
      if (_state != VoiceState.holding) return;
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _pulseController.forward();
      }
    });
    _waveTick.addListener(() {
      if (!mounted) return;
      if (_state == VoiceState.holding) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveTick.dispose();
    _waveTimer?.cancel();
    super.dispose();
  }

  void _notify(VoiceState next) {
    if (_state == next) return;
    setState(() => _state = next);
    widget.onStateChanged?.call(next);
  }

  void _startHolding() {
    if (_state == VoiceState.processing || _completing) return;
    if (_state == VoiceState.holding) return;
    HapticFeedback.lightImpact();
    _notify(VoiceState.holding);
    _pulseController
      ..stop()
      ..forward(from: 0);
    _waveTick.repeat();
    _waveTimer?.cancel();
    _waveTimer =
        Timer.periodic(const Duration(milliseconds: 70), (_) => _tickWaveform());
  }

  Future<void> _stopHolding() async {
    if (_state != VoiceState.holding || _completing) return;
    _completing = true;
    _pulseController.stop();
    _notify(VoiceState.processing);
    await _decayWaveform();
    if (widget.mockGenerate != null) {
      await widget.mockGenerate!();
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
    }
    _waveTick.stop();
    _notify(VoiceState.idle);
    _completing = false;
  }

  Future<void> _decayWaveform() async {
    _waveTimer?.cancel();
    for (var step = 0; step < 10; step++) {
      for (var i = 0; i < _amplitudes.length; i++) {
        _amplitudes[i] = (_amplitudes[i] * 0.6).clamp(0.0, 1.0);
      }
      if (!mounted) return;
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 40));
    }
    _waveTimer = null;
    _amplitudes = List<double>.filled(_amplitudes.length, 0);
  }

  void _tickWaveform() {
    for (var i = 0; i < _amplitudes.length; i++) {
      final noise = (_rng.nextDouble() * 0.9) + 0.1;
      final t = _rng.nextDouble();
      _amplitudes[i] = lerpDouble(_amplitudes[i], noise, 0.55 + (0.2 * t))!;
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.primary;
    final micBg = _state == VoiceState.holding
        ? baseColor.withValues(alpha: 0.18)
        : baseColor.withValues(alpha: 0.08);
    final waveformColor = theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 40,
          width: 240,
          child: CustomPaint(
            painter: _Bars(
              amplitudes: _amplitudes,
              color: waveformColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Tooltip(
          message: 'Hold to talk',
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (_) => _startHolding(),
            onTapUp: (_) => _stopHolding(),
            onTapCancel: () => _stopHolding(),
            child: ScaleTransition(
              scale: _scale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: micBg,
                      shape: BoxShape.circle,
                      boxShadow: _state == VoiceState.holding
                          ? [
                              BoxShadow(
                                color: baseColor.withValues(alpha: 0.25),
                                blurRadius: 28,
                                spreadRadius: 2,
                              )
                            ]
                          : [],
                    ),
                  ),
                  Icon(Icons.mic,
                      size: 30, color: theme.colorScheme.onPrimaryContainer),
                  if (_state == VoiceState.processing)
                    const Positioned.fill(
                      child: Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _state == VoiceState.holding ? 'Release to send' : 'Hold to talk',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Bars extends CustomPainter {
  _Bars({required this.amplitudes, required this.color});

  final List<double> amplitudes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.9);
    final barWidth = size.width / amplitudes.length;
    for (var i = 0; i < amplitudes.length; i++) {
      final amp = amplitudes[i].clamp(0.0, 1.0);
      final height = (amp * size.height).clamp(4.0, size.height);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          i * barWidth + (barWidth * 0.2),
          (size.height - height) / 2,
          barWidth * 0.6,
          height,
        ),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _Bars oldDelegate) =>
      oldDelegate.amplitudes != amplitudes ||
      oldDelegate.color != color;
}
