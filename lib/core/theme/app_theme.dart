import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'color_scheme_extensions.dart';
import 'theme_tokens.dart';

/// Defines the palette options available across the app.
class Palette {
  const Palette({
    required this.name,
    required this.seed,
    required this.lightGradient,
    required this.darkGradient,
  });

  final String name;
  final Color seed;
  final List<Color> lightGradient;
  final List<Color> darkGradient;
}

/// Curated palette list, matching the original design.
const List<Palette> palettes = <Palette>[
  Palette(
    name: 'Calm Navy',
    seed: Color(0xFF5D7A8D),
    lightGradient: [Color(0xFFF3F6F9), Color(0xFFE9EEF4), Color(0xFFE0E6EF)],
    darkGradient: [Color(0xFF0C121B), Color(0xFF111824), Color(0xFF151E28)],
  ),
  Palette(
    name: 'Soft Teal',
    seed: Color(0xFF5BA9B3),
    lightGradient: [Color(0xFFF5F7F8), Color(0xFFE8EFF2), Color(0xFFDAE5EA)],
    darkGradient: [Color(0xFF0F151C), Color(0xFF131A23), Color(0xFF181F2B)],
  ),
  Palette(
    name: 'Muted Indigo',
    seed: Color(0xFF7A8C9E),
    lightGradient: [Color(0xFFF6F8FC), Color(0xFFEDF2F8), Color(0xFFE4EBF3)],
    darkGradient: [Color(0xFF0D1421), Color(0xFF131A26), Color(0xFF181F2E)],
  ),
  Palette(
    name: 'Warm Slate',
    seed: Color(0xFF8C7A67),
    lightGradient: [Color(0xFFF7F5F2), Color(0xFFF0ECE8), Color(0xFFE9E4E0)],
    darkGradient: [Color(0xFF100E16), Color(0xFF14121E), Color(0xFF1A1828)],
  ),
  Palette(
    name: 'Cloudy Teal',
    seed: Color(0xFF6EA0A9),
    lightGradient: [Color(0xFFF3F7F8), Color(0xFFE8F1F4), Color(0xFFDDE5EA)],
    darkGradient: [Color(0xFF0C131F), Color(0xFF131B27), Color(0xFF1A2234)],
  ),
];

/// Central theme definitions for the Patient Tracker experience.
class AppTheme {
  const AppTheme._();

  static ThemeData light(Color seed) =>
      _themeFrom(ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light));

  static ThemeData dark(Color seed) =>
      _themeFrom(ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark));

  static ThemeData _themeFrom(ColorScheme scheme) {
    final base = ThemeData(
      colorScheme: scheme,
      brightness: scheme.brightness,
      useMaterial3: true,
      splashFactory: InkRipple.splashFactory,
    );

    final textTheme = base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: textTheme.copyWith(
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.12,
          color: scheme.onSurface,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          height: 1.35,
          color: scheme.onSurface,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          height: 1.4,
          color: scheme.onSurface,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          height: 1.35,
          color: scheme.onSurface,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          height: 1.4,
          color: scheme.secondaryTextColor,
        ),
      ),
      primaryTextTheme: base.primaryTextTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      iconTheme: IconThemeData(
        color: scheme.onSurfaceVariant,
        size: 22,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: scheme.onSurface,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: scheme.secondaryTextColor,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.scaled,
          ),
          TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.scaled,
          ),
          TargetPlatform.macOS: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.windows: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.linux: FadeThroughPageTransitionsBuilder(),
        },
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primaryContainer,
        labelStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurface,
        ),
        side: BorderSide(color: scheme.cardBorderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeTokens.smallRadius),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerHigh,
        elevation: 0,
        shadowColor: scheme.shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeTokens.cardRadius),
          side: BorderSide(
            color: scheme.cardBorderColor.withValues(alpha: 0.4),
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected)
              ? scheme.onSurface
              : scheme.onSurfaceVariant;
          return textTheme.labelLarge
              ?.copyWith(color: color, fontWeight: FontWeight.w500);
        }),
        indicatorColor: scheme.navigationIndicatorColor,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected)
              ? scheme.onSurface
              : scheme.onSurfaceVariant;
          return IconThemeData(color: color);
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
