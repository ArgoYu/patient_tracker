import 'package:flutter/material.dart';

extension AppColorSchemeExtensions on ColorScheme {
  /// Text colors tuned for light/dark contrast.
  Color get secondaryTextColor => onSurface.withValues(
        alpha: brightness == Brightness.dark ? 0.70 : 0.78,
      );

  Color get tertiaryTextColor => onSurface.withValues(
        alpha: brightness == Brightness.dark ? 0.50 : 0.60,
      );

  /// Indicator/tint colors that remain legible in both modes.
  Color get navigationIndicatorColor => primary.withValues(
        alpha: brightness == Brightness.dark ? 0.18 : 0.12,
      );

  /// Border color for cards and containers.
  Color get cardBorderColor => outlineVariant;

  /// Fill color for icon/hero containers.
  Color get iconContainerFillColor => surfaceContainerHighest;

  /// Applies a subtle tonal tint over a surface.
  Color heroCardColor(Color surface) => Color.alphaBlend(
        primary.withValues(
          alpha: brightness == Brightness.dark ? 0.12 : 0.08,
        ),
        surface,
      );
}
