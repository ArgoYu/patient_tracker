import 'dart:math' as math;

import 'package:flutter/material.dart';

class VoiceWaveform extends StatelessWidget {
  const VoiceWaveform({super.key, required this.level});

  final double level;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme.primary;
    final bars = List<Widget>.generate(12, (index) {
      final normalized = (math.sin(level * math.pi + index * 0.5) + 1) / 2;
      final height = 12 + normalized * 24;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 6,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: _opacityColor(palette, 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    });

    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: bars,
      ),
    );
  }
}

Color _opacityColor(Color color, double opacity) {
  final alpha = (color.a * opacity).clamp(0.0, 1.0);
  return color.withValues(alpha: alpha);
}
