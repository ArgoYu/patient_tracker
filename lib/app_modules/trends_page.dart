part of 'package:patient_tracker/app_modules.dart';

enum SignalTone { good, neutral, caution }

class SignalStatus {
  const SignalStatus(this.label, this.tone);

  final String label;
  final SignalTone tone;
}

class TrendsPage extends StatefulWidget {
  const TrendsPage(
      {super.key,
      required this.history,
      required this.vitals,
      required this.labs});

  final List<FeelingEntry> history;
  final List<VitalEntry> vitals;
  final List<LabResult> labs;

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  bool _showAllVitals = false;

  List<FeelingEntry> get _recent => widget.history.length <= 7
      ? List<FeelingEntry>.from(widget.history)
      : widget.history.sublist(widget.history.length - 7);

  double? _avg(List<FeelingEntry> entries) {
    if (entries.isEmpty) return null;
    final total = entries.fold<int>(0, (sum, e) => sum + e.score);
    return total / entries.length;
  }

  String _avgLabel(double? value) =>
      value == null ? '--' : value.toStringAsFixed(1);

  SignalStatus _moodSignalStatus(List<FeelingEntry> entries) {
    if (entries.isEmpty) {
      return const SignalStatus('Needs data', SignalTone.caution);
    }
    final latest = entries
        .map((e) => e.date)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    if (latest.isBefore(cutoff)) {
      return const SignalStatus('Limited data', SignalTone.neutral);
    }
    return const SignalStatus('Tracking', SignalTone.good);
  }

  SignalStatus _vitalsSignalStatus(List<VitalEntry> vitalsSorted) {
    if (vitalsSorted.length < 2) {
      return const SignalStatus('Needs data', SignalTone.caution);
    }
    final current = vitalsSorted[0];
    final previous = vitalsSorted[1];
    const systolicThreshold = 6;
    const heartRateThreshold = 6;
    final systolicDiff = (current.systolic - previous.systolic).abs();
    final hrDiff = (current.heartRate - previous.heartRate).abs();
    if (systolicDiff <= systolicThreshold && hrDiff <= heartRateThreshold) {
      return const SignalStatus('Stable', SignalTone.good);
    }
    return const SignalStatus('Changing', SignalTone.neutral);
  }

  SignalStatus _labsSignalStatus(List<LabResult> labsSorted) {
    if (labsSorted.isEmpty) {
      return const SignalStatus('Needs data', SignalTone.caution);
    }
    return const SignalStatus('Up to date', SignalTone.good);
  }

  SignalStatus _timelineSignalStatus(List<FeelingEntry> entries) {
    if (entries.isEmpty) {
      return const SignalStatus('No events', SignalTone.neutral);
    }
    return const SignalStatus('Updated', SignalTone.good);
  }

  @override
  Widget build(BuildContext context) {
    final entries = List<FeelingEntry>.from(widget.history);
    final recent = _recent;
    final recentAvg = _avg(recent);
    final overallAvg = _avg(entries);
    final trendDelta = (recentAvg != null && overallAvg != null)
        ? recentAvg - overallAvg
        : null;
    final deltaText = trendDelta == null
        ? 'Log more entries to see trends.'
        : trendDelta.abs() < 0.05
            ? 'Mood steady compared to average.'
            : trendDelta > 0
                ? 'Mood trending up over last 7 entries.'
                : 'Mood trending down recently.';

    final latest = entries.isNotEmpty
        ? entries.reduce((a, b) => a.date.isAfter(b.date) ? a : b)
        : null;
    final vitalsSorted = List<VitalEntry>.from(widget.vitals)
      ..sort((a, b) => b.date.compareTo(a.date));
    final labsSorted = List<LabResult>.from(widget.labs)
      ..sort((a, b) => b.collectedOn.compareTo(a.collectedOn));

    final moodStatus = _moodSignalStatus(entries);
    final vitalsStatus = _vitalsSignalStatus(vitalsSorted);
    final labsStatus = _labsSignalStatus(labsSorted);
    final timelineStatus = _timelineSignalStatus(entries);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trends'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SignalsSummaryCard(
            title: "Today's Signals",
            items: [
              SignalTile(
                icon: Icons.mood_outlined,
                label: 'Mood',
                status: moodStatus,
              ),
              SignalTile(
                icon: Icons.monitor_heart_outlined,
                label: 'Vitals',
                status: vitalsStatus,
              ),
              SignalTile(
                icon: Icons.science_outlined,
                label: 'Labs',
                status: labsStatus,
              ),
              SignalTile(
                icon: Icons.event_note_outlined,
                label: 'Timeline',
                status: timelineStatus,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TrendSectionCard(
            title: 'Mood',
            trailing: SignalChip(status: moodStatus),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _TrendStat(
                        label: 'Last entry',
                        value: latest == null ? '--' : '${latest.score}/5',
                        footer: latest == null
                            ? 'Log a feeling to get started.'
                            : formatDateTime(latest.date)),
                    _TrendStat(
                        label: 'Average (7)',
                        value: '${_avgLabel(recentAvg)}/5',
                        footer: recent.isEmpty
                            ? 'Need more recent logs.'
                            : 'Past 7 entries.'),
                    _TrendStat(
                        label: 'Average (all)',
                        value: '${_avgLabel(overallAvg)}/5',
                        footer: entries.isEmpty
                            ? 'No entries yet.'
                            : '${entries.length} total logs.'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  deltaText,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.75)),
                ),
                const SizedBox(height: 14),
                _Subpanel(
                  child: entries.isEmpty
                      ? const _EmptyState(
                          icon: Icons.mood_outlined,
                          title: 'No mood entries yet',
                          message:
                              'Log feelings from Notifications to see trends.',
                        )
                      : SizedBox(
                          height: 190,
                          child: _MoodTrendChart(entries: entries),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TrendSectionCard(
            title: 'Vitals',
            trailing: SignalChip(status: vitalsStatus),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Subpanel(
                  child: vitalsSorted.isEmpty
                      ? const _EmptyState(
                          icon: Icons.monitor_heart_outlined,
                          title: 'No vital readings yet',
                          message:
                              'Capture blood pressure and heart rate to see patterns.',
                        )
                      : SizedBox(
                          height: 190,
                          child: _VitalsBarChart(vitals: vitalsSorted),
                        ),
                ),
                if (vitalsSorted.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Recent readings',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const Spacer(),
                      if (vitalsSorted.length > 3)
                        TextButton(
                          onPressed: () {
                            setState(() => _showAllVitals = !_showAllVitals);
                          },
                          child: Text(_showAllVitals ? 'Show less' : 'View all'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Blood Pressure')),
                        DataColumn(label: Text('Heart Rate')),
                        DataColumn(label: Text('Trend')),
                      ],
                      rows: List<DataRow>.generate(
                        _showAllVitals
                            ? vitalsSorted.length
                            : math.min(3, vitalsSorted.length),
                        (i) {
                          final current = vitalsSorted[i];
                          final previous = i + 1 < vitalsSorted.length
                              ? vitalsSorted[i + 1]
                              : null;
                          final diff = previous == null
                              ? null
                              : current.systolic - previous.systolic;
                          final diffText = diff == null
                              ? '--'
                              : diff == 0
                                  ? '0'
                                  : diff > 0
                                      ? '+$diff'
                                      : '$diff';
                          final diffColor = diff == null
                              ? Theme.of(context).textTheme.bodyMedium?.color
                              : diff > 0
                                  ? Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withValues(alpha: 0.85)
                                  : diff < 0
                                      ? Theme.of(context)
                                          .colorScheme
                                          .tertiary
                                          .withValues(alpha: 0.85)
                                      : Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color;
                          return DataRow(
                            cells: [
                              DataCell(Text(formatDateTime(current.date))),
                              DataCell(Text(
                                  '${current.systolic}/${current.diastolic} mmHg')),
                              DataCell(Text('${current.heartRate} bpm')),
                              DataCell(Text(diffText,
                                  style: TextStyle(color: diffColor))),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          TrendSectionCard(
            title: 'Labs',
            trailing: SignalChip(status: labsStatus),
            child: labsSorted.isEmpty
                ? const _EmptyState(
                    icon: Icons.science_outlined,
                    title: 'No lab results yet',
                    message: 'Add lab records to keep this signal up to date.',
                  )
                : Column(
                    children: [
                      for (int i = 0; i < labsSorted.length; i++)
                        _LabRow(
                          lab: labsSorted[i],
                          isLast: i == labsSorted.length - 1,
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          TrendSectionCard(
            title: 'Timeline',
            trailing: SignalChip(status: timelineStatus),
            child: entries.isEmpty
                ? const _EmptyState(
                    icon: Icons.event_note_outlined,
                    title: 'No timeline events',
                    message: 'Log a feeling to see updates here.',
                  )
                : Column(
                    children: entries.reversed
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Text('Score ${e.score}/5'),
                                const SizedBox(width: 12),
                                Expanded(child: Text(formatDateTime(e.date))),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class SignalsSummaryCard extends StatelessWidget {
  const SignalsSummaryCard({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return TrendSectionCard(
      title: title,
      prominent: true,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: items,
      ),
    );
  }
}

class SignalTile extends StatelessWidget {
  const SignalTile({
    super.key,
    required this.icon,
    required this.label,
    required this.status,
  });

  final IconData icon;
  final String label;
  final SignalStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = _signalAccentColor(colors, status.tone);
    final text = Theme.of(context).textTheme;

    return Container(
      width: 168,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colors.surface.withValues(alpha: 0.08),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.labelLarge),
                const SizedBox(height: 2),
                Text(
                  status.label,
                  style: text.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
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

class SignalChip extends StatelessWidget {
  const SignalChip({super.key, required this.status});

  final SignalStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = _signalAccentColor(colors, status.tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_graph_outlined, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class TrendSectionCard extends StatelessWidget {
  const TrendSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.prominent = false,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final surfaceOpacity = prominent ? 0.12 : 0.08;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: colors.surface.withValues(alpha: surfaceOpacity),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Subpanel extends StatelessWidget {
  const _Subpanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: colors.surface.withValues(alpha: 0.06),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: child,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: colors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: text.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.7),
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

class _LabRow extends StatelessWidget {
  const _LabRow({required this.lab, required this.isLast});

  final LabResult lab;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isNormal = lab.value.trim().toLowerCase() == 'normal';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast
                ? Colors.transparent
                : colors.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lab.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatDate(lab.collectedOn),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                lab.valueWithUnit(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (isNormal) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: colors.tertiary.withValues(alpha: 0.8),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

Color _signalAccentColor(ColorScheme colors, SignalTone tone) {
  switch (tone) {
    case SignalTone.good:
      return colors.primary.withValues(alpha: 0.9);
    case SignalTone.caution:
      return colors.tertiary.withValues(alpha: 0.9);
    case SignalTone.neutral:
      return colors.onSurface.withValues(alpha: 0.8);
  }
}

class _TrendStat extends StatelessWidget {
  const _TrendStat(
      {required this.label, required this.value, required this.footer});

  final String label;
  final String value;
  final String footer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 156,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colors.surface.withValues(alpha: 0.08),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelLarge),
          const SizedBox(height: 6),
          Text(value,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            footer,
            style: text.labelSmall
                ?.copyWith(color: colors.onSurface.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _MoodTrendChart extends StatelessWidget {
  const _MoodTrendChart({required this.entries});

  final List<FeelingEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final sorted = List<FeelingEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));
    final data =
        sorted.length > 14 ? sorted.sublist(sorted.length - 14) : sorted;
    final keyData = data.isEmpty ? '' : data.last.date.toIso8601String();

    return TweenAnimationBuilder<double>(
      key: ValueKey('${data.length}-$keyData'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return CustomPaint(
          painter: _MoodTrendPainter(
            data: data,
            progress: value,
            color: Theme.of(context).colorScheme.primary,
            axisColor:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
            textStyle: Theme.of(context).textTheme.bodySmall,
          ),
        );
      },
    );
  }
}

class _MoodTrendPainter extends CustomPainter {
  _MoodTrendPainter({
    required this.data,
    required this.progress,
    required this.color,
    required this.axisColor,
    required this.textStyle,
  });

  final List<FeelingEntry> data;
  final double progress;
  final Color color;
  final Color axisColor;
  final TextStyle? textStyle;

  static const double _topPadding = 12;
  static const double _bottomPadding = 26;
  static const double _leftPadding = 24;
  static const double _rightPadding = 12;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartHeight = math.max(1, size.height - _topPadding - _bottomPadding);
    final chartWidth = math.max(1, size.width - _leftPadding - _rightPadding);

    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      final x = data.length == 1
          ? _leftPadding + chartWidth / 2
          : _leftPadding + (chartWidth / (data.length - 1)) * i;
      final normalized = (entry.score - 1) / 4; // score 1-5
      final y = _topPadding + chartHeight * (1 - normalized);
      points.add(Offset(x, y));
    }

    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;

    // Horizontal grid lines for each score level.
    for (var level = 0; level < 5; level++) {
      final y = _topPadding + chartHeight * (1 - level / 4);
      canvas.drawLine(Offset(_leftPadding, y),
          Offset(size.width - _rightPadding, y), axisPaint);
      _drawLabel(canvas, Offset(4, y - 8), '${level + 1}');
    }

    if (points.isEmpty) return;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final lineMetrics = linePath.computeMetrics();
    final animatedPath = Path();
    for (final metric in lineMetrics) {
      animatedPath.addPath(
          metric.extractPath(0, metric.length * progress), Offset.zero);
    }

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(animatedPath, linePaint);

    // Draw points up to progress.
    final maxIndex = progress >= 1
        ? points.length - 1
        : math.max(
            0,
            math
                .min(points.length - 1, (points.length - 1) * progress)
                .floor());
    for (var i = 0; i <= maxIndex; i++) {
      final pt = points[i];
      canvas.drawCircle(pt, 4.5, Paint()..color = color);
      canvas.drawCircle(pt, 8, Paint()..color = color.withValues(alpha: 0.18));
    }

    // Labels along x-axis (date)
    final visibleLabels = data.length == 1 ? 1 : data.length.clamp(2, 6);
    final step =
        visibleLabels == 1 ? 0 : (data.length - 1) / (visibleLabels - 1);
    for (var i = 0; i < visibleLabels; i++) {
      final dataIndex = (i * step).round().clamp(0, data.length - 1);
      final pt = points[dataIndex];
      _drawLabel(canvas, Offset(pt.dx - 20, size.height - _bottomPadding + 6),
          _fmtShortDate(data[dataIndex].date));
    }
  }

  void _drawLabel(Canvas canvas, Offset offset, String text) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  String _fmtShortDate(DateTime d) => '${d.month}/${d.day}';

  @override
  bool shouldRepaint(covariant _MoodTrendPainter oldDelegate) {
    final sameData = _entriesEqual(oldDelegate.data, data);
    return !sameData ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }

  bool _entriesEqual(List<FeelingEntry> a, List<FeelingEntry> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].score != b[i].score ||
          a[i].date != b[i].date ||
          a[i].note != b[i].note) {
        return false;
      }
    }
    return true;
  }
}

class _VitalsBarChart extends StatelessWidget {
  const _VitalsBarChart({required this.vitals});

  final List<VitalEntry> vitals;

  @override
  Widget build(BuildContext context) {
    if (vitals.isEmpty) return const SizedBox.shrink();

    final ordered = List<VitalEntry>.from(vitals)
      ..sort((a, b) => a.date.compareTo(b.date));
    final maxSystolic =
        ordered.fold<int>(1, (prev, e) => math.max(prev, e.systolic));
    final barColor = Theme.of(context).colorScheme.primary;
    final labelStyle = Theme.of(context).textTheme.bodySmall;

    String shortDate(DateTime d) => '${d.month}/${d.day}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = math.max(50.0, constraints.maxHeight - 40);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (int i = 0; i < ordered.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Tooltip(
                        message:
                            '${ordered[i].systolic}/${ordered[i].diastolic} mmHg - HR ${ordered[i].heartRate}',
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: math.max(
                              8,
                              availableHeight *
                                  (ordered[i].systolic / maxSystolic),
                            ),
                            width: 24,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  barColor.withValues(alpha: 0.85),
                                  barColor.withValues(alpha: 0.55),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${ordered[i].systolic}',
                        style:
                            labelStyle?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        shortDate(ordered[i].date),
                        style: labelStyle,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// ===================== Me =====================
