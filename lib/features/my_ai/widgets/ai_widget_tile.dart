import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/ai_widget.dart';
import 'ai_design_tokens.dart';

class AiWidgetTile extends StatefulWidget {
  const AiWidgetTile({
    super.key,
    required this.instance,
    required this.isEditing,
    this.isDragging = false,
    required this.onPrimaryTap,
    required this.onDelete,
    required this.onResize,
    required this.onNavigate,
  });

  final AiWidgetInstance instance;
  final bool isEditing;
  final bool isDragging;
  final VoidCallback? onPrimaryTap;
  final VoidCallback onDelete;
  final VoidCallback onResize;
  final ValueChanged<String> onNavigate;

  @override
  State<AiWidgetTile> createState() => _AiWidgetTileState();
}

class _AiWidgetTileState extends State<AiWidgetTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final double _phase =
      math.Random().nextDouble() * 2 * math.pi; // desync jiggle phases
  late final double _tiltAmplitude =
      0.015 + math.Random().nextDouble() * 0.01; // radians
  late final double _translateAmplitude =
      1.2 + math.Random().nextDouble(); // logical pixels

  @override
  void initState() {
    super.initState();
    _updateAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AiWidgetTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditing != oldWidget.isEditing ||
        widget.isDragging != oldWidget.isDragging) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    final shouldJiggle = widget.isEditing && !widget.isDragging;
    if (shouldJiggle && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!shouldJiggle && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = switch (widget.instance.size) {
      AiWidgetSize.small => AiDesignTokens.smallCardPadding,
      AiWidgetSize.medium => AiDesignTokens.mediumCardPadding,
      AiWidgetSize.large => AiDesignTokens.largeCardPadding,
    };

    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AiDesignTokens.cardRadius,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow
                .withValues(alpha: AiDesignTokens.shadowOpacity),
            blurRadius: AiDesignTokens.shadowBlur,
            offset: const Offset(0, AiDesignTokens.shadowOffsetY),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AiDesignTokens.cardRadius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AiDesignTokens.cardRadius,
            onTap: widget.isEditing ? null : widget.onPrimaryTap,
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _iconFor(widget.instance.type),
                        size: AiDesignTokens.iconSize,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AiDesignTokens.spacing12),
                      Expanded(
                        child: Text(
                          _titleFor(widget.instance),
                          style: AiTextStyles.title16(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AiDesignTokens.spacing16),
                  Expanded(
                    child: _TileContent(
                      instance: widget.instance,
                      onNavigate: widget.onNavigate,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final jiggle = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (!(widget.isEditing && !widget.isDragging)) {
          return child!;
        }
        final wave = math.sin((_controller.value * 2 * math.pi) + _phase);
        final rotation = wave * _tiltAmplitude;
        final translateX = wave * _translateAmplitude;
        final translateY = wave * (_translateAmplitude * 0.6);
        return Transform.translate(
          offset: Offset(translateX, translateY),
          child: Transform.rotate(
            angle: rotation,
            child: child,
          ),
        );
      },
      child: content,
    );

    final deleteButton = Positioned(
      top: AiDesignTokens.spacing12,
      left: AiDesignTokens.spacing12,
      child: _TileDeleteButton(onTap: widget.onDelete),
    );

    final resizeButton = Positioned(
      bottom: AiDesignTokens.spacing12,
      right: AiDesignTokens.spacing12,
      child: _TileActionButton(
        icon: Icons.aspect_ratio_rounded,
        onTap: widget.onResize,
      ),
    );

    return Stack(
      children: [
        jiggle,
        if (widget.isEditing) deleteButton,
        if (widget.isEditing) resizeButton,
      ],
    );
  }

  IconData _iconFor(AiWidgetType type) {
    switch (type) {
      case AiWidgetType.quickPrompts:
        return Icons.flash_on_outlined;
      case AiWidgetType.dailyBrief:
        return Icons.today_outlined;
      case AiWidgetType.pinnedChats:
        return Icons.push_pin_outlined;
      case AiWidgetType.trends:
        return Icons.show_chart;
    }
  }

  String _titleFor(AiWidgetInstance instance) {
    final override = instance.settings['title'] as String?;
    if (override != null && override.isNotEmpty) {
      return override;
    }
    return switch (instance.type) {
      AiWidgetType.quickPrompts => 'Quick Prompts',
      AiWidgetType.dailyBrief => 'Daily Brief',
      AiWidgetType.pinnedChats => 'Pinned Chats',
      AiWidgetType.trends => 'Trends Snapshot',
    };
  }
}

class _TileActionButton extends StatelessWidget {
  const _TileActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.inverseSurface.withValues(alpha: 0.72),
      borderRadius: AiDesignTokens.pillRadius,
      child: InkWell(
        borderRadius: AiDesignTokens.pillRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AiDesignTokens.spacing8),
          child: Icon(
            icon,
            size: AiDesignTokens.buttonIconSize,
            color: theme.colorScheme.onInverseSurface,
          ),
        ),
      ),
    );
  }
}

class _TileDeleteButton extends StatelessWidget {
  const _TileDeleteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.error,
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(
            Icons.remove,
            size: 18,
            color: theme.colorScheme.onError,
          ),
        ),
      ),
    );
  }
}

class _TileContent extends StatelessWidget {
  const _TileContent({
    required this.instance,
    required this.onNavigate,
  });

  final AiWidgetInstance instance;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    switch (instance.type) {
      case AiWidgetType.quickPrompts:
        return _QuickPrompts(
          instance: instance,
          onNavigate: onNavigate,
        );
      case AiWidgetType.dailyBrief:
        return _DailyBrief(
          instance: instance,
          onNavigate: onNavigate,
        );
      case AiWidgetType.pinnedChats:
        return _PinnedChats(
          instance: instance,
          onNavigate: onNavigate,
        );
      case AiWidgetType.trends:
        return _TrendsSnapshot(
          instance: instance,
          onNavigate: onNavigate,
        );
    }
  }
}

class _QuickPrompts extends StatelessWidget {
  const _QuickPrompts({
    required this.instance,
    required this.onNavigate,
  });

  final AiWidgetInstance instance;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final promptsRaw =
        instance.settings['prompts'] as List<dynamic>? ?? const [];
    final prompts = promptsRaw
        .map<Map<String, String>>((entry) {
          if (entry is Map) {
            return {
              'label': entry['label']?.toString() ?? '',
              'target': entry['target']?.toString() ?? '',
            };
          }
          return {
            'label': entry.toString(),
            'target': '',
          };
        })
        .where((entry) => entry['label']!.isNotEmpty)
        .toList();

    const maxVisible =
        AiDesignTokens.quickPromptPerRow * AiDesignTokens.quickPromptMaxRows;
    final visible = prompts.take(maxVisible).toList();
    final hiddenCount = math.max(prompts.length - visible.length, 0);

    final rows = <Widget>[];
    for (var i = 0; i < visible.length; i += AiDesignTokens.quickPromptPerRow) {
      final chunk =
          visible.skip(i).take(AiDesignTokens.quickPromptPerRow).toList();
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            for (var j = 0; j < chunk.length; j++) ...[
              Flexible(
                fit: FlexFit.loose,
                child: _PromptPill(
                  label: chunk[j]['label'] ?? '',
                  onTap: () => onNavigate(chunk[j]['target'] ?? ''),
                ),
              ),
              if (j != chunk.length - 1)
                const SizedBox(width: AiDesignTokens.spacing12),
            ],
          ],
        ),
      );
      if (i + AiDesignTokens.quickPromptPerRow < visible.length) {
        rows.add(const SizedBox(height: AiDesignTokens.spacing12));
      }
    }

    if (hiddenCount > 0) {
      rows.add(const SizedBox(height: AiDesignTokens.spacing12));
      rows.add(
        Text(
          '+ $hiddenCount more',
          style: AiTextStyles.body13(context).copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      );
    }

    if (rows.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Add prompts from the catalog.',
          style: AiTextStyles.body13(context),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }
}

class _PromptPill extends StatelessWidget {
  const _PromptPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: AiDesignTokens.pillRadius,
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: AiDesignTokens.pillRadius,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AiDesignTokens.spacing16,
          vertical: AiDesignTokens.spacing8,
        ),
        child: Text(
          label,
          style: AiTextStyles.body13(context).copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _DailyBrief extends StatelessWidget {
  const _DailyBrief({
    required this.instance,
    required this.onNavigate,
  });

  final AiWidgetInstance instance;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final entriesRaw =
        instance.settings['entries'] as List<dynamic>? ?? const [];
    final entries = entriesRaw
        .map<Map<String, String>>((entry) {
          if (entry is Map) {
            return {
              'icon': entry['icon']?.toString() ?? '',
              'text': entry['text']?.toString() ?? '',
              'target': entry['target']?.toString() ?? '',
            };
          }
          return {
            'icon': '',
            'text': entry.toString(),
            'target': '',
          };
        })
        .where((entry) => entry['text']!.isNotEmpty)
        .toList();

    final limit = switch (instance.size) {
      AiWidgetSize.large => 6,
      _ => 3,
    };
    final visible = entries.take(limit).toList();
    final hiddenCount = math.max(entries.length - visible.length, 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          _DailyBriefRow(
            icon: visible[i]['icon'] ?? '',
            text: visible[i]['text'] ?? '',
            onTap: () => onNavigate(visible[i]['target'] ?? ''),
          ),
          if (i != visible.length - 1)
            const SizedBox(height: AiDesignTokens.spacing12),
        ],
        if (hiddenCount > 0) ...[
          const SizedBox(height: AiDesignTokens.spacing12),
          Text(
            '+ $hiddenCount more',
            style: AiTextStyles.body13(context).copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ],
    );
  }
}

class _DailyBriefRow extends StatelessWidget {
  const _DailyBriefRow({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final String icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: AiDesignTokens.pillRadius,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AiDesignTokens.spacing8,
        ),
        child: Row(
          children: [
            Icon(
              _dailyIconFor(icon),
              size: AiDesignTokens.iconSize,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AiDesignTokens.spacing12),
            Expanded(
              child: Text(
                text,
                style: AiTextStyles.body13(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _dailyIconFor(String value) {
    switch (value) {
      case 'schedule':
        return Icons.calendar_month_outlined;
      case 'pill':
        return Icons.vaccines_outlined;
      case 'mood':
        return Icons.emoji_emotions_outlined;
      case 'sleep':
        return Icons.nights_stay_outlined;
      case 'steps':
        return Icons.directions_walk_rounded;
      case 'hydration':
        return Icons.local_drink_outlined;
      default:
        return Icons.info_outline;
    }
  }
}

class _PinnedChats extends StatelessWidget {
  const _PinnedChats({
    required this.instance,
    required this.onNavigate,
  });

  final AiWidgetInstance instance;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final itemsRaw = instance.settings['items'] as List<dynamic>? ?? const [];
    final items = itemsRaw
        .map<Map<String, String>>((entry) {
          if (entry is Map) {
            return {
              'name': entry['name']?.toString() ?? '',
              'role': entry['role']?.toString() ?? '',
              'target': entry['target']?.toString() ?? '',
            };
          }
          return {
            'name': entry.toString(),
            'role': '',
            'target': '',
          };
        })
        .where((entry) => entry['name']!.isNotEmpty)
        .toList();

    final maxItems = switch (instance.size) {
      AiWidgetSize.small => 1,
      AiWidgetSize.medium => 2,
      AiWidgetSize.large => 4,
    };

    final visible = items.take(maxItems).toList();

    if (visible.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Pin a conversation to see it here.',
          style: AiTextStyles.body13(context),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          InkWell(
            borderRadius: AiDesignTokens.pillRadius,
            onTap: () => onNavigate(visible[i]['target'] ?? ''),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AiDesignTokens.spacing8,
              ),
              child: Row(
                children: [
                  _AvatarPlaceholder(name: visible[i]['name'] ?? ''),
                  const SizedBox(width: AiDesignTokens.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visible[i]['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AiDesignTokens.spacing4),
                        Text(
                          visible[i]['role'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      size: AiDesignTokens.iconSize,
                      color: Theme.of(context).colorScheme.outline),
                ],
              ),
            ),
          ),
          if (i != visible.length - 1)
            const SizedBox(height: AiDesignTokens.spacing12),
        ],
      ],
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = name.isEmpty
        ? '?'
        : name
            .trim()
            .split(RegExp(r'\\s+'))
            .take(2)
            .map((part) => part.isEmpty ? '' : part[0])
            .join()
            .toUpperCase();
    return CircleAvatar(
      radius: 18,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TrendsSnapshot extends StatelessWidget {
  const _TrendsSnapshot({
    required this.instance,
    required this.onNavigate,
  });

  final AiWidgetInstance instance;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final metricsRaw =
        instance.settings['metrics'] as List<dynamic>? ?? const [];
    final metrics = metricsRaw
        .map<Map<String, String>>((entry) {
          if (entry is Map) {
            return {
              'label': entry['label']?.toString() ?? '',
              'value': entry['value']?.toString() ?? '',
              'target': entry['target']?.toString() ?? '',
            };
          }
          return {
            'label': '',
            'value': entry.toString(),
            'target': '',
          };
        })
        .where((entry) => entry['label']!.isNotEmpty)
        .toList();

    if (metrics.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Add metrics from the catalog.',
          style: AiTextStyles.body13(context),
        ),
      );
    }

    switch (instance.size) {
      case AiWidgetSize.small:
        final metric = metrics.first;
        return _TrendMetricTile(
          label: metric['label'] ?? '',
          value: metric['value'] ?? '',
          chartHeight: AiDesignTokens.trendsSmallChartHeight.toDouble(),
          onTap: () => onNavigate(metric['target'] ?? ''),
        );
      case AiWidgetSize.medium:
        final visible = metrics.take(2).toList();
        return Row(
          children: [
            for (var i = 0; i < visible.length; i++) ...[
              Expanded(
                child: _TrendMetricTile(
                  label: visible[i]['label'] ?? '',
                  value: visible[i]['value'] ?? '',
                  chartHeight: AiDesignTokens.trendsSmallChartHeight.toDouble(),
                  onTap: () => onNavigate(visible[i]['target'] ?? ''),
                ),
              ),
              if (i != visible.length - 1)
                const SizedBox(width: AiDesignTokens.spacing12),
            ],
          ],
        );
      case AiWidgetSize.large:
        final visible = metrics.take(4).toList();
        return Column(
          children: [
            for (var i = 0; i < visible.length; i += 2) ...[
              Row(
                children: [
                  for (var j = 0; j < 2; j++) ...[
                    if (i + j < visible.length)
                      Expanded(
                        child: _TrendMetricTile(
                          label: visible[i + j]['label'] ?? '',
                          value: visible[i + j]['value'] ?? '',
                          chartHeight:
                              AiDesignTokens.trendsLargeChartHeight.toDouble(),
                          onTap: () =>
                              onNavigate(visible[i + j]['target'] ?? ''),
                        ),
                      ),
                    if (j == 0 && i + 1 < visible.length)
                      const SizedBox(width: AiDesignTokens.spacing12),
                  ],
                ],
              ),
              if (i + 2 < visible.length)
                const SizedBox(height: AiDesignTokens.spacing12),
            ],
          ],
        );
    }
  }
}

class _TrendMetricTile extends StatelessWidget {
  const _TrendMetricTile({
    required this.label,
    required this.value,
    required this.chartHeight,
    required this.onTap,
  });

  final String label;
  final String value;
  final double chartHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: AiDesignTokens.cardRadius,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
          borderRadius: AiDesignTokens.cardRadius,
        ),
        padding: const EdgeInsets.all(AiDesignTokens.spacing12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AiTextStyles.body13(context).copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AiDesignTokens.spacing8),
            Text(
              value,
              style: AiTextStyles.value28(context).copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AiDesignTokens.spacing12),
            SizedBox(
              height: chartHeight,
              child: _Sparkline(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(color: color.withValues(alpha: 0.6)),
      child: const SizedBox.expand(),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.2, size.height * 0.4),
      Offset(size.width * 0.4, size.height * 0.6),
      Offset(size.width * 0.6, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.5),
      Offset(size.width, size.height * 0.3),
    ];
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
