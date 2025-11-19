// ignore_for_file: deprecated_member_use

part of 'package:patient_tracker/app_modules.dart';

class EmergencyAssistPage extends StatelessWidget {
  const EmergencyAssistPage({
    super.key,
    required this.profile,
    required this.medications,
    required this.vitals,
    required this.nextVisit,
    required this.safetyPlan,
    required this.carePlan,
    required this.labs,
  });

  final PatientProfile profile;
  final List<RxMedication> medications;
  final List<VitalEntry> vitals;
  final NextVisit nextVisit;
  final SafetyPlanData safetyPlan;
  final CarePlan carePlan;
  final List<LabResult> labs;

  VitalEntry? get _latestVitals => vitals.isEmpty
      ? null
      : vitals.reduce((a, b) => a.date.isAfter(b.date) ? a : b);

  VitalEntry? get _previousVitals {
    if (vitals.length < 2) return null;
    final sorted = [...vitals]..sort((a, b) => a.date.compareTo(b.date));
    return sorted[sorted.length - 2];
  }

  _MedicationSnapshot? get _lastMedicationEvent {
    DateTime? latest;
    RxMedication? med;
    for (final candidate in medications) {
      for (final intake in candidate.intakeLog) {
        final currentLatest = latest;
        if (currentLatest == null || intake.isAfter(currentLatest)) {
          latest = intake;
          med = candidate;
        }
      }
    }
    final resolvedLatest = latest;
    final resolvedMed = med;
    if (resolvedLatest == null || resolvedMed == null) return null;
    return _MedicationSnapshot(
        medication: resolvedMed, takenAt: resolvedLatest);
  }

  List<String> _splitLines(String value) => value
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  String _relativeLabel(DateTime moment) {
    final now = DateTime.now();
    final diff = now.difference(moment);

    String fmt(Duration d) {
      final abs = d.abs();
      if (abs.inMinutes < 1) return 'moments';
      if (abs.inMinutes < 60) return '${abs.inMinutes} min';
      if (abs.inHours < 24) return '${abs.inHours} hr';
      return '${abs.inDays} day';
    }

    if (diff.inSeconds >= 0) {
      return '${fmt(diff)} ago';
    }
    return 'In ${fmt(diff)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    const gap = 12.0;

    final latestVitals = _latestVitals;
    final previousVitals = _previousVitals;
    final lastMedicationEvent = _lastMedicationEvent;

    final summaryTiles = <Widget>[
      _EmergencySummaryTile(
        icon: Icons.favorite,
        label: 'Latest vitals',
        value: latestVitals != null
            ? '${latestVitals.systolic}/${latestVitals.diastolic} · HR ${latestVitals.heartRate}'
            : 'No recent vitals',
        detail: latestVitals != null
            ? 'Logged ${formatDateTime(latestVitals.date)}'
            : 'Encourage vitals capture',
      ),
      _EmergencySummaryTile(
        icon: Icons.trending_down,
        label: 'Trend',
        value: latestVitals != null && previousVitals != null
            ? _bloodPressureDelta(latestVitals, previousVitals)
            : 'Insufficient data',
        detail: latestVitals != null && previousVitals != null
            ? 'Compared with ${formatDateTime(previousVitals.date)}'
            : 'Need at least two readings',
      ),
      _EmergencySummaryTile(
        icon: Icons.vaccines_outlined,
        label: 'Last medication',
        value: lastMedicationEvent != null
            ? lastMedicationEvent.medication.name
            : 'No intake logged',
        detail: lastMedicationEvent != null
            ? _relativeLabel(lastMedicationEvent.takenAt)
            : 'Review adherence',
      ),
      _EmergencySummaryTile(
        icon: Icons.event_available,
        label: 'Next visit',
        value: nextVisit.title,
        detail:
            '${formatDate(nextVisit.when)} · ${nextVisit.mode} with ${nextVisit.doctor}',
      ),
    ];

    final medsData = medications
        .map(
          (med) => _EmergencyInfoItem(
            leading: Icons.medication_liquid,
            label: med.name,
            value:
                '${med.dose}\nEffect: ${med.effect}\nLast logged: ${med.intakeLog.isEmpty ? 'No intake reported' : _relativeLabel(med.intakeLog.last)}',
          ),
        )
        .toList();

    final vitalWidgets = [...vitals]..sort((a, b) => b.date.compareTo(a.date));

    final vitalItems = vitalWidgets
        .take(4)
        .map(
          (entry) => _EmergencyInfoItem(
            leading: Icons.monitor_heart_outlined,
            label: formatDateTime(entry.date),
            value:
                '${entry.systolic}/${entry.diastolic} mmHg · HR ${entry.heartRate}',
          ),
        )
        .toList();

    final labWidgets = [...labs]
      ..sort((a, b) => b.collectedOn.compareTo(a.collectedOn));

    final labItems = labWidgets
        .map(
          (lab) => _EmergencyInfoItem(
            leading: Icons.science_outlined,
            label: '${lab.name} (${formatDate(lab.collectedOn)})',
            value: lab.unit.isNotEmpty
                ? '${lab.value} ${lab.unit}\n${lab.notes}'
                : '${lab.value}\n${lab.notes}',
          ),
        )
        .toList();

    final safetyItems = <Widget>[
      if (safetyPlan.warningSigns.trim().isNotEmpty)
        _EmergencyBulletList(
          icon: Icons.report_problem_outlined,
          title: 'Warning signs',
          items: _splitLines(safetyPlan.warningSigns),
        ),
      if (safetyPlan.copingStrategies.trim().isNotEmpty)
        _EmergencyBulletList(
          icon: Icons.self_improvement_outlined,
          title: 'Immediate coping',
          items: _splitLines(safetyPlan.copingStrategies),
        ),
      if (safetyPlan.supportContacts.trim().isNotEmpty)
        _EmergencyBulletList(
          icon: Icons.people_alt_outlined,
          title: 'Support network',
          items: _splitLines(safetyPlan.supportContacts),
        ),
      if (safetyPlan.hasEmergencyContact)
        _EmergencyInfoItem(
          leading: Icons.phone_in_talk,
          label: 'Emergency contact',
          value:
              '${safetyPlan.emergencyContactName}\n${safetyPlan.emergencyContactPhone}',
        ),
    ];

    final timelineEntries = <_EmergencyTimelineEntry>[];
    if (latestVitals != null) {
      timelineEntries.add(
        _EmergencyTimelineEntry(
          timeAgo: _relativeLabel(latestVitals.date),
          summary:
              'Vitals recorded at ${formatTime(latestVitals.date)} · ${latestVitals.label()}',
        ),
      );
    }
    for (final med in medications) {
      if (med.intakeLog.isEmpty) continue;
      final last = med.intakeLog.reduce((a, b) => a.isAfter(b) ? a : b);
      timelineEntries.add(
        _EmergencyTimelineEntry(
          timeAgo: _relativeLabel(last),
          summary: '${med.name} logged at ${formatTime(last)} (${med.dose})',
        ),
      );
    }
    timelineEntries.add(
      _EmergencyTimelineEntry(
        timeAgo: _relativeLabel(nextVisit.when),
        summary:
            'Upcoming: ${nextVisit.title} with ${nextVisit.doctor} (${nextVisit.mode})',
      ),
    );

    final overviewSections = <Widget>[
      _EmergencyHeroCard(
        profile: profile,
        nextVisit: nextVisit,
        carePlan: carePlan,
        summaryTiles: summaryTiles,
      ),
      _EmergencySectionCard(
        title: 'Active medications',
        collapsedHeight: 220,
        children: medsData,
      ),
      if (vitalItems.isNotEmpty)
        _EmergencySectionCard(
          title: 'Recent vitals',
          collapsedHeight: 200,
          children: vitalItems,
        ),
      if (labItems.isNotEmpty)
        _EmergencySectionCard(
          title: 'Recent labs',
          collapsedHeight: 200,
          children: labItems,
        ),
    ];

    final supportSections = <Widget>[
      if (timelineEntries.isNotEmpty)
        _EmergencySectionCard(
          title: 'Timeline (latest 24h)',
          collapsedHeight: 200,
          children: timelineEntries,
        ),
      if (safetyItems.isNotEmpty)
        _EmergencySectionCard(
          title: 'Safety plan snapshot',
          collapsedHeight: 220,
          children: safetyItems,
        ),
    ];

    final aiAssist = _EmergencyAiConsole(patientName: profile.name);

    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency · ${profile.name}'),
        backgroundColor: cs.error,
        foregroundColor: cs.onError,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1080;

          Widget spacedColumn(List<Widget> items) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    items[i],
                    if (i != items.length - 1) const SizedBox(height: gap),
                  ],
                ],
              );

          if (isWide) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  aiAssist,
                  const SizedBox(height: gap),
                  if (supportSections.isEmpty)
                    spacedColumn(overviewSections)
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: spacedColumn(overviewSections)),
                        const SizedBox(width: gap),
                        SizedBox(
                          width: 340,
                          child: spacedColumn(supportSections),
                        ),
                      ],
                    ),
                ],
              ),
            );
          }

          final verticalSections = [...overviewSections, ...supportSections];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                aiAssist,
                if (verticalSections.isNotEmpty) ...[
                  const SizedBox(height: gap),
                  spacedColumn(verticalSections),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  static String _bloodPressureDelta(VitalEntry latest, VitalEntry previous) {
    final deltaSys = latest.systolic - previous.systolic;
    final deltaDia = latest.diastolic - previous.diastolic;
    final signSys = deltaSys == 0
        ? ''
        : deltaSys > 0
            ? '+'
            : '';
    final signDia = deltaDia == 0
        ? ''
        : deltaDia > 0
            ? '+'
            : '';
    return '$signSys$deltaSys/$signDia$deltaDia vs prior';
  }
}

class _EmergencyHeroCard extends StatelessWidget {
  const _EmergencyHeroCard({
    required this.profile,
    required this.nextVisit,
    required this.carePlan,
    required this.summaryTiles,
  });

  final PatientProfile profile;
  final NextVisit nextVisit;
  final CarePlan carePlan;
  final List<Widget> summaryTiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Glass(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: cs.error.withValues(alpha: 0.18),
                  child: Icon(Icons.sos, color: cs.error, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.notes ?? 'Care plan active',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'MRN',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      profile.patientId,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _HeroPill(
                  icon: Icons.medical_services_outlined,
                  label: 'Lead physician',
                  value: carePlan.physician,
                ),
                _HeroPill(
                  icon: Icons.event,
                  label: 'Next visit',
                  value:
                      '${formatDate(nextVisit.when)} · ${formatTime(nextVisit.when)}',
                ),
                _HeroPill(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: nextVisit.location,
                ),
              ],
            ),
            if (summaryTiles.isNotEmpty) ...[
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 12.0;
                  final maxWidth = constraints.maxWidth;
                  final columns = maxWidth < 360 ? 1 : 2;
                  final tileWidth = columns == 1
                      ? maxWidth
                      : (maxWidth - spacing) / columns;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: summaryTiles
                        .map(
                          (tile) => SizedBox(
                            width: tileWidth,
                            child: tile,
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: cs.primary.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: cs.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencySummaryTile extends StatelessWidget {
  const _EmergencySummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final gradient = LinearGradient(
      colors: [
        cs.primary.withValues(alpha: 0.82),
        cs.primary.withValues(alpha: 0.58),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: null,
        child: Ink(
          height: 92,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: gradient,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.78),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencySectionCard extends StatefulWidget {
  const _EmergencySectionCard({
    required this.title,
    required this.children,
    this.collapsedHeight = 220,
  });

  final String title;
  final List<Widget> children;
  final double collapsedHeight;

  @override
  State<_EmergencySectionCard> createState() => _EmergencySectionCardState();
}

class _EmergencySectionCardState extends State<_EmergencySectionCard>
    with AutomaticKeepAliveClientMixin {
  bool _collapsed = true;

  @override
  bool get wantKeepAlive => true;

  List<Widget> _spacedChildren() {
    final widgets = <Widget>[];
    for (var i = 0; i < widget.children.length; i++) {
      widgets.add(widget.children[i]);
      if (i != widget.children.length - 1) {
        widgets.add(const SizedBox(height: 12));
      }
    }
    return widgets;
  }

  void _toggleCollapsed() {
    setState(() => _collapsed = !_collapsed);
  }

  void _openFullScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _EmergencySectionFullScreen(
          title: widget.title,
          children: widget.children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final content = _collapsed
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _spacedChildren(),
          );

    return Glass(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 28,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _toggleCollapsed,
                      child: Text(
                        widget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _collapsed ? 'Expand section' : 'Collapse section',
                    onPressed: _toggleCollapsed,
                    icon: Icon(
                      _collapsed
                          ? Icons.unfold_more
                          : Icons.unfold_less,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Open full screen',
                    onPressed: _openFullScreen,
                    icon: const Icon(Icons.fullscreen),
                  ),
                ],
              ),
              if (!_collapsed) const SizedBox(height: 12),
              content,
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencySectionFullScreen extends StatelessWidget {
  const _EmergencySectionFullScreen({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemBuilder: (context, index) => children[index],
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemCount: children.length,
      ),
    );
  }
}

class _EmergencyInfoItem extends StatelessWidget {
  const _EmergencyInfoItem({
    required this.leading,
    required this.label,
    required this.value,
  });

  final IconData leading;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(10),
          child: Icon(leading, color: cs.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmergencyTimelineEntry extends StatelessWidget {
  const _EmergencyTimelineEntry({
    required this.timeAgo,
    required this.summary,
  });

  final String timeAgo;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            Container(
              width: 2,
              height: 36,
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: cs.primary.withValues(alpha: 0.6),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeAgo,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                summary,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmergencyBulletList extends StatelessWidget {
  const _EmergencyBulletList({
    required this.icon,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• '),
                Expanded(
                  child: Text(
                    item,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EmergencyAiConsole extends StatefulWidget {
  const _EmergencyAiConsole({
    required this.patientName,
  });

  final String patientName;

  @override
  State<_EmergencyAiConsole> createState() => _EmergencyAiConsoleState();
}

class _EmergencyAiConsoleState extends State<_EmergencyAiConsole> {
  late final List<_AiMessage> _messages;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _messages = [
      _AiMessage(
        sender: _AiSender.ai,
        content:
            'Hello Doctor. I compiled ${widget.patientName}\'s latest vitals and recent behavior changes. Let me know what else you would like to review.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        _AiMessage(
          sender: _AiSender.doctor,
          content: text,
          timestamp: DateTime.now(),
        ),
      );
      _messages.add(
        _AiMessage(
          sender: _AiSender.ai,
          content:
              'Acknowledged. I will append additional observations regarding "$text" to the chart summary.',
          timestamp: DateTime.now().add(const Duration(seconds: 1)),
        ),
      );
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Glass(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy_outlined, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'My AI triage assistant',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 240, maxHeight: 420),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isAi = msg.sender == _AiSender.ai;
                  final align =
                      isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end;
                  final bubbleColor = isAi
                      ? cs.primary.withValues(alpha: 0.08)
                      : cs.secondary.withValues(alpha: 0.16);

                  return Column(
                    crossAxisAlignment: align,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          msg.content,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Ask My AI about recent events, medication adherence, or social context…',
                suffixIcon: IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send_rounded),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AiSender { ai, doctor }

class _AiMessage {
  _AiMessage({
    required this.sender,
    required this.content,
    required this.timestamp,
  });

  final _AiSender sender;
  final String content;
  final DateTime timestamp;
}

class _MedicationSnapshot {
  const _MedicationSnapshot({
    required this.medication,
    required this.takenAt,
  });

  final RxMedication medication;
  final DateTime takenAt;
}
