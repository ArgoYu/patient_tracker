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
  static const double _kBottomActionBarHeight = 72;
  final Map<int, TimeOfDay> _reminderTimes = {};
  final Map<int, Timer> _timers = {};
  final Map<int, DateTime> _scheduledFire = {};

  final JournalRepository _journalRepository = JournalRepository();
  List<JournalEntry> _journalEntries = <JournalEntry>[];
  late final String _journalAccountId;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _journalAccountId = _currentAccountId();
    _loadJournalEntries();
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    super.dispose();
  }


  String _currentAccountId() {
    final account = AuthService.instance.currentUserAccountListenable.value;
    return account?.id ?? 'guest';
  }

  Future<void> _loadJournalEntries() async {
    final entries = await _journalRepository.loadEntries(_journalAccountId);
    if (!mounted) return;
    setState(() {
      _journalEntries = entries;
    });
  }

  Future<void> _saveJournalEntries() async {
    await _journalRepository.saveEntries(_journalAccountId, _journalEntries);
  }

  Future<void> _saveJournalEntry(JournalEntry entry) async {
    final updated = List<JournalEntry>.from(_journalEntries);
    final index = updated.indexWhere((item) => item.id == entry.id);
    if (index == -1) {
      updated.insert(0, entry);
    } else {
      updated[index] = entry;
    }
    updated.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (!mounted) return;
    setState(() {
      _journalEntries = updated;
    });
    await _saveJournalEntries();
    if (!mounted) return;
    showToast(context, 'Saved to journal ?');
  }

  Future<void> _openJournalEntrySheet(RxMedication med) async {
    final entry = await showJournalEntrySheet(
      context,
      medication: med,
    );
    if (entry == null) return;
    await _saveJournalEntry(entry);
  }

  Future<void> _openJournalHistory(RxMedication med) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JournalEntriesPage(
          medication: med,
          entries: _journalEntries,
          onEntriesChanged: (entries) async {
            _journalEntries = List<JournalEntry>.from(entries)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            await _saveJournalEntries();
            if (!mounted) return;
            setState(() {});
          },
        ),
      ),
    );
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

  Future<void> _checkInMeds(List<int> indices) async {
    if (indices.isEmpty) return;
    final now = DateTime.now();
    for (final index in indices) {
      widget.onCheckIn(index, now);
    }
    if (!mounted) return;
    setState(() {});
    final names = indices.map((i) => widget.meds[i].name).join(', ');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Checked in: $names')),
    );
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

  String _medSubtitle(RxMedication med) {
    if (med.intakeLog.isEmpty) return med.dose;
    final last = List<DateTime>.from(med.intakeLog)
      ..sort((a, b) => b.compareTo(a));
    return 'Last taken ${formatTime(last.first)}';
  }

  void _showMedMultiSelectSheet({
    required String title,
    required String subtitle,
    required List<RxMedication> meds,
    required void Function(List<int> selectedIndices) onConfirm,
  }) {
    final selected = <int>{};
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final canConfirm = selected.isNotEmpty;
            return SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF121417),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withOpacity(0.92),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(Icons.close,
                              color: Colors.white.withOpacity(0.75)),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        subtitle,
                        style: TextStyle(color: Colors.white.withOpacity(0.65)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (meds.length > 1)
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                selected
                                  ..clear()
                                  ..addAll(List.generate(meds.length, (i) => i));
                              });
                            },
                            child: const Text('Select all'),
                          ),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: () {
                              setModalState(selected.clear);
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: meds.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: Colors.white.withOpacity(0.06)),
                        itemBuilder: (_, i) {
                          final med = meds[i];
                          final isChecked = selected.contains(i);
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setModalState(() {
                                if (isChecked) {
                                  selected.remove(i);
                                } else {
                                  selected.add(i);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isChecked,
                                    onChanged: (_) {
                                      setModalState(() {
                                        if (isChecked) {
                                          selected.remove(i);
                                        } else {
                                          selected.add(i);
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          med.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color:
                                                Colors.white.withOpacity(0.90),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _medSubtitle(med),
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.62),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: canConfirm
                                ? () {
                                    final selectedIndices = selected.toList()
                                      ..sort();
                                    Navigator.pop(ctx);
                                    onConfirm(selectedIndices);
                                  }
                                : null,
                            child: const Text('Confirm'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openMultiMedCheckInSheet() {
    if (widget.meds.isEmpty) return;
    _showMedMultiSelectSheet(
      title: 'Check in',
      subtitle: 'Select medications',
      meds: widget.meds,
      onConfirm: _checkInMeds,
    );
  }

  void _openJournalMultiSelectSheet() {
    if (widget.meds.isEmpty) return;
    _showMedMultiSelectSheet(
      title: 'Journal',
      subtitle: 'Select medications',
      meds: widget.meds,
      onConfirm: (selectedIndices) {
        final selectedMeds =
            selectedIndices.map((index) => widget.meds[index]).toList();
        _openJournalForMeds(selectedMeds);
      },
    );
  }

  Future<void> _openJournalForMeds(List<RxMedication> meds) async {
    if (meds.isEmpty) return;
    if (meds.length == 1) {
      await _openJournalEntrySheet(meds.first);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _MultiMedJournalComposerPage(meds: meds),
      ),
    );
  }

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

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          ListView.separated(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              24 + _kBottomActionBarHeight + 16 + bottomInset,
            ),
            itemCount: widget.meds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final med = widget.meds[index];
              final logs = List<DateTime>.from(med.intakeLog)
                ..sort((a, b) => b.compareTo(a));
              final reminder = _reminderTimes[index];
              final scheduled = _scheduledFire[index];
              final statusText = _statusText(logs);
              final isExpanded = _expandedIndex == index;
              return RxMedExpandableCard(
                med: med,
                isExpanded: isExpanded,
                statusText: statusText,
                statusIcon: _statusIcon(logs),
                statusColor: _statusColor(context, logs),
                reminder: reminder,
                scheduled: scheduled,
                secondaryTextStyle: _secondaryText(context),
                onToggle: () {
                  setState(() {
                    _expandedIndex = isExpanded ? null : index;
                  });
                },
                onReminderTap: () => reminder == null
                    ? _pickReminder(index)
                    : _cancelReminder(index),
                onTimelineTap: () {
                  final checkIns = med.intakeLog
                      .map((entry) =>
                          RxCheckIn(timestamp: entry, medicationId: med.name))
                      .toList();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MedicationTimelineScreen(
                        medicationId: med.name,
                        medicationDisplayName: med.name,
                        checkIns: checkIns,
                      ),
                    ),
                  );
                },
                onJournalHistoryTap: () => _openJournalHistory(med),
              );
            },
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: _RxBottomActionBar(
                height: _kBottomActionBarHeight,
                onCheckIn: _openMultiMedCheckInSheet,
                onJournal: _openJournalMultiSelectSheet,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RxMedExpandableCard extends StatelessWidget {
  const RxMedExpandableCard({
    super.key,
    required this.med,
    required this.isExpanded,
    required this.statusText,
    required this.statusIcon,
    required this.statusColor,
    required this.reminder,
    required this.scheduled,
    required this.secondaryTextStyle,
    required this.onToggle,
    required this.onReminderTap,
    required this.onTimelineTap,
    required this.onJournalHistoryTap,
  });

  final RxMedication med;
  final bool isExpanded;
  final String statusText;
  final IconData statusIcon;
  final Color statusColor;
  final TimeOfDay? reminder;
  final DateTime? scheduled;
  final TextStyle? secondaryTextStyle;
  final VoidCallback onToggle;
  final VoidCallback onReminderTap;
  final VoidCallback onTimelineTap;
  final VoidCallback onJournalHistoryTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Glass(
      radius: 22,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(statusIcon, size: 16, color: statusColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '$statusText бд ${med.dose}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.78),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Divider(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                height: 16,
              ),
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: onReminderTap,
                            icon: Icon(
                              reminder == null ? Icons.timer : Icons.close,
                            ),
                            label: Text(
                              reminder == null
                                  ? 'Set reminder'
                                  : 'Cancel reminder',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.2),
                              ),
                              foregroundColor: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (reminder != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            scheduled == null
                                ? 'Reminder active at ${reminder!.format(context)} daily.'
                                : 'Reminder set for ${formatTime(scheduled!)} (daily).',
                            style: secondaryTextStyle,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _RxMedExpandedBody(
                          med: med,
                          onTimelineTap: onTimelineTap,
                          onJournalHistoryTap: onJournalHistoryTap,
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _RxBottomActionBar extends StatelessWidget {
  const _RxBottomActionBar({
    required this.height,
    required this.onCheckIn,
    required this.onJournal,
  });

  final double height;
  final VoidCallback onCheckIn;
  final VoidCallback onJournal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: onCheckIn,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: const StadiumBorder(),
                backgroundColor: scheme.primary.withValues(alpha: 0.2),
                foregroundColor: scheme.onSurface,
              ),
              child: const Text('Check in'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: onJournal,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: const StadiumBorder(),
                side: BorderSide(
                  color: scheme.onSurface.withValues(alpha: 0.2),
                ),
                foregroundColor: scheme.onSurface,
              ),
              child: const Text('Journal'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RxMedExpandedBody extends StatelessWidget {
  const _RxMedExpandedBody({
    required this.med,
    required this.onTimelineTap,
    required this.onJournalHistoryTap,
  });

  final RxMedication med;
  final VoidCallback onTimelineTap;
  final VoidCallback onJournalHistoryTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtleText = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text('Why you take this', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(
          med.effect,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.info_outline,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Text(
              'Possible side effects',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(med.sideEffects, style: subtleText),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onTimelineTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 6),
            foregroundColor: theme.colorScheme.onSurfaceVariant,
            minimumSize: const Size(0, 36),
            alignment: Alignment.centerLeft,
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month_outlined,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.75)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Timeline',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.9),
                  ),
                ),
              ),
              Text(
                'View history',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: onJournalHistoryTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 6),
            foregroundColor: theme.colorScheme.onSurfaceVariant,
            minimumSize: const Size(0, 36),
            alignment: Alignment.centerLeft,
          ),
          child: Row(
            children: [
              Icon(Icons.menu_book_outlined,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.75)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Journal',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.9),
                  ),
                ),
              ),
              Text(
                'View journal',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MultiMedJournalComposerPage extends StatefulWidget {
  const _MultiMedJournalComposerPage({required this.meds});

  final List<RxMedication> meds;

  @override
  State<_MultiMedJournalComposerPage> createState() =>
      _MultiMedJournalComposerPageState();
}

class _MultiMedJournalComposerPageState
    extends State<_MultiMedJournalComposerPage> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveDraft() {
    final names = widget.meds.map((med) => med.name).join(', ');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Journal entry saved for: $names')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Journal Entry'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Medications',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.meds
                    .map(
                      (med) => Chip(
                        label: Text(med.name),
                        backgroundColor:
                            scheme.primary.withValues(alpha: 0.12),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Entry',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Write your journal entry...',
                  border: OutlineInputBorder(),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveDraft,
                  child: const Text('Save entry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

