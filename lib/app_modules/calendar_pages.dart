// ignore_for_file: use_build_context_synchronously

part of 'package:patient_tracker/app_modules.dart';

class ScheduleItemDetailsPage extends StatelessWidget {
  const ScheduleItemDetailsPage({super.key, required this.item});
  final ScheduleItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    Widget infoRow(IconData icon, String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
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
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
          title: const Text('Event Details'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Glass(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.title,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          infoRow(Icons.schedule_outlined, 'When', formatDateTime(item.date)),
          infoRow(Icons.category_outlined, 'Type', item.kind.label()),
          if (item.location != null && item.location!.isNotEmpty)
            infoRow(Icons.place_outlined, 'Location', item.location!),
        ])),
        if ((item.doctor != null && item.doctor!.isNotEmpty) ||
            item.attendees.isNotEmpty) ...[
          const SizedBox(height: 12),
          Glass(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('People',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (item.doctor != null && item.doctor!.isNotEmpty)
                infoRow(Icons.person_outline, 'Lead', item.doctor!),
              if (item.attendees.isNotEmpty) ...[
                Text('Attendees',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: item.attendees
                      .map(
                        (name) => Chip(
                          label: Text(name),
                          backgroundColor: cs.secondaryContainer
                              .withValues(alpha: isDark ? 0.45 : 0.6),
                          labelStyle: theme.textTheme.labelLarge?.copyWith(
                            color: cs.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ]),
          ),
        ],
        if (item.notes != null && item.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Glass(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Notes & preparation',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(item.notes!, style: theme.textTheme.bodyMedium),
            ]),
          ),
        ],
        if (item.link != null && item.link!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Glass(
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.link),
                label: const Text('Open related link'),
                onPressed: () async {
                  final url = Uri.parse(item.link!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    showToast(context, 'Could not open link');
                  }
                },
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.items, required this.onAdd});
  final List<ScheduleItem> items;
  final void Function(ScheduleItem) onAdd;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  List<DateTime> get _visibleDays {
    final firstOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month);
    final startOffset = firstOfMonth.weekday % 7;
    final firstVisible = firstOfMonth.subtract(Duration(days: startOffset));
    return List<DateTime>.generate(
        42, (i) => firstVisible.add(Duration(days: i)));
  }

  List<ScheduleItem> _eventsForDay(DateTime day) {
    return widget.items
        .where((it) =>
            it.date.year == day.year &&
            it.date.month == day.month &&
            it.date.day == day.day)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isToday(DateTime day) => _isSameDay(day, DateTime.now());

  bool _isSelected(DateTime day) =>
      _selectedDay != null && _isSameDay(day, _selectedDay!);

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      if (day.month != _focusedMonth.month || day.year != _focusedMonth.year) {
        _focusedMonth = DateTime(day.year, day.month);
      }
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
  }

  Future<void> _addEvent() async {
    final r = await _addScheduleDialog(context);
    if (r != null) {
      widget.onAdd(r);
      setState(() {});
    }
  }

  String _monthLabel(DateTime month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  String _timeLabel(DateTime d) {
    if (d.hour == 0 && d.minute == 0) return 'All day';
    return formatTime(d);
  }

  @override
  Widget build(BuildContext context) {
    final days = _visibleDays;
    final selectedEvents =
        _selectedDay == null ? <ScheduleItem>[] : _eventsForDay(_selectedDay!);
    const weekLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Glass(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Previous month',
                          onPressed: () => _changeMonth(-1),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              _monthLabel(_focusedMonth),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Next month',
                          onPressed: () => _changeMonth(1),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: weekLabels
                          .map(
                            (label) => Expanded(
                              child: Center(
                                child: Text(
                                  label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 280,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: days.length,
                        itemBuilder: (context, index) {
                          final day = days[index];
                          final isCurrentMonth =
                              day.month == _focusedMonth.month &&
                                  day.year == _focusedMonth.year;
                          final isSelected = _isSelected(day);
                          final isToday = _isToday(day);
                          final hasEvents = _eventsForDay(day).isNotEmpty;
                          final textColor = isCurrentMonth
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.45);

                          return GestureDetector(
                            onTap: () => _selectDay(day),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.18)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: isToday
                                    ? Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        width: isSelected ? 2 : 1.4,
                                      )
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${day.day}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: textColor,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (hasEvents)
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Glass(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDay == null
                            ? 'Calendar'
                            : 'Calendar · ${formatDate(_selectedDay!)}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      if (selectedEvents.isEmpty)
                        const Expanded(
                          child: Center(child: Text('No plans for this day.')),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: selectedEvents.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final it = selectedEvents[i];
                              return InkWell(
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) =>
                                        ScheduleItemDetailsPage(item: it),
                                  ));
                                },
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(it.kind.icon(), size: 22),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            it.title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${it.kind.label()} • ${_timeLabel(it.date)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium,
                                          ),
                                          if (it.notes != null &&
                                              it.notes!.isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Text(it.notes!),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<ScheduleItem?> _addScheduleDialog(BuildContext context) async {
  final title = TextEditingController();
  final notes = TextEditingController();
  final location = TextEditingController();
  final doctor = TextEditingController();
  final link = TextEditingController();
  final attendees = TextEditingController();
  DateTime date = DateTime.now().add(const Duration(days: 1));
  ScheduleKind kind = ScheduleKind.other;

  return fadeDialog<ScheduleItem>(
    context,
    StatefulBuilder(builder: (context, setSt) {
      return AlertDialog(
        title: const Text('Add schedule'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ScheduleKind>(
                value: kind,
                items: ScheduleKind.values
                    .map((k) =>
                        DropdownMenuItem(value: k, child: Text(k.label())))
                    .toList(),
                onChanged: (v) => setSt(() => kind = v ?? ScheduleKind.other),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text('Date: ${formatDate(date)}')),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDate: date,
                      );
                      if (picked != null) setSt(() => date = picked);
                    },
                    child: const Text('Pick date'),
                  ),
                ],
              ),
              TextField(
                  controller: notes,
                  decoration:
                      const InputDecoration(labelText: 'Notes / instructions'),
                  maxLines: 2),
              const SizedBox(height: 8),
              TextField(
                controller: location,
                decoration: const InputDecoration(
                  labelText: 'Location / place',
                  hintText: 'Building, room, telehealth link, etc.',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: doctor,
                decoration: const InputDecoration(
                  labelText: 'Lead / clinician',
                  hintText: 'e.g. Dr. Wang',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: attendees,
                decoration: const InputDecoration(
                  labelText: 'Attendees',
                  hintText: 'Comma separated names',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: link,
                decoration: const InputDecoration(
                  labelText: 'Link',
                  hintText: 'https://',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (title.text.trim().isEmpty) return;
              final trimmedNotes = notes.text.trim();
              final trimmedLocation = location.text.trim();
              final trimmedDoctor = doctor.text.trim();
              final trimmedLink = link.text.trim();
              Navigator.pop(
                  context,
                  ScheduleItem(
                      title: title.text.trim(),
                      date: date,
                      notes: trimmedNotes.isEmpty ? null : trimmedNotes,
                      kind: kind,
                      location:
                          trimmedLocation.isEmpty ? null : trimmedLocation,
                      doctor: trimmedDoctor.isEmpty ? null : trimmedDoctor,
                      link: trimmedLink.isEmpty ? null : trimmedLink,
                      attendees: attendees.text
                          .split(',')
                          .map((s) => s.trim())
                          .where((s) => s.isNotEmpty)
                          .toList()));
            },
            child: const Text('Save'),
          ),
        ],
      );
    }),
  );
}

/// ===================== More & Settings =====================
