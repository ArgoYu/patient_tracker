// lib/app.dart
import 'package:flutter/material.dart';

import 'shared/app_settings.dart';
import 'core/routing/app_routes.dart';
import 'core/theme/app_theme.dart';

export 'app_modules.dart';

/// The root widget configuring MaterialApp, theme, and routes.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key, this.initialRoute = AppRoutes.home});

  final String initialRoute;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  ThemeMode _mode = ThemeMode.system;
  int _paletteIndex = 0;
  Color _seed = palettes[0].seed;

  double _lightOpacity = 0.04;
  double _darkOpacity = 0.03;
  double _blurSigma = 28;

  @override
  Widget build(BuildContext context) {
    final pal = palettes[_paletteIndex];
    return AppSettings(
      themeMode: _mode,
      seedColor: _seed,
      paletteIndex: _paletteIndex,
      lightOpacity: _lightOpacity,
      darkOpacity: _darkOpacity,
      blurSigma: _blurSigma,
      onChangeThemeMode: (m) => setState(() => _mode = m),
      onChangeSeed: (c) => setState(() => _seed = c),
      onChangePalette: (i) => setState(() {
        _paletteIndex = i;
        _seed = palettes[i].seed;
      }),
      onChangeLightOpacity: (v) =>
          setState(() => _lightOpacity = v.clamp(0.0, 1.0)),
      onChangeDarkOpacity: (v) =>
          setState(() => _darkOpacity = v.clamp(0.0, 1.0)),
      onChangeBlurSigma: (v) => setState(() => _blurSigma = v.clamp(0.0, 60.0)),
      child: MaterialApp(
        title: 'Patient Tracker',
        debugShowCheckedModeBanner: false,
        themeMode: _mode,
        theme: AppTheme.light(_seed),
        darkTheme: AppTheme.dark(_seed),
        initialRoute: widget.initialRoute,
        routes: AppRoutes.routes,
        builder: (context, child) =>
            AppBackdrop(palette: pal, child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}

/// Applies the gradient backdrop chosen from the active palette.
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.palette, required this.child});

  final Palette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? palette.darkGradient : palette.lightGradient;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: child,
    );
  }
}
