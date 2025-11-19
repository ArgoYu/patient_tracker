// lib/shared/app_settings.dart
import 'package:flutter/material.dart';

/// Stores global visual settings such as theme mode and glass morphism levels.
class AppSettings extends InheritedWidget {
  const AppSettings({
    super.key,
    required this.themeMode,
    required this.seedColor,
    required this.paletteIndex,
    required this.lightOpacity,
    required this.darkOpacity,
    required this.blurSigma,
    required this.onChangeThemeMode,
    required this.onChangeSeed,
    required this.onChangePalette,
    required this.onChangeLightOpacity,
    required this.onChangeDarkOpacity,
    required this.onChangeBlurSigma,
    required super.child,
  });

  final ThemeMode themeMode;
  final Color seedColor;
  final int paletteIndex;

  final double lightOpacity;
  final double darkOpacity;
  final double blurSigma;

  final ValueChanged<ThemeMode> onChangeThemeMode;
  final ValueChanged<Color> onChangeSeed;
  final ValueChanged<int> onChangePalette;
  final ValueChanged<double> onChangeLightOpacity;
  final ValueChanged<double> onChangeDarkOpacity;
  final ValueChanged<double> onChangeBlurSigma;

  static AppSettings of(BuildContext context) {
    final AppSettings? s =
        context.dependOnInheritedWidgetOfExactType<AppSettings>();
    assert(s != null, 'AppSettings not found in context');
    return s!;
  }

  @override
  bool updateShouldNotify(AppSettings old) =>
      themeMode != old.themeMode ||
      seedColor != old.seedColor ||
      paletteIndex != old.paletteIndex ||
      lightOpacity != old.lightOpacity ||
      darkOpacity != old.darkOpacity ||
      blurSigma != old.blurSigma;
}
