part of 'package:patient_tracker/app_modules.dart';

/// ============ FadeScale dialog helper (with optional full-screen blur) ============
Future<T?> fadeDialog<T>(
  BuildContext context,
  Widget child, {
  bool barrierDismissible = true,
  double backdropSigma = 20, // Blur strength
  double backdropDarken = 0.000000000000001, // Background darkening opacity
}) {
  return showModal<T>(
    context: context,
    configuration: const FadeScaleTransitionConfiguration(
      barrierDismissible: true,
    ),
    builder: (_) => Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter:
                ImageFilter.blur(sigmaX: backdropSigma, sigmaY: backdropSigma),
            child: Container(
              color: const Color.fromARGB(255, 0, 0, 0)
                  .withValues(alpha: backdropDarken),
            ),
          ),
        ),
        Center(
          child: Material(
            type: MaterialType.transparency,
            child: child,
          ),
        ),
      ],
    ),
  );
}

/// ===================== Root Shell (independent Navigator per tab) =====================
