part of 'package:patient_tracker/app_modules.dart';

class RxSuggestionsPage extends StatefulWidget {
  const RxSuggestionsPage(
      {super.key, required this.meds, required this.onCheckIn});

  final List<RxMedication> meds;
  final void Function(int index, DateTime when, MedTimeSlot? slot) onCheckIn;

  @override
  State<RxSuggestionsPage> createState() => _RxSuggestionsPageState();
}

class _RxSuggestionsPageState extends State<RxSuggestionsPage> {
  final Map<int, TimeOfDay> _reminderTimes = {};
  final Map<int, Timer> _timers = {};
  final Map<int, DateTime> _scheduledFire = {};
  final Set<int> _selectedMedIndices = <int>{};
  final Map<int, MedTimeSlot?> _pendingCheckInSlots = <int, MedTimeSlot?>{};

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

  Future<void> _openJournalHistoryAllMeds() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RxJournalPage(
          scope: RxScope.allMeds,
          meds: widget.meds,
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

  void _openHistoryAllMeds() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RxHistoryPage(
          scope: RxScope.allMeds,
          meds: widget.meds,
        ),
      ),
    );
  }

  Future<void> _checkIn(int index, {MedTimeSlot? slot}) async {
    final now = DateTime.now();
    widget.onCheckIn(index, now, slot);
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
      final slot = _pendingCheckInSlots[index] ?? _nextRemainingSlotForMed(index);
      widget.onCheckIn(index, now, slot);
    }
    if (!mounted) return;
    _selectedMedIndices
      ..clear()
      ..addAll(indices);
    _pendingCheckInSlots.clear();
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
                    _checkIn(index, slot: _nextRemainingSlotForMed(index));
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

  String _statusText(List<DateTime> logs) {
    if (logs.isEmpty) return 'Not checked in yet';
    final last = logs.first;
    final now = DateTime.now();
    if (isSameDay(last, now)) return 'Taken today';
    if (isSameDay(last, now.subtract(const Duration(days: 1)))) {
      return 'Last taken yesterday';
    }
    return 'Last taken ${formatDate(last)}';
  }

  _MedDoseProgress _doseProgressForMed(RxMedication med) {
    final now = DateTime.now();
    if (med.timesOfDay.isEmpty) {
      final takenToday = med.intakeLogs.any(
        (log) =>
            log.status == MedIntakeStatus.taken &&
            isSameDay(log.takenAt, now),
      );
      return _MedDoseProgress(totalDue: 1, takenCount: takenToday ? 1 : 0);
    }

    final dueSlots = List<MedTimeSlot>.from(med.timesOfDay)
      ..sort((a, b) => a.order.compareTo(b.order));
    final takenSlots = <MedTimeSlot>{};
    var unassigned = 0;
    for (final log in med.intakeLogs) {
      if (log.status != MedIntakeStatus.taken) continue;
      if (!isSameDay(log.takenAt, now)) continue;
      if (log.slot == null) {
        unassigned += 1;
      } else if (dueSlots.contains(log.slot)) {
        takenSlots.add(log.slot!);
      }
    }

    if (unassigned > 0) {
      final remaining = dueSlots
          .where((slot) => !takenSlots.contains(slot))
          .toList();
      for (var i = 0; i < unassigned && i < remaining.length; i++) {
        takenSlots.add(remaining[i]);
      }
    }

    return _MedDoseProgress(
      totalDue: dueSlots.length,
      takenCount: takenSlots.length,
    );
  }

  void _clearTodayLogs(int medIndex) {
    final med = widget.meds[medIndex];
    final now = DateTime.now();
    med.intakeLog.removeWhere((entry) => isSameDay(entry, now));
    med.intakeLogs.removeWhere(
      (entry) =>
          entry.status == MedIntakeStatus.taken &&
          isSameDay(entry.takenAt, now),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed today\'s log for ${med.name}')),
    );
    setState(() {});
  }

  void _toggleQuickCheckIn(int medIndex, _MedDoseProgress progress) {
    if (progress.isComplete) {
      _clearTodayLogs(medIndex);
      return;
    }
    _checkIn(medIndex, slot: _nextRemainingSlotForMed(medIndex));
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
    Set<int> initialSelectedIndices = const <int>{},
    required void Function(List<int> selectedIndices) onConfirm,
  }) {
    final selected = <int>{}..addAll(initialSelectedIndices);
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
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08)),
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
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(Icons.close,
                              color: Colors.white.withValues(alpha: 0.75)),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        subtitle,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65)),
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
                            Divider(
                                color: Colors.white.withValues(alpha: 0.06)),
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
                                            Colors.white.withValues(alpha: 0.90),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _medSubtitle(med),
                                          style: TextStyle(
                                            color:
                                            Colors.white.withValues(alpha: 0.62),
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

  void _openMultiMedCheckInSheet({bool keepPendingSlots = false}) {
    if (widget.meds.isEmpty) return;
    if (!keepPendingSlots) {
      _pendingCheckInSlots.clear();
    }
    _showMedMultiSelectSheet(
      title: 'Check in',
      subtitle: 'Select medications',
      meds: widget.meds,
      initialSelectedIndices: _selectedMedIndices,
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

  String _doseKey(String medId, MedTimeSlot slot) => '$medId-${slot.name}';

  _SummaryData _buildSummaryData() {
    final now = DateTime.now();
    final due = <_DueDose>[];
    for (var i = 0; i < widget.meds.length; i++) {
      final med = widget.meds[i];
      if (!med.isActive || med.timesOfDay.isEmpty) continue;
      for (final slot in med.timesOfDay) {
        due.add(_DueDose(
          medId: med.id,
          medIndex: i,
          medName: med.name,
          slot: slot,
        ));
      }
    }

    due.sort((a, b) {
      final order = a.slot.order.compareTo(b.slot.order);
      if (order != 0) return order;
      return a.medName.compareTo(b.medName);
    });

    final taken = <String>{};
    final unassignedCounts = <String, int>{};
    for (final med in widget.meds) {
      for (final log in med.intakeLogs) {
        if (log.status != MedIntakeStatus.taken) continue;
        if (!isSameDay(log.takenAt, now)) continue;
        if (log.slot == null) {
          unassignedCounts[med.id] = (unassignedCounts[med.id] ?? 0) + 1;
          continue;
        }
        taken.add(_doseKey(med.id, log.slot!));
      }
    }

    if (unassignedCounts.isNotEmpty) {
      for (final entry in unassignedCounts.entries) {
        final available = due
            .where((dose) =>
                dose.medId == entry.key &&
                !taken.contains(_doseKey(dose.medId, dose.slot)))
            .toList()
          ..sort((a, b) => a.slot.order.compareTo(b.slot.order));
        for (var i = 0; i < entry.value && i < available.length; i++) {
          final dose = available[i];
          taken.add(_doseKey(dose.medId, dose.slot));
        }
      }
    }

    final remaining = due
        .where((dose) => !taken.contains(_doseKey(dose.medId, dose.slot)))
        .toList();
    final totalDue = due.length;
    final takenCount = math.min(totalDue, taken.length);
    final remainingCount = remaining.length;

    remaining.sort((a, b) {
      final order = a.slot.order.compareTo(b.slot.order);
      if (order != 0) return order;
      return a.medName.compareTo(b.medName);
    });

    final preview = remaining
        .take(3)
        .map((dose) => RemainingPreviewItem(
              medName: dose.medName,
              slotLabel: dose.slot.label,
            ))
        .toList();

    final nextSlotByMed = <int, MedTimeSlot?>{};
    for (final dose in remaining) {
      nextSlotByMed.putIfAbsent(dose.medIndex, () => dose.slot);
    }

    return _SummaryData(
      vm: SummaryVM(
        totalDue: totalDue,
        takenCount: takenCount,
        remainingCount: remainingCount,
        preview: preview,
        moreCount: remainingCount > 3 ? remainingCount - 3 : 0,
        statusTitle: takenCount > 0 ? "You're on track" : "Let's get started",
        nextUpLabel:
            remaining.isEmpty ? null : 'Next up: ${remaining.first.slot.label}',
      ),
      remainingDoses: remaining,
      remainingMedIndices: remaining.map((dose) => dose.medIndex).toSet(),
      nextSlotByMed: nextSlotByMed,
    );
  }

  MedTimeSlot? _nextRemainingSlotForMed(int medIndex) {
    final summary = _buildSummaryData();
    return summary.nextSlotByMed[medIndex];
  }

  void _handleSummaryCheckIn(_SummaryData summary) {
    if (summary.remainingMedIndices.isEmpty) {
      showToast(context, 'No remaining doses to check in.');
      return;
    }
    _selectedMedIndices
      ..clear()
      ..addAll(summary.remainingMedIndices);
    _pendingCheckInSlots
      ..clear()
      ..addAll(summary.nextSlotByMed);
    _openMultiMedCheckInSheet(keepPendingSlots: true);
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
    final summary = _buildSummaryData();

    return Scaffold(
      appBar: _buildAppBar(),
      body: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24 + bottomInset,
        ),
        itemCount: widget.meds.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            return DailyMedSummaryCard(
              vm: summary.vm,
              onCheckIn: () => _handleSummaryCheckIn(summary),
              onJournal: _openJournalMultiSelectSheet,
              onOpenHistory: _openHistoryAllMeds,
              onOpenJournal: _openJournalHistoryAllMeds,
            );
          }
          final medIndex = index - 1;
          final med = widget.meds[medIndex];
          final logs = List<DateTime>.from(med.intakeLog)
            ..sort((a, b) => b.compareTo(a));
          final reminder = _reminderTimes[medIndex];
          final scheduled = _scheduledFire[medIndex];
          final statusText = _statusText(logs);
          final isExpanded = _expandedIndex == medIndex;
          final doseProgress = _doseProgressForMed(med);
          return RxMedExpandableCard(
            med: med,
            isExpanded: isExpanded,
            isChecked: doseProgress.isComplete,
            isPartial: doseProgress.isPartial,
            partialLabel: doseProgress.label,
            statusText: statusText,
            reminder: reminder,
            scheduled: scheduled,
            secondaryTextStyle: _secondaryText(context),
            onToggle: () {
              setState(() {
                _expandedIndex = isExpanded ? null : medIndex;
              });
            },
            onCheckboxTap: () => _toggleQuickCheckIn(medIndex, doseProgress),
            onReminderTap: () => reminder == null
                ? _pickReminder(medIndex)
                : _cancelReminder(medIndex),
          );
        },
      ),
    );
  }
}

class RxMedExpandableCard extends StatelessWidget {
  const RxMedExpandableCard({
    super.key,
    required this.med,
    required this.isExpanded,
    required this.isChecked,
    required this.isPartial,
    required this.partialLabel,
    required this.statusText,
    required this.reminder,
    required this.scheduled,
    required this.secondaryTextStyle,
    required this.onToggle,
    required this.onCheckboxTap,
    required this.onReminderTap,
  });

  final RxMedication med;
  final bool isExpanded;
  final bool isChecked;
  final bool isPartial;
  final String? partialLabel;
  final String statusText;
  final TimeOfDay? reminder;
  final DateTime? scheduled;
  final TextStyle? secondaryTextStyle;
  final VoidCallback onToggle;
  final VoidCallback onCheckboxTap;
  final VoidCallback onReminderTap;
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MedCompletionCheckbox(
                    isChecked: isChecked,
                    isPartial: isPartial,
                    partialLabel: partialLabel,
                    onTap: onCheckboxTap,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: onToggle,
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
                                Text(
                                  '$statusText бд ${med.dose}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.78),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.75),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

class _MedCompletionCheckbox extends StatelessWidget {
  const _MedCompletionCheckbox({
    required this.isChecked,
    required this.isPartial,
    required this.partialLabel,
    required this.onTap,
  });

  final bool isChecked;
  final bool isPartial;
  final String? partialLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const size = 30.0;
    const radius = 8.0;
    final fillColor = isChecked
        ? scheme.primary
        : isPartial
            ? scheme.primary.withValues(alpha: 0.12)
            : Colors.transparent;
    final borderColor = isChecked
        ? Colors.transparent
        : scheme.onSurface.withValues(alpha: 0.25);

    Widget content = const SizedBox.shrink();
    if (isChecked) {
      content = Icon(
        Icons.check_rounded,
        size: 20,
        color: scheme.onPrimary,
      );
    } else if (isPartial) {
      content = partialLabel == null
          ? Icon(
              Icons.remove_rounded,
              size: 20,
              color: scheme.primary,
            )
          : Text(
              partialLabel!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Center(child: content),
        ),
      ),
    );
  }
}

class _RxMedExpandedBody extends StatelessWidget {
  const _RxMedExpandedBody({
    required this.med,
  });

  final RxMedication med;

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

class _MedDoseProgress {
  const _MedDoseProgress({
    required this.totalDue,
    required this.takenCount,
  });

  final int totalDue;
  final int takenCount;

  bool get isComplete => totalDue == 0 ? takenCount > 0 : takenCount >= totalDue;

  bool get isPartial =>
      totalDue > 1 && takenCount > 0 && takenCount < totalDue;

  String? get label => isPartial ? '$takenCount/$totalDue' : null;
}

class SummaryVM {
  const SummaryVM({
    required this.totalDue,
    required this.takenCount,
    required this.remainingCount,
    required this.preview,
    required this.moreCount,
    required this.statusTitle,
    this.nextUpLabel,
  });

  final int totalDue;
  final int takenCount;
  final int remainingCount;
  final List<RemainingPreviewItem> preview;
  final int moreCount;
  final String statusTitle;
  final String? nextUpLabel;
}

class RemainingPreviewItem {
  const RemainingPreviewItem({required this.medName, required this.slotLabel});

  final String medName;
  final String slotLabel;
}

class _SummaryData {
  const _SummaryData({
    required this.vm,
    required this.remainingDoses,
    required this.remainingMedIndices,
    required this.nextSlotByMed,
  });

  final SummaryVM vm;
  final List<_DueDose> remainingDoses;
  final Set<int> remainingMedIndices;
  final Map<int, MedTimeSlot?> nextSlotByMed;
}

class _DueDose {
  const _DueDose({
    required this.medId,
    required this.medIndex,
    required this.medName,
    required this.slot,
  });

  final String medId;
  final int medIndex;
  final String medName;
  final MedTimeSlot slot;
}

enum RxScope { allMeds }

class RxHistoryPage extends StatelessWidget {
  const RxHistoryPage({
    super.key,
    required this.scope,
    required this.meds,
  });

  final RxScope scope;
  final List<RxMedication> meds;

  @override
  Widget build(BuildContext context) {
    final checkIns = <RxCheckIn>[
      for (final med in meds)
        for (final entry in med.intakeLog)
          RxCheckIn(timestamp: entry, medicationId: med.name),
    ];
    final label = scope == RxScope.allMeds ? 'All medications' : 'Medication';
    return MedicationTimelineScreen(
      medicationId: scope == RxScope.allMeds ? 'all' : 'medication',
      medicationDisplayName: label,
      checkIns: checkIns,
    );
  }
}

class RxJournalPage extends StatelessWidget {
  const RxJournalPage({
    super.key,
    required this.scope,
    required this.meds,
    required this.entries,
    required this.onEntriesChanged,
  });

  final RxScope scope;
  final List<RxMedication> meds;
  final List<JournalEntry> entries;
  final Future<void> Function(List<JournalEntry> entries) onEntriesChanged;

  @override
  Widget build(BuildContext context) {
    final isAll = scope == RxScope.allMeds;
    return JournalEntriesPage(
      medication: isAll ? null : (meds.isNotEmpty ? meds.first : null),
      medications: meds,
      entries: entries,
      onEntriesChanged: onEntriesChanged,
    );
  }
}

class DailyMedSummaryCard extends StatelessWidget {
  const DailyMedSummaryCard({
    super.key,
    required this.vm,
    required this.onCheckIn,
    required this.onJournal,
    required this.onOpenHistory,
    required this.onOpenJournal,
  });

  final SummaryVM vm;
  final VoidCallback onCheckIn;
  final VoidCallback onJournal;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenJournal;

  Color _progressColor(ColorScheme scheme, double p) {
    final clamped = p.clamp(0.0, 1.0);
    final danger = scheme.error;
    final warning = scheme.tertiary;
    final primary = scheme.primary;
    final success = scheme.secondary;
    if (clamped < 0.3) {
      return Color.lerp(danger, warning, clamped / 0.3) ?? warning;
    }
    if (clamped < 0.6) {
      return Color.lerp(warning, primary, (clamped - 0.3) / 0.3) ?? primary;
    }
    return Color.lerp(primary, success, (clamped - 0.6) / 0.4) ?? success;
  }

  Widget _buildMiniAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: const StadiumBorder(),
        side: BorderSide(
          color: scheme.onSurface.withValues(alpha: 0.16),
        ),
        foregroundColor: scheme.onSurface.withValues(alpha: 0.85),
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
        textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final progress = vm.totalDue == 0
        ? 0.0
        : vm.takenCount / math.max(vm.totalDue, 1);

    return Glass(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Medication summary',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildMiniAction(
                    context: context,
                    icon: Icons.history_rounded,
                    label: 'History',
                    onPressed: onOpenHistory,
                  ),
                  _buildMiniAction(
                    context: context,
                    icon: Icons.menu_book_outlined,
                    label: 'Journal',
                    onPressed: onOpenJournal,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            vm.statusTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (vm.totalDue == 0) ...[
            Text(
              'No scheduled meds today',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add a medication or update your schedule to get reminders here.',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ] else ...[
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: progress.clamp(0, 1).toDouble(),
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, child) => ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 11,
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: value.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _progressColor(scheme, value),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Taken ${vm.takenCount} of ${vm.totalDue}',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            Text(
              'Remaining: ${vm.remainingCount} doses',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onCheckIn,
                  style: FilledButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Check in'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onJournal,
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: scheme.onSurface.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Text('Journal'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

