import 'dart:async';

import 'package:flutter/material.dart';

/// Stores a GlobalKey for each chat thread item so we can ensureVisible later.
class ChatItemKeyRegistry {
  static final ChatItemKeyRegistry I = ChatItemKeyRegistry._();
  ChatItemKeyRegistry._();

  final Map<String, GlobalKey> _keys = {};

  GlobalKey registerKey(String threadId) =>
      _keys.putIfAbsent(threadId, () => GlobalKey());

  GlobalKey? keyOf(String threadId) => _keys[threadId];
}

/// Wrapper that can flash background color briefly when [highlight] toggles.
class FocusHighlight extends StatefulWidget {
  final Widget child;
  final bool highlight;
  final Color color;
  final Duration duration;

  const FocusHighlight({
    super.key,
    required this.child,
    required this.highlight,
    required this.color,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<FocusHighlight> createState() => _FocusHighlightState();
}

class _FocusHighlightState extends State<FocusHighlight>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<Color?> _bg;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 450),
    );
    _bg = ColorTween(begin: Colors.transparent, end: widget.color).animate(_ac);
    // no autoplay
  }

  @override
  void didUpdateWidget(covariant FocusHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlight && !_ac.isAnimating) {
      _ac.forward().then((_) async {
        await Future.delayed(widget.duration);
        if (mounted) _ac.reverse();
      });
    }
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bg,
      builder: (_, __) => DecoratedBox(
        decoration: BoxDecoration(
          color: _bg.value,
          borderRadius: BorderRadius.circular(12),
        ),
        child: widget.child,
      ),
    );
  }
}
