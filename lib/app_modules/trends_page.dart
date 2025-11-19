part of 'package:patient_tracker/app_modules.dart';

class TrendsPage extends StatelessWidget {
  const TrendsPage(
      {super.key,
      required this.history,
      required this.vitals,
      required this.labs});

  final List<FeelingEntry> history;
  final List<VitalEntry> vitals;
  final List<LabResult> labs;

  List<FeelingEntry> get _recent => history.length <= 7
      ? List<FeelingEntry>.from(history)
      : history.sublist(history.length - 7);

  double? _avg(List<FeelingEntry> entries) {
    if (entries.isEmpty) return null;
    final total = entries.fold<int>(0, (sum, e) => sum + e.score);
    return total / entries.length;
  }

  String _avgLabel(double? value) =>
      value == null ? '--' : value.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final entries = List<FeelingEntry>.from(history);
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

    final latest = entries.isNotEmpty ? entries.last : null;
    final vitalsSorted = List<VitalEntry>.from(vitals)
      ..sort((a, b) => b.date.compareTo(a.date));
    final labsSorted = List<LabResult>.from(labs)
      ..sort((a, b) => b.collectedOn.compareTo(a.collectedOn));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trends'),
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
                Text('Mood summary',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
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
                Text(deltaText),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mood trend (last entries)',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SizedBox(
                  height: 180,
                  child: _MoodTrendChart(entries: entries),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vitals (Blood Pressure & Heart Rate)',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (vitalsSorted.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No vital records yet.'),
                  )
                else ...[
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
                        vitalsSorted.length,
                        (i) {
                          final current = vitalsSorted[i];
                          final previous = i + 1 < vitalsSorted.length
                              ? vitalsSorted[i + 1]
                              : null;
                          final diff = previous == null
                              ? null
                              : current.systolic - previous.systolic;
                          final diffText = diff == null
                              ? '—'
                              : diff == 0
                                  ? '0'
                                  : diff > 0
                                      ? '+$diff'
                                      : '$diff';
                          final diffColor = diff == null
                              ? Theme.of(context).textTheme.bodyMedium?.color
                              : diff > 0
                                  ? Colors.redAccent
                                  : diff < 0
                                      ? Colors.green
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
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
                    child: _VitalsBarChart(vitals: vitalsSorted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lab Results',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (labsSorted.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No lab results captured yet.'),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Collected')),
                        DataColumn(label: Text('Test')),
                        DataColumn(label: Text('Result')),
                        DataColumn(label: Text('Notes')),
                      ],
                      rows: labsSorted
                          .map(
                            (lab) => DataRow(
                              cells: [
                                DataCell(Text(formatDate(lab.collectedOn))),
                                DataCell(Text(lab.name)),
                                DataCell(Text(lab.valueWithUnit())),
                                DataCell(Text(lab.notes?.isNotEmpty == true
                                    ? lab.notes!
                                    : '—')),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Timeline',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                        'No mood entries yet. Log feelings from Notifications.'),
                  )
                else
                  ...entries.reversed.map(
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
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelLarge),
          const SizedBox(height: 6),
          Text(value,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(footer, style: text.labelSmall),
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
      return const Center(child: Text('No mood entries yet.'));
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
                            '${ordered[i].systolic}/${ordered[i].diastolic} mmHg · HR ${ordered[i].heartRate}',
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
