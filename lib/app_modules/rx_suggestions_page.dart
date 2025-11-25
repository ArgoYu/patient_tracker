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
        padding: const EdgeInsets.all(16),
        itemCount: widget.meds.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final med = widget.meds[index];
          final logs = List<DateTime>.from(med.intakeLog)
            ..sort((a, b) => b.compareTo(a));
          final reminder = _reminderTimes[index];
          final scheduled = _scheduledFire[index];
          return Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.medication_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        med.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(med.dose, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                _InfoRow(
                    icon: Icons.healing,
                    label: 'Therapeutic effect',
                    value: med.effect),
                const SizedBox(height: 6),
                _InfoRow(
                    icon: Icons.warning_amber_rounded,
                    label: 'Possible side effects',
                    value: med.sideEffects),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () => _checkIn(index),
                      icon: const Icon(Icons.check),
                      label: const Text('Check in'),
                    ),
                    const SizedBox(width: 12),
                    if (reminder == null)
                      OutlinedButton.icon(
                        onPressed: () => _pickReminder(index),
                        icon: const Icon(Icons.timer),
                        label: const Text('Set reminder'),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () => _cancelReminder(index),
                        icon: const Icon(Icons.close),
                        label: const Text('Cancel reminder'),
                      ),
                  ],
                ),
                if (reminder != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    scheduled == null
                        ? 'Reminder active at ${reminder.format(context)} daily.'
                        : 'Reminder set for ${formatTime(scheduled)} (daily).',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                Text('Timeline', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                if (logs.isEmpty)
                  const Text('No doses logged yet.')
                else
                  Column(
                    children: logs
                        .map(
                          (d) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.check_circle_outline,
                                size: 20),
                            title: Text(formatDateTime(d)),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 2),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }
}
