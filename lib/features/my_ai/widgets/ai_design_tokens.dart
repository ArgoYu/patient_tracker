import 'package:flutter/material.dart';

class AiDesignTokens {
  const AiDesignTokens._();

  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing24 = 24;

  static const double pagePadding = spacing16;
  static const double gutter = spacing12;

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(24));
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(14));

  static const double iconSize = 20;
  static const double buttonIconSize = 18;
  static const double shadowBlur = 24;
  static const double shadowOffsetY = 8;
  static const double shadowOpacity = 0.12;

  static const double smallCardPadding = spacing16;
  static const double mediumCardPadding = spacing16 + spacing4;
  static const double largeCardPadding = spacing24;

  static const int quickPromptMaxRows = 2;
  static const int quickPromptPerRow = 3;
  static const int trendsSmallChartHeight = 56;
  static const int trendsLargeChartHeight = 72;
}

class AiTextStyles {
  const AiTextStyles._();

  static TextStyle title16(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ) ??
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

  static TextStyle body13(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ) ??
      const TextStyle(fontSize: 13, fontWeight: FontWeight.w400);

  static TextStyle value28(BuildContext context) =>
      Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ) ??
      const TextStyle(fontSize: 28, fontWeight: FontWeight.w600);
}
