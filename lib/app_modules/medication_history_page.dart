part of 'package:patient_tracker/app_modules.dart';

class MedicationHistoryPage extends StatefulWidget {
  const MedicationHistoryPage({super.key, required this.medication});

  static const String routeName = '/medication-history';

  final RxMedication medication;

  @override
  State<MedicationHistoryPage> createState() => _MedicationHistoryPageState();
}

class _MedicationHistoryPageState extends State<MedicationHistoryPage> {
  late final List<DateTime> _sortedLogs;
  late final Map<DateTime, List<DateTime>> _entriesByDay;
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _sortedLogs = List<DateTime>.from(widget.medication.intakeLog)
      ..sort((a, b) => b.compareTo(a));
    _entriesByDay = <DateTime, List<DateTime>>{};
    for (final entry in _sortedLogs) {
      final dayKey = _dateOnly(entry);
      final bucket = _entriesByDay.putIfAbsent(dayKey, () => <DateTime>[]);
      bucket.add(entry);
    }
    for (final bucket in _entriesByDay.values) {
      bucket.sort((a, b) => b.compareTo(a));
    }
    final today = _dateOnly(DateTime.now());
    if (_entriesByDay.containsKey(today)) {
      _selectedDay = today;
    } else if (_sortedLogs.isNotEmpty) {
      _selectedDay = _dateOnly(_sortedLogs.first);
    } else {
      _selectedDay = today;
    }
    _focusedDay = _selectedDay;
  }

  DateTime _dateOnly(DateTime input) =>
      DateTime(input.year, input.month, input.day);

  List<DateTime> _entriesFor(DateTime day) =>
      _entriesByDay[_dateOnly(day)] ?? <DateTime>[];

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildCalendar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: TableCalendar<DateTime>(
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
          titleTextStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontWeight: FontWeight.w600,
              ),
          leftChevronIcon: Icon(Icons.chevron_left, color: scheme.onSurface),
          rightChevronIcon: Icon(Icons.chevron_right, color: scheme.onSurface),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
          weekendStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          isTodayHighlighted: true,
          todayDecoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.45),
            ),
          ),
          selectedDecoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary.withValues(alpha: 0.18),
          ),
          defaultTextStyle: Theme.of(context).textTheme.bodySmall!,
          weekendTextStyle: Theme.of(context).textTheme.bodySmall!,
          todayTextStyle: Theme.of(context).textTheme.bodySmall!,
          selectedTextStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w600,
              ),
          markerDecoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary.withValues(alpha: 0.55),
          ),
          markersMaxCount: 1,
          markersAlignment: Alignment.bottomCenter,
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return const SizedBox.shrink();
            return Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryChips(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final recentDays = <DateTime>{
      for (var i = 0; i < 7; i++) _dateOnly(now.subtract(Duration(days: i)))
    };
    final recordedDays =
        recentDays.where((day) => _entriesByDay.containsKey(day)).length;
    final lastCheckIn = _sortedLogs.isNotEmpty ? _sortedLogs.first : null;

    Widget chip({required String label, required String value}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      )),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        );

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        chip(label: 'Last 7 days', value: '$recordedDays/7 recorded'),
        chip(
          label: 'Last check-in',
          value: lastCheckIn == null ? '—' : formatDateTime(lastCheckIn),
        ),
      ],
    );
  }

  Widget _buildEntriesList(BuildContext context) {
    final entries = _entriesFor(_selectedDay);
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.6)),
              const SizedBox(height: 10),
              Text(
                'No check-ins for this day',
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Check in from the Rx card.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      itemCount: entries.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              formatDate(_selectedDay),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                  ),
            ),
          );
        }
        final entry = entries[index - 1];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  size: 18,
                  color: scheme.primary.withValues(alpha: 0.6)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatTime(entry),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Checked in · ${widget.medication.dose}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                scheme.onSurfaceVariant.withValues(alpha: 0.75),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.medication.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.medication.dose,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 16),
            _buildCalendar(context),
            const SizedBox(height: 12),
            _buildSummaryChips(context),
            const SizedBox(height: 12),
            Expanded(child: _buildEntriesList(context)),
          ],
        ),
      ),
    );
  }
}
