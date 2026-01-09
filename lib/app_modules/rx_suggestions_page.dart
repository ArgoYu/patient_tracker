part of 'package:patient_tracker/app_modules.dart';

class RxSuggestionsPage extends StatefulWidget {
  const RxSuggestionsPage(
      {super.key, required this.meds, required this.onCheckIn});

  final List<RxMedication> meds;
  final void Function(int index, DateTime when) onCheckIn;

  @override
  State<RxSuggestionsPage> createState() => _RxSuggestionsPageState();
}

class _RxSuggestionsPageState extends State<RxSuggestionsPage> {
  final Map<int, TimeOfDay> _reminderTimes = {};
  final Map<int, Timer> _timers = {};
  final Map<int, DateTime> _scheduledFire = {};

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    super.dispose();
  }

  Future<void> _checkIn(int index) async {
    final now = DateTime.now();
    widget.onCheckIn(index, now);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Logged ${widget.meds[index].name} at ${formatTime(now)}')),
    );
    setState(() {});
  }

  Future<void> _pickReminder(int index) async {
    final current = _reminderTimes[index] ?? TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null) return;
    _reminderTimes[index] = picked;
    _scheduleDailyReminder(index);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Reminder set for ${widget.meds[index].name} at ${picked.format(context)}')),
    );
  }

  void _fireReminder(int index) {
    if (!mounted) return;
    final med = widget.meds[index];
    _timers.remove(index);
    _scheduledFire.remove(index);
    _scheduleDailyReminder(index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Medication Reminder'),
          content: Text('Time to take ${med.name}.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Dismiss'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _checkIn(index);
              },
              child: const Text('Check in now'),
            ),
          ],
        ),
      );
    });
    setState(() {});
  }

  void _cancelReminder(int index) {
    _timers[index]?.cancel();
    _timers.remove(index);
    _reminderTimes.remove(index);
    _scheduledFire.remove(index);
    setState(() {});
  }

  void _scheduleDailyReminder(int index) {
    final reminder = _reminderTimes[index];
    if (reminder == null) return;
    final now = DateTime.now();
    var target =
        DateTime(now.year, now.month, now.day, reminder.hour, reminder.minute);
    if (!target.isAfter(now)) {
      target = target.add(const Duration(days: 1));
    }
    _timers[index]?.cancel();
    _scheduledFire[index] = target;
    _timers[index] = Timer(target.difference(now), () => _fireReminder(index));
  }

  AppBar _buildAppBar() => AppBar(
        title: const Text('Rx Suggestions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      );

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _statusText(List<DateTime> logs) {
    if (logs.isEmpty) return 'Not checked in yet';
    final last = logs.first;
    final now = DateTime.now();
    if (_isSameDay(last, now)) return 'Taken today';
    if (_isSameDay(last, now.subtract(const Duration(days: 1)))) {
      return 'Last taken yesterday';
    }
    return 'Last taken ${formatDate(last)}';
  }

  IconData _statusIcon(List<DateTime> logs) {
    if (logs.isEmpty) return Icons.radio_button_unchecked;
    final last = logs.first;
    final now = DateTime.now();
    if (_isSameDay(last, now)) return Icons.check_circle_rounded;
    return Icons.history_rounded;
  }

  Color _statusColor(BuildContext context, List<DateTime> logs) {
    final scheme = Theme.of(context).colorScheme;
    if (logs.isEmpty) return scheme.onSurface.withValues(alpha: 0.45);
    final last = logs.first;
    if (_isSameDay(last, DateTime.now())) {
      return scheme.primary.withValues(alpha: 0.75);
    }
    return scheme.onSurface.withValues(alpha: 0.6);
  }

  TextStyle? _secondaryText(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
          );

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medication_outlined,
                size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'No medication suggestions yet.',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Once your care team assigns a prescription or you add one manually, it will show up here with suggested check-ins and reminders.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.meds.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: _buildEmptyState(context),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: widget.meds.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final med = widget.meds[index];
          final logs = List<DateTime>.from(med.intakeLog)
            ..sort((a, b) => b.compareTo(a));
          final reminder = _reminderTimes[index];
          final scheduled = _scheduledFire[index];
          final statusText = _statusText(logs);
          return Glass(
            radius: 22,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(_statusIcon(logs),
                        size: 16, color: _statusColor(context, logs)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$statusText · ${med.dose}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.78),
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _checkIn(index),
                        icon: const Icon(Icons.check),
                        label: const Text('Check in'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.18),
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => reminder == null
                            ? _pickReminder(index)
                            : _cancelReminder(index),
                        icon: Icon(
                          reminder == null ? Icons.timer : Icons.close,
                        ),
                        label: Text(
                          reminder == null ? 'Set reminder' : 'Cancel reminder',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.2),
                          ),
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                if (reminder != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    scheduled == null
                        ? 'Reminder active at ${reminder.format(context)} daily.'
                        : 'Reminder set for ${formatTime(scheduled)} (daily).',
                    style: _secondaryText(context),
                  ),
                ],
                const SizedBox(height: 16),
                Text('Why you take this',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(med.effect, style: _secondaryText(context)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5)),
                    const SizedBox(width: 6),
                    Text('Possible side effects',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            )),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  med.sideEffects,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: 14),
                Text('Timeline', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                if (logs.isEmpty)
                  Text('No check-ins yet', style: _secondaryText(context))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: logs
                        .map(
                          (d) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              formatDateTime(d),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
