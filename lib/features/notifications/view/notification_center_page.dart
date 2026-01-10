// lib/features/notifications/view/notification_center_page.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/color_scheme_extensions.dart';
import '../../../core/theme/theme_tokens.dart';
import '../../../core/utils/date_formats.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/glass.dart';
import '../../../shared/widgets/layout_cards.dart';
import '../../../shared/utils/toast.dart';
import '../../../app_modules.dart' show FeelingsPage, FeelingsResult;
import '../widgets/next_visit_hero_card.dart';
import '../widgets/notification_secondary_card.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({
    super.key,
    required this.list,
    required this.initialFeelingsScore,
    required this.feelingHistory,
    required this.onFeelingsSaved,
    required this.nextVisit,
    required this.safetyPlan,
    required this.onSafetyPlanChanged,
  });

  final List<AppNotification> list;
  final int initialFeelingsScore;
  final List<FeelingEntry> feelingHistory;
  final void Function(int score, DateTime when, String? note) onFeelingsSaved;
  final NextVisit nextVisit;
  final SafetyPlanData safetyPlan;
  final ValueChanged<SafetyPlanData> onSafetyPlanChanged;

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  late int _currentScore;
  late SafetyPlanData _safetyPlan;

  @override
  void initState() {
    super.initState();
    _currentScore = math.max(1, math.min(5, widget.initialFeelingsScore));
    _safetyPlan = widget.safetyPlan;
  }

  @override
  void didUpdateWidget(NotificationCenterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.safetyPlan != oldWidget.safetyPlan) {
      _safetyPlan = widget.safetyPlan;
    }
  }

  void _updateSafetyPlan(SafetyPlanData data) {
    widget.onSafetyPlanChanged(data);
    setState(() => _safetyPlan = data);
  }

  Future<void> _openFeelings() async {
    final result = await Navigator.of(context).push<FeelingsResult>(
      MaterialPageRoute(
        builder: (_) => FeelingsPage(
          initialScore: _currentScore,
          history: widget.feelingHistory,
          safetyPlan: _safetyPlan,
          onSafetyPlanChanged: _updateSafetyPlan,
        ),
      ),
    );

    if (result != null) {
      setState(() => _currentScore = result.score);
      widget.onFeelingsSaved(result.score, result.when, result.journalNote);
    }
  }

  String _latestFeelingLabel() {
    if (widget.feelingHistory.isEmpty) {
      return 'No mood check-ins yet. Log how you feel when you are ready.';
    }
    final latest = widget.feelingHistory.last;
    return 'Last check-in ${formatDateTime(latest.date)}';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildRecentAlerts(
    BuildContext context,
    List<AppNotification> notifications,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (notifications.isEmpty) {
      return SectionContainer(
        padding: const EdgeInsets.all(AppThemeTokens.cardPadding),
        child: Row(
          children: [
            Icon(Icons.inbox_outlined, color: scheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'You are all caught up for now.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.secondaryTextColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SectionContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: AppThemeTokens.cardPadding,
        vertical: 4,
      ),
      child: Column(
        children: [
          for (var index = 0; index < notifications.length; index++) ...[
            _RecentAlertTile(notification: notifications[index]),
            if (index < notifications.length - 1)
              Divider(
                color: scheme.onSurface.withValues(alpha: 0.08),
                height: 1,
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final notifications = widget.list;
    final isVisitToday = _isSameDay(widget.nextVisit.when, DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppThemeTokens.pagePadding,
          AppThemeTokens.pagePadding,
          AppThemeTokens.pagePadding,
          32,
        ),
        children: [
          Text(
            'Today',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'What needs my attention today?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: AppThemeTokens.gap),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              const gap = AppThemeTokens.gap;
              final wide = width > 560;
              final double half = wide ? (width - gap) / 2 : width;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: width,
                    child: NextVisitHeroCard(
                      visit: widget.nextVisit,
                      isToday: isVisitToday,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              VisitDetailsPage(visit: widget.nextVisit),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: half,
                    child: _FeelingsHeroCard(
                      score: _currentScore,
                      summary: _latestFeelingLabel(),
                      onTap: _openFeelings,
                    ),
                  ),
                  SizedBox(
                    width: half,
                    child: NotificationSecondaryCard(
                      icon: Icons.person_outline,
                      title: 'Care team contact',
                      body:
                          '${widget.nextVisit.doctor} · ${widget.nextVisit.mode}',
                      supportingText:
                          'Next check-in ${formatDateTime(widget.nextVisit.when)}',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              VisitDetailsPage(visit: widget.nextVisit),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppThemeTokens.pagePadding),
          Text(
            'Recent alerts',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          _buildRecentAlerts(context, notifications),
        ],
      ),
    );
  }
}

class _RecentAlertTile extends StatelessWidget {
  const _RecentAlertTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppThemeTokens.smallRadius),
              border: Border.all(
                color: scheme.cardBorderColor.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(
              Icons.notifications_none,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatDateTime(notification.time)} · ${notification.body}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeelingsHeroCard extends StatelessWidget {
  const _FeelingsHeroCard({
    required this.score,
    required this.summary,
    required this.onTap,
  });

  final int score;
  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cardColor = scheme.heroCardColor(scheme.surfaceContainerHigh);
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
                    color: scheme.secondary.withValues(alpha: 0.14),
                    borderRadius:
                        BorderRadius.circular(AppThemeTokens.smallRadius),
                  ),
                  child: Icon(
                    Icons.mood,
                    color: scheme.secondary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's feeling",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        summary,
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
                    '$score / 5',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.tertiaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.tonal(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                minimumSize: const Size(0, 40),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Log how I feel'),
            ),
          ],
        ),
      ),
    );
  }
}

class VisitDetailsPage extends StatelessWidget {
  const VisitDetailsPage({super.key, required this.visit});

  final NextVisit visit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(visit.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.schedule, size: 20),
                  const SizedBox(width: 8),
                  Text(formatDateTime(visit.when)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.person, size: 20),
                  const SizedBox(width: 8),
                  Text(visit.doctor),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(
                    visit.mode.toLowerCase().contains('online')
                        ? Icons.videocam
                        : Icons.place,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(visit.location)),
                ]),
                if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(visit.notes!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Glass(
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () =>
                        showToast(context, 'Add to calendar (placeholder)'),
                    child: const Text('Add to Calendar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        showToast(context, 'Open link/directions (placeholder)'),
                    child: Text(visit.mode.toLowerCase().contains('online')
                        ? 'Open Link'
                        : 'Directions'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Glass(
            child: Container(
              height: 160,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Map / Meeting link preview'),
            ),
          ),
        ],
      ),
    );
  }
}
