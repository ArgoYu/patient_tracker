// lib/features/notifications/widgets/next_visit_hero_card.dart
import 'package:flutter/material.dart';

import '../../../core/theme/color_scheme_extensions.dart';
import '../../../core/theme/theme_tokens.dart';
import '../../../core/utils/date_formats.dart';
import '../../../data/models/models.dart';

class NextVisitHeroCard extends StatelessWidget {
  const NextVisitHeroCard({
    super.key,
    required this.visit,
    required this.onTap,
    this.isToday = false,
  });

  final NextVisit visit;
  final VoidCallback onTap;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cardColor = scheme.heroCardColor(scheme.surfaceContainerHigh);
    final statusLabel = isToday ? 'Today' : 'Upcoming';
    final dateLabel = isToday
        ? 'Today · ${formatTime(visit.when)}'
        : formatDateTime(visit.when);
    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(AppThemeTokens.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.14),
                    borderRadius:
                        BorderRadius.circular(AppThemeTokens.smallRadius),
                  ),
                  child: Icon(
                    Icons.calendar_month_outlined,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dateLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${visit.doctor} · ${visit.mode}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius:
                        BorderRadius.circular(AppThemeTokens.smallRadius),
                    border: Border.all(
                      color: scheme.cardBorderColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.tertiaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onTap,
                child: const Text('View visit details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
