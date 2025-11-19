// lib/core/theme/app_theme.dart
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

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
    name: 'iPhone Blue',
    seed: Color(0xFF4B7BE5),
    lightGradient: [Color(0xFFFAFCFF), Color(0xFFF6F9FF), Color(0xFFF2F6FF)],
    darkGradient: [Color(0xFF0C1018), Color(0xFF0F1420), Color(0xFF141B28)],
  ),
  Palette(
    name: 'iPhone Pink',
    seed: Color(0xFFFF7AA2),
    lightGradient: [Color(0xFFFFF6F8), Color(0xFFFFF0F5), Color(0xFFFFE8F0)],
    darkGradient: [Color(0xFF150F16), Color(0xFF1B1220), Color(0xFF231429)],
  ),
  Palette(
    name: 'iPhone Yellow',
    seed: Color(0xFFF5C543),
    lightGradient: [Color(0xFFFFFBF1), Color(0xFFFFF7E5), Color(0xFFFFF3D8)],
    darkGradient: [Color(0xFF181308), Color(0xFF211A0C), Color(0xFF2A200F)],
  ),
  Palette(
    name: 'iPhone Green',
    seed: Color(0xFF5AD2A1),
    lightGradient: [Color(0xFFF3FFF9), Color(0xFFE9FFF4), Color(0xFFDFFEEF)],
    darkGradient: [Color(0xFF081611), Color(0xFF0D1F18), Color(0xFF142A21)],
  ),
  Palette(
    name: 'iPhone Black',
    seed: Color(0xFF1F2937),
    lightGradient: [Color(0xFFF6F7F9), Color(0xFFF1F3F6), Color(0xFFEDEFF3)],
    darkGradient: [Color(0xFF0A0B0E), Color(0xFF0E1014), Color(0xFF12151A)],
  ),
];

/// Centralised theme configuration for both light and dark modes.
class AppTheme {
  const AppTheme._();

  static ThemeData light(Color seed) => _themeFor(Brightness.light, seed);

  static ThemeData dark(Color seed) => _themeFor(Brightness.dark, seed);

  static ThemeData _themeFor(Brightness brightness, Color seed) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      splashFactory: InkSparkle.splashFactory,
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
            bodyColor: scheme.onSurface,
            displayColor: scheme.onSurface,
          ),
      primaryTextTheme: ThemeData(brightness: brightness).textTheme.apply(
            bodyColor: scheme.onPrimary,
            displayColor: scheme.onPrimary,
          ),
      iconTheme: IconThemeData(color: scheme.onSurface),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        titleTextStyle: ThemeData(brightness: brightness)
            .textTheme
            .titleMedium
            ?.copyWith(color: scheme.onSurface),
        subtitleTextStyle: ThemeData(brightness: brightness)
            .textTheme
            .bodySmall
            ?.copyWith(color: scheme.onSurfaceVariant),
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
        side: BorderSide(color: scheme.onSurface.withValues(alpha: 0.08)),
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        selectedColor: scheme.primary.withValues(alpha: 0.18),
        labelStyle: TextStyle(color: scheme.onSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(color: scheme.onSurface.withValues(alpha: 0.9)),
        ),
      ),
    );
  }
}
