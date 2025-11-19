// lib/features/notifications/view/notification_center_page.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/date_formats.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/glass.dart';
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
      return 'No mood entries yet. Tap to log how you feel.';
    }
    final latest = widget.feelingHistory.last;
    return 'Last logged ${formatDateTime(latest.date)} · Score ${latest.score}/5';
  }

  @override
  Widget build(BuildContext context) {
    final notifications = widget.list;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              const gap = 12.0;
              final wide = width > 520;
              final double half = wide ? (width - gap) / 2 : width;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: width,
                    child: NextVisitHeroCard(
                      visit: widget.nextVisit,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VisitDetailsPage(visit: widget.nextVisit),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width,
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
                          '${widget.nextVisit.doctor} · Tap to review visit details',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VisitDetailsPage(visit: widget.nextVisit),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Recent alerts',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (notifications.isEmpty)
            const Glass(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.inbox_outlined),
                    SizedBox(width: 12),
                    Expanded(child: Text('You’re all caught up for now.')),
                  ],
                ),
              ),
            )
          else
            ...notifications.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Glass(
                  child: ListTile(
                    leading: const Icon(Icons.notifications),
                    title: Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text('${formatDateTime(item.time)} · ${item.body}'),
                  ),
                ),
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
    return Glass(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      theme.colorScheme.secondary.withValues(alpha: 0.16),
                  child: const Icon(Icons.mood),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today’s feeling',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(summary),
                    ],
                  ),
                ),
                Text(
                  '$score / 5',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onTap,
                child: const Text('Log how I feel'),
              ),
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
