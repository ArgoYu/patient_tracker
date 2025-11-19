// lib/shared/widgets/glass.dart
import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_settings.dart';

/// Reusable glassmorphism container that reacts to global settings.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 18,
    this.padding = const EdgeInsets.all(14),
    this.blurSigma,
    this.lightOpacity,
    this.darkOpacity,
    this.borderOpacityLight,
    this.borderOpacityDark,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final double? blurSigma;
  final double? lightOpacity;
  final double? darkOpacity;
  final double? borderOpacityLight;
  final double? borderOpacityDark;

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fillOpacity = isDark
        ? (darkOpacity ?? s.darkOpacity)
        : (lightOpacity ?? s.lightOpacity);
    final borderOpacity =
        isDark ? (borderOpacityDark ?? 0.14) : (borderOpacityLight ?? 0.10);

    final baseFill = isDark ? Colors.white : Colors.black;
    final border = isDark ? Colors.white : Colors.black;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
            sigmaX: (blurSigma ?? s.blurSigma),
            sigmaY: (blurSigma ?? s.blurSigma)),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: baseFill.withValues(alpha: fillOpacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
                color: border.withValues(alpha: borderOpacity), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
