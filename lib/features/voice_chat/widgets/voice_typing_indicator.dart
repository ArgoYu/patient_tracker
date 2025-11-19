import 'package:flutter/material.dart';

class VoiceTypingIndicator extends StatefulWidget {
  const VoiceTypingIndicator({super.key, this.color});

  final Color? color;

  @override
  State<VoiceTypingIndicator> createState() => _VoiceTypingIndicatorState();
}

class _VoiceTypingIndicatorState extends State<VoiceTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = List<Widget>.generate(3, (index) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = (_controller.value + index * 0.2) % 1.0;
          final scale = 0.5 + (value < 0.5 ? value : (1 - value)) * 1.0;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: widget.color ?? Theme.of(context).colorScheme.secondary,
            shape: BoxShape.circle,
          ),
        ),
      );
    });

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: dots,
    );
  }
}
