// lib/features/medications/medication_timeline_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/utils/date_formats.dart';
import '../../data/models/rx_check_in.dart';

class MedicationTimelineArgs {
  const MedicationTimelineArgs({
    required this.medicationId,
    this.medicationDisplayName,
    this.checkIns = const <RxCheckIn>[],
  });

  final String medicationId;
  final String? medicationDisplayName;
  final List<RxCheckIn> checkIns;
}

class MedicationTimelineScreen extends StatefulWidget {
  const MedicationTimelineScreen({
    super.key,
    required this.medicationId,
    this.medicationDisplayName,
    this.checkIns = const <RxCheckIn>[],
  });

  final String medicationId;
  final String? medicationDisplayName;
  final List<RxCheckIn> checkIns;

  @override
  State<MedicationTimelineScreen> createState() =>
      _MedicationTimelineScreenState();
}

class _MedicationTimelineScreenState extends State<MedicationTimelineScreen> {
  late List<RxCheckIn> _sortedEntries;
  late Map<DateTime, List<RxCheckIn>> _entriesByDay;
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _rebuildEntries();
  }

  @override
  void didUpdateWidget(covariant MedicationTimelineScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.checkIns, widget.checkIns)) {
      _rebuildEntries(preserveSelected: _selectedDay);
      setState(() {});
    }
  }

  void _rebuildEntries({DateTime? preserveSelected}) {
    _sortedEntries = List<RxCheckIn>.from(widget.checkIns)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _entriesByDay = <DateTime, List<RxCheckIn>>{};
    for (final entry in _sortedEntries) {
      final dayKey = _dateOnly(entry.timestamp);
      final bucket = _entriesByDay.putIfAbsent(dayKey, () => <RxCheckIn>[]);
      bucket.add(entry);
    }
    for (final bucket in _entriesByDay.values) {
      bucket.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    final today = _dateOnly(DateTime.now());
    if (preserveSelected != null) {
      _selectedDay = _dateOnly(preserveSelected);
    } else if (_entriesByDay.containsKey(today)) {
      _selectedDay = today;
    } else if (_sortedEntries.isNotEmpty) {
      _selectedDay = _dateOnly(_sortedEntries.first.timestamp);
    } else {
      _selectedDay = today;
    }
    _focusedDay = _selectedDay;
  }

  DateTime _dateOnly(DateTime input) =>
      DateTime(input.year, input.month, input.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<RxCheckIn> _entriesFor(DateTime day) =>
      _entriesByDay[_dateOnly(day)] ?? <RxCheckIn>[];

  bool get _isAllMedsScope {
    if (widget.medicationId == 'all') return true;
    final label = widget.medicationDisplayName ?? '';
    return label.toLowerCase().contains('all');
  }

  String _titleText() {
    final label = widget.medicationDisplayName ?? widget.medicationId;
    if (label.trim().isEmpty) {
      return 'Medication history';
    }
    return '$label history';
  }

  String _selectedDayLabel(DateTime day) {
    final today = _dateOnly(DateTime.now());
    if (_isSameDay(day, today)) {
      return 'Today';
    }
    if (_isSameDay(day, today.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return DateFormat('MMM d, yyyy').format(day);
  }

  int _recentRecordedDays(int days) {
    final today = _dateOnly(DateTime.now());
    final start = today.subtract(Duration(days: days - 1));
    return _entriesByDay.keys
        .where((day) => !day.isBefore(start) && !day.isAfter(today))
        .length;
  }

  Widget _buildSummaryStrip(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lastCheckIn =
        _sortedEntries.isNotEmpty ? _sortedEntries.first.timestamp : null;
    final recentDays = _recentRecordedDays(7);

    Widget metric({required String label, required String value}) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          metric(label: 'Last 7 days', value: '$recentDays/7'),
          const SizedBox(width: 16),
          metric(
            label: 'Most recent',
            value: lastCheckIn == null
                ? 'None'
                : DateFormat.Hm().format(lastCheckIn),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget dayCell({
      required DateTime day,
      required Color textColor,
      Color? background,
      BoxBorder? border,
      FontWeight? fontWeight,
    }) {
      return Center(
        child: Container(
          width: 36,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: border,
          ),
          child: Text(
            '${day.day}',
            style: textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: fontWeight,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: TableCalendar<RxCheckIn>(
        firstDay: DateTime(2020),
        lastDay: DateTime(2035),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => _isSameDay(day, _selectedDay),
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = _dateOnly(selected);
            _focusedDay = focused;
          });
        },
        calendarFormat: CalendarFormat.month,
        eventLoader: _entriesFor,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ) ??
              const TextStyle(),
          leftChevronIcon: Icon(Icons.chevron_left, color: scheme.onSurface),
          rightChevronIcon: Icon(Icons.chevron_right, color: scheme.onSurface),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ) ??
              const TextStyle(),
          weekendStyle: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ) ??
              const TextStyle(),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: true,
          todayDecoration: const BoxDecoration(),
          selectedDecoration: const BoxDecoration(),
          defaultTextStyle:
              textTheme.bodySmall?.copyWith(color: scheme.onSurface) ??
                  const TextStyle(),
          weekendTextStyle:
              textTheme.bodySmall?.copyWith(color: scheme.onSurface) ??
                  const TextStyle(),
          outsideTextStyle: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
              ) ??
              const TextStyle(),
          disabledTextStyle: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
              ) ??
              const TextStyle(),
          markerDecoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary.withValues(alpha: 0.5),
          ),
          markersAlignment: Alignment.bottomCenter,
          markersMaxCount: 1,
        ),
        calendarBuilders: CalendarBuilders(
          selectedBuilder: (context, day, _) {
            return dayCell(
              day: day,
              textColor: scheme.onSurface,
              background: scheme.primary.withValues(alpha: 0.18),
              fontWeight: FontWeight.w600,
            );
          },
          todayBuilder: (context, day, _) {
            return dayCell(
              day: day,
              textColor: scheme.onSurface,
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.4),
                width: 1,
              ),
              fontWeight: FontWeight.w600,
            );
          },
          defaultBuilder: (context, day, _) {
            return dayCell(
              day: day,
              textColor: scheme.onSurface,
            );
          },
          outsideBuilder: (context, day, _) {
            return dayCell(
              day: day,
              textColor: scheme.onSurfaceVariant.withValues(alpha: 0.45),
            );
          },
          markerBuilder: (context, day, events) {
            if (events.isEmpty) {
              return const SizedBox.shrink();
            }
            return Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEntryRow(BuildContext context, RxCheckIn entry) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: scheme.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatTime(entry.timestamp),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Checked in',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                      ),
                ),
                if (_isAllMedsScope)
                  Text(
                    entry.medicationId,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              scheme.onSurfaceVariant.withValues(alpha: 0.65),
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 32,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 10),
          Text(
            'No check-ins for this day',
            style: Theme.of(context).textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Check in from Rx Suggestions to add history.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lastCheckIn =
        _sortedEntries.isNotEmpty ? _sortedEntries.first.timestamp : null;
    final entries = _entriesFor(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleText()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last check-in: ${lastCheckIn == null ? 'None' : DateFormat.yMMMd().add_jm().format(lastCheckIn)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              scheme.onSurfaceVariant.withValues(alpha: 0.75),
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryStrip(context),
                  const SizedBox(height: 16),
                  _buildCalendar(context),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                _selectedDayLabel(_selectedDay),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
              ),
            ),
          ),
          if (entries.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: _buildEmptyState(context)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = entries[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildEntryRow(context, entry),
                    );
                  },
                  childCount: entries.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
