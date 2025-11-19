// lib/features/notifications/widgets/next_visit_hero_card.dart
import 'package:flutter/material.dart';

import '../../../core/utils/date_formats.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/glass.dart';

class NextVisitHeroCard extends StatelessWidget {
  const NextVisitHeroCard({
    super.key,
    required this.visit,
    required this.onTap,
  });

  final NextVisit visit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Glass(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.16),
                  child: const Icon(Icons.calendar_month_outlined),
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
                      const SizedBox(height: 4),
                      Text(formatDateTime(visit.when)),
                      const SizedBox(height: 4),
                      Text('${visit.doctor} · ${visit.mode}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
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
