// ignore_for_file: use_build_context_synchronously

part of 'package:patient_tracker/app_modules.dart';

class MePage extends StatelessWidget {
  const MePage({
    super.key,
    required this.carePlan,
    required this.safetyPlan,
    required this.onSafetyPlanChanged,
  });

  final CarePlan carePlan;
  final SafetyPlanData safetyPlan;
  final ValueChanged<SafetyPlanData> onSafetyPlanChanged;

  @override
  Widget build(BuildContext context) {
    final pay = carePlan.insurance.youPay();
    final total = carePlan.insurance.totalCost;
    final covered = carePlan.insurance.covered;
    final coverageRatio = total <= 0 ? 0.0 : (covered / total).clamp(0.0, 1.0);
    final uncoveredRatio = (1 - coverageRatio).clamp(0.0, 1.0);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Care Plan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Glass(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Primary physician',
                  style: theme.textTheme.titleSmall?.copyWith(
                    letterSpacing: 0.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: cs.primary.withValues(alpha: 0.12),
                      child: Text(
                        _initials(carePlan.physician),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            carePlan.physician,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Guiding your personalised mental health roadmap',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () => showToast(context, 'Chat coming soon'),
                      child: const Text('Chat'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _QuickActionChip(
                      icon: Icons.video_call_outlined,
                      label: 'Schedule follow-up', onPressed: () {  },
                    ),
                    _QuickActionChip(
                      icon: Icons.description_outlined,
                      label: 'Share summary', onPressed: () {  },
                    ),
                    _QuickActionChip(
                      icon: Icons.location_pin,
                      label: 'Clinic directions', onPressed: () {  },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionHeading('Coverage snapshot'),
          const SizedBox(height: 12),
          Glass(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 420;
                final chartSize = isCompact
                    ? math.max(140.0, constraints.maxWidth * 0.6)
                    : 164.0;

                final chart = SizedBox.square(
                  dimension: chartSize,
                  child: _CoverageChart(
                    coverage: coverageRatio,
                    uncovered: uncoveredRatio,
                    coverageColor: cs.primary,
                    uncoveredColor: cs.secondary,
                    labelColor:
                        theme.textTheme.bodySmall?.color ?? cs.onSurface,
                  ),
                );

                final stats = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(coverageRatio * 100).round()}% of treatment covered',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your plan absorbs most of the current spending, leaving a manageable out-of-pocket balance.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 18),
                    _SummaryStatTile(
                      icon: Icons.payments_outlined,
                      color: cs.primary,
                      label: 'Total billed',
                      value: '\$${total.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 12),
                    _SummaryStatTile(
                      icon: Icons.shield_outlined,
                      color: cs.secondary,
                      label: 'Covered by insurance',
                      value: '\$${covered.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 12),
                    _SummaryStatTile(
                      icon: Icons.account_balance_wallet_outlined,
                      color: cs.tertiary,
                      label: 'You pay',
                      value: '\$${pay.toStringAsFixed(2)}',
                    ),
                  ],
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: chart),
                      const SizedBox(height: 18),
                      stats,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    chart,
                    const SizedBox(width: 24),
                    Expanded(child: stats),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const _SectionHeading('Medication insights'),
          const SizedBox(height: 12),
          Glass(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tracking effectiveness & tolerability',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                if (carePlan.medsEffects.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    alignment: Alignment.center,
                    child: Text(
                      'No medication insights logged yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.72),
                      ),
                    ),
                  )
                else
                  Column(
                    children: List.generate(
                      carePlan.medsEffects.length,
                      (index) {
                        final med = carePlan.medsEffects[index];
                        final accent = _medicationAccentColor(cs, index);
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == carePlan.medsEffects.length - 1
                                ? 0
                                : 14,
                          ),
                          child: _MedicationInsightCard(
                            med: med,
                            accent: accent,
                            index: index,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionHeading('Weekly focus'),
          const SizedBox(height: 12),
          Glass(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: _PlanTimeline(steps: carePlan.plan),
          ),
          const SizedBox(height: 24),
          const _SectionHeading('Safety plan'),
          const SizedBox(height: 12),
          Glass(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Know your steps before a tough moment hits.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Review your personalised safety plan whenever mood dips so you can act quickly and stay grounded.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (safetyPlan.emergencyContactName.isNotEmpty ||
                    safetyPlan.emergencyContactPhone.isNotEmpty) ...[
                  Text(
                    'Emergency contact: '
                    '${safetyPlan.emergencyContactName.isEmpty ? 'Not set' : safetyPlan.emergencyContactName}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (safetyPlan.emergencyContactPhone.isNotEmpty)
                    Text(
                      safetyPlan.emergencyContactPhone,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.primary),
                    ),
                  const SizedBox(height: 12),
                ] else ...[
                  Text(
                    'Emergency contact: Not set yet.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SafetyPlanPage(
                        initialData: safetyPlan,
                        onSave: onSafetyPlanChanged,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.shield_outlined),
                  label: const Text('Open safety plan'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionHeading('Expected outcomes'),
          const SizedBox(height: 12),
          Glass(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: _OutcomeChips(items: carePlan.expectedOutcomes),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'Dr';
    if (parts.length == 1) {
      final first = parts.first;
      return first.length >= 2
          ? first.substring(0, 2).toUpperCase()
          : first.toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class SafetyPlanPage extends StatefulWidget {
  const SafetyPlanPage(
      {super.key, required this.initialData, required this.onSave});

  final SafetyPlanData initialData;
  final ValueChanged<SafetyPlanData> onSave;

  @override
  State<SafetyPlanPage> createState() => _SafetyPlanPageState();
}

class _SafetyPlanPageState extends State<SafetyPlanPage> {
  late final TextEditingController _warningSigns;
  late final TextEditingController _copingStrategies;
  late final TextEditingController _supportContacts;
  late final TextEditingController _nextSteps;
  late final TextEditingController _contactName;
  late final TextEditingController _contactPhone;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _warningSigns = TextEditingController(text: data.warningSigns);
    _copingStrategies = TextEditingController(text: data.copingStrategies);
    _supportContacts = TextEditingController(text: data.supportContacts);
    _nextSteps = TextEditingController(text: data.nextSteps);
    _contactName = TextEditingController(text: data.emergencyContactName);
    _contactPhone = TextEditingController(text: data.emergencyContactPhone);
  }

  @override
  void dispose() {
    _warningSigns.dispose();
    _copingStrategies.dispose();
    _supportContacts.dispose();
    _nextSteps.dispose();
    _contactName.dispose();
    _contactPhone.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) {
      _dirty = true;
    }
  }

  void _save() {
    final updated = SafetyPlanData(
      warningSigns: _warningSigns.text.trim(),
      copingStrategies: _copingStrategies.text.trim(),
      supportContacts: _supportContacts.text.trim(),
      nextSteps: _nextSteps.text.trim(),
      emergencyContactName: _contactName.text.trim(),
      emergencyContactPhone: _contactPhone.text.trim(),
    );
    widget.onSave(updated);
    showToast(context, 'Safety plan updated');
    Navigator.of(context).pop();
  }

  Future<void> _launchOrToast(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      showToast(
          context, 'Unable to open ${uri.scheme == 'tel' ? 'phone' : 'link'}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final contactDial = _contactPhone.text.replaceAll(RegExp(r'[^0-9+]'), '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Plan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _dirty ? _save : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Glass(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay oriented when things feel hard',
                  style:
                      text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fill in what works for you. Update the plan anytime and keep emergency numbers close at hand.',
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _EditableSafetySection(
            icon: Icons.lightbulb_outline,
            title: 'Warning signs',
            hint:
                'List feelings, thoughts, or situations that signal things are getting tough...',
            controller: _warningSigns,
            onChanged: (_) => setState(_markDirty),
          ),
          const SizedBox(height: 12),
          _EditableSafetySection(
            icon: Icons.self_improvement,
            title: 'Coping skills that help',
            hint:
                'Grounding exercises, breathing patterns, music, or movement that resets you...',
            controller: _copingStrategies,
            onChanged: (_) => setState(_markDirty),
          ),
          const SizedBox(height: 12),
          _EditableSafetySection(
            icon: Icons.groups_outlined,
            title: 'People & supports',
            hint:
                'Friends, family, clinicians, or helplines you can reach out to...',
            controller: _supportContacts,
            onChanged: (_) => setState(_markDirty),
          ),
          const SizedBox(height: 12),
          _EditableSafetySection(
            icon: Icons.route_outlined,
            title: 'Next safe steps',
            hint:
                'Move to another room, set a brief timer, follow a routine that keeps you grounded...',
            controller: _nextSteps,
            onChanged: (_) => setState(_markDirty),
          ),
          const SizedBox(height: 16),
          Glass(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency contact',
                  style:
                      text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _contactName,
                  decoration: const InputDecoration(
                    labelText: 'Name or role',
                  ),
                  onChanged: (_) => setState(_markDirty),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contactPhone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                  ),
                  onChanged: (_) => setState(_markDirty),
                ),
                if (contactDial.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      _launchOrToast(
                        context,
                        Uri(scheme: 'tel', path: contactDial),
                      );
                    },
                    icon: const Icon(Icons.phone),
                    label: Text(
                        'Call ${_contactName.text.trim().isEmpty ? 'emergency contact' : _contactName.text.trim()}'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Glass(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Crisis contacts',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 10),
                _SafetyContactTile(
                  icon: Icons.local_phone,
                  label: 'Hospital emergency line',
                  detail: 'Immediate response · 24/7',
                  onTap: () => _launchOrToast(
                    context,
                    Uri(scheme: 'tel', path: '911'),
                  ),
                ),
                const SizedBox(height: 8),
                _SafetyContactTile(
                  icon: Icons.support_agent,
                  label: '988 Suicide & Crisis Lifeline',
                  detail: 'Call or text 988 any time',
                  onTap: () => _launchOrToast(
                    context,
                    Uri(scheme: 'tel', path: '988'),
                  ),
                ),
                const SizedBox(height: 8),
                _SafetyContactTile(
                  icon: Icons.chat_bubble_outline,
                  label: 'Nurse care team chat',
                  detail: 'Weekdays 8:00–18:00',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CareTeamMessagesPage(
                        initialConversation: ConversationType.nurse,
                      ),
                    ),
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

class _SafetyContactTile extends StatelessWidget {
  const _SafetyContactTile({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.12),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: text.bodyLarge),
                  const SizedBox(height: 2),
                  Text(detail, style: text.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _EditableSafetySection extends StatelessWidget {
  const _EditableSafetySection({
    required this.icon,
    required this.title,
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = theme.textTheme;

    return Glass(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: cs.primary.withValues(alpha: 0.16),
                ),
                child: Icon(icon, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: null,
            minLines: 4,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );
    return Text(label, style: textStyle);
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({required this.icon, required this.label, required VoidCallback onPressed});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: cs.surface.withValues(alpha: 0.16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _SummaryStatTile extends StatelessWidget {
  const _SummaryStatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: text.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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

class _CoverageChart extends StatelessWidget {
  const _CoverageChart({
    required this.coverage,
    required this.uncovered,
    required this.coverageColor,
    required this.uncoveredColor,
    required this.labelColor,
  });

  final double coverage;
  final double uncovered;
  final Color coverageColor;
  final Color uncoveredColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          painter: _CoveragePainter(
            coverage: coverage,
            uncovered: uncovered,
            coverageColor: coverageColor,
            uncoveredColor: uncoveredColor,
          ),
          child: const SizedBox.expand(),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${(coverage * 100).round()}%',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'covered',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: labelColor.withValues(alpha: 0.74)),
            ),
          ],
        ),
      ],
    );
  }
}

class _CoveragePainter extends CustomPainter {
  _CoveragePainter({
    required this.coverage,
    required this.uncovered,
    required this.coverageColor,
    required this.uncoveredColor,
  });

  final double coverage;
  final double uncovered;
  final Color coverageColor;
  final Color uncoveredColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final strokeWidth = radius * 0.24;
    final rect =
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = uncoveredColor.withValues(alpha: 0.32)
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, 2 * math.pi, false, backgroundPaint);

    if (coverage > 0) {
      final coveragePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + 2 * math.pi * coverage,
          colors: [
            coverageColor.withValues(alpha: 0.85),
            coverageColor,
          ],
        ).createShader(rect);

      final sweepAngle = 2 * math.pi * coverage;
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweepAngle,
        false,
        coveragePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CoveragePainter oldDelegate) {
    return coverage != oldDelegate.coverage ||
        uncovered != oldDelegate.uncovered ||
        coverageColor != oldDelegate.coverageColor ||
        uncoveredColor != oldDelegate.uncoveredColor;
  }
}

Color _medicationAccentColor(ColorScheme cs, int index) {
  const fallback = [
    Colors.teal,
    Colors.deepPurpleAccent,
    Colors.orange,
    Colors.blueGrey,
  ];
  final palette = [
    cs.primary,
    cs.secondary,
    cs.tertiary,
    ...fallback,
  ];
  return palette[index % palette.length];
}

class _MedicationInsightCard extends StatelessWidget {
  const _MedicationInsightCard({
    required this.med,
    required this.accent,
    required this.index,
  });

  final MedEffect med;
  final Color accent;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentBg = accent.withValues(alpha: 0.14);
    final border = accent.withValues(alpha: 0.22);
    final labelColor =
        theme.textTheme.bodySmall?.color?.withValues(alpha: 0.72);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.06),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.medication_liquid_outlined,
                  color: accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Medication ${index + 1} • Active',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: labelColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MedicationInsightRow(
            icon: Icons.healing_outlined,
            iconColor: accent,
            title: 'Therapeutic focus',
            body: med.effect,
          ),
          const SizedBox(height: 12),
          _MedicationInsightRow(
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orangeAccent,
            title: 'Observed side effects',
            body: med.sideEffects,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _InsightTag(
                icon: Icons.stacked_bar_chart,
                label: 'Stability tracking',
                color: accent,
              ),
              _InsightTag(
                icon: Icons.note_alt_outlined,
                label: 'Add journal entry',
                color: accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MedicationInsightRow extends StatelessWidget {
  const _MedicationInsightRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightTag extends StatelessWidget {
  const _InsightTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: textStyle),
        ],
      ),
    );
  }
}

class _PlanTimeline extends StatelessWidget {
  const _PlanTimeline({required this.steps});
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (index) {
        final isLast = index == steps.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 28,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.2),
                          theme.colorScheme.primary.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 18),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.surface.withValues(alpha: 0.14),
                ),
                child: Text(
                  steps[index],
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _OutcomeChips extends StatelessWidget {
  const _OutcomeChips({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.16),
                    cs.secondary.withValues(alpha: 0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag, size: 18, color: cs.primary),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 200,
                    child: Text(
                      item,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

/// ===================== Substance Use Disorder =====================
