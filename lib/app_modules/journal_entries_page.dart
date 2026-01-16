part of 'package:patient_tracker/app_modules.dart';

const List<String> _kJournalTagOptions = <String>[
  'nausea',
  'headache',
  'dizziness',
  'anxiety spike',
  'insomnia',
  'vivid dreams',
  'groggy',
  'other',
];

String _feelingLabel(JournalFeeling feeling) {
  switch (feeling) {
    case JournalFeeling.ok:
      return 'OK';
    case JournalFeeling.notGreat:
      return 'Not great';
    case JournalFeeling.bad:
      return 'Bad';
  }
}

Color _feelingColor(BuildContext context, JournalFeeling feeling) {
  final scheme = Theme.of(context).colorScheme;
  switch (feeling) {
    case JournalFeeling.ok:
      return scheme.primary;
    case JournalFeeling.notGreat:
      return scheme.tertiary;
    case JournalFeeling.bad:
      return scheme.error;
  }
}

String _tagLabel(String tag) {
  if (tag.isEmpty) return tag;
  return '${tag[0].toUpperCase()}${tag.substring(1)}';
}

Future<JournalEntry?> showJournalEntrySheet(
  BuildContext context, {
  required RxMedication medication,
  JournalEntry? existing,
}) {
  return showModalBottomSheet<JournalEntry>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _JournalEntrySheet(
      medication: medication,
      existing: existing,
    ),
  );
}

class _JournalEntrySheet extends StatefulWidget {
  const _JournalEntrySheet({required this.medication, this.existing});

  final RxMedication medication;
  final JournalEntry? existing;

  @override
  State<_JournalEntrySheet> createState() => _JournalEntrySheetState();
}

class _JournalEntrySheetState extends State<_JournalEntrySheet> {
  late JournalFeeling _feeling;
  late Set<String> _selectedTags;
  late DateTime _timestamp;
  late bool _includeSeverity;
  int? _severity;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _feeling = widget.existing?.feeling ?? JournalFeeling.ok;
    _selectedTags = widget.existing?.tags.toSet() ?? <String>{};
    _timestamp = widget.existing?.createdAt ?? DateTime.now();
    _severity = widget.existing?.severity;
    _includeSeverity = _severity != null;
    _notesController =
        TextEditingController(text: widget.existing?.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _editTimestamp() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _timestamp,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_timestamp),
    );
    if (time == null) return;
    setState(() {
      _timestamp = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _toggleSeverity(bool value) {
    setState(() {
      _includeSeverity = value;
      if (!value) {
        _severity = null;
      } else {
        _severity ??= 5;
      }
    });
  }

  void _saveEntry() {
    final notes = _notesController.text.trim();
    final entry = JournalEntry(
      id: widget.existing?.id ?? const Uuid().v4(),
      medicationId: widget.medication.name,
      createdAt: _timestamp,
      feeling: _feeling,
      tags: _selectedTags.toList(growable: false),
      severity: _includeSeverity ? _severity : null,
      notes: notes.isEmpty ? null : notes,
    );
    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing == null
                    ? 'New journal entry'
                    : 'Edit journal entry',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Medication',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  widget.medication.name,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              Text('Feeling', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<JournalFeeling>(
                segments: const <ButtonSegment<JournalFeeling>>[
                  ButtonSegment(
                    value: JournalFeeling.ok,
                    label: Text('OK'),
                  ),
                  ButtonSegment(
                    value: JournalFeeling.notGreat,
                    label: Text('Not great'),
                  ),
                  ButtonSegment(
                    value: JournalFeeling.bad,
                    label: Text('Bad'),
                  ),
                ],
                selected: <JournalFeeling>{_feeling},
                onSelectionChanged: (selection) {
                  setState(() {
                    _feeling = selection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              Text('Symptom tags', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kJournalTagOptions
                    .map(
                      (tag) => FilterChip(
                        label: Text(_tagLabel(tag)),
                        selected: _selectedTags.contains(tag),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Severity (optional)',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  Switch(value: _includeSeverity, onChanged: _toggleSeverity),
                ],
              ),
              if (_includeSeverity) ...[
                Slider(
                  value: (_severity ?? 5).toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '${_severity ?? 5}',
                  onChanged: (value) {
                    setState(() {
                      _severity = value.round();
                    });
                  },
                ),
              ],
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: const Text('Timestamp'),
                subtitle: Text(formatDateTime(_timestamp)),
                trailing: const Icon(Icons.edit_outlined, size: 20),
                onTap: _editTimestamp,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 4,
                minLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'What happened after you took it?',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_feeling == JournalFeeling.bad) ...[
                const SizedBox(height: 12),
                Text(
                  'If symptoms are severe or urgent, contact your clinician or seek emergency care.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saveEntry,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JournalEntriesPage extends StatefulWidget {
  const JournalEntriesPage({
    super.key,
    this.medication,
    this.medications = const <RxMedication>[],
    required this.entries,
    required this.onEntriesChanged,
  });

  final RxMedication? medication;
  final List<RxMedication> medications;
  final List<JournalEntry> entries;
  final Future<void> Function(List<JournalEntry> entries) onEntriesChanged;

  @override
  State<JournalEntriesPage> createState() => _JournalEntriesPageState();
}

class _JournalEntriesPageState extends State<JournalEntriesPage> {
  late List<JournalEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = List<JournalEntry>.from(widget.entries);
  }

  bool get _isGlobalScope => widget.medication == null;

  List<JournalEntry> _entriesForScope() {
    final filtered = _isGlobalScope
        ? List<JournalEntry>.from(_entries)
        : _entries
            .where((entry) => entry.medicationId == widget.medication!.name)
            .toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  RxMedication? _resolveMedication(JournalEntry entry) {
    if (widget.medication != null) return widget.medication;
    for (final med in widget.medications) {
      if (med.name == entry.medicationId) return med;
    }
    return null;
  }

  Future<void> _applyEntries(List<JournalEntry> updated) async {
    setState(() {
      _entries = updated;
    });
    await widget.onEntriesChanged(updated);
  }

  Future<void> _editEntry(JournalEntry entry) async {
    final medication = _resolveMedication(entry);
    if (medication == null) {
      showToast(context, 'Medication not found for this entry.');
      return;
    }
    final updated = await showJournalEntrySheet(
      context,
      medication: medication,
      existing: entry,
    );
    if (updated == null) return;
    final next = List<JournalEntry>.from(_entries);
    final index = next.indexWhere((item) => item.id == entry.id);
    if (index == -1) return;
    next[index] = updated;
    next.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _applyEntries(next);
    if (!mounted) return;
    showToast(context, 'Saved to journal ✅');
  }

  Future<void> _deleteEntry(JournalEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This journal entry will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final next = List<JournalEntry>.from(_entries)
      ..removeWhere((item) => item.id == entry.id);
    await _applyEntries(next);
  }

  Widget _buildFeelingBadge(BuildContext context, JournalFeeling feeling) {
    final color = _feelingColor(context, feeling);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _feelingLabel(feeling),
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildEntryCard(BuildContext context, JournalEntry entry) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final medicationLabel =
        _isGlobalScope ? entry.medicationId : widget.medication!.name;
    return InkWell(
      onTap: () => _editEntry(entry),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  formatTime(entry.createdAt),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                _buildFeelingBadge(context, entry.feeling),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: scheme.onSurfaceVariant,
                  tooltip: 'Delete entry',
                  onPressed: () => _deleteEntry(entry),
                ),
              ],
            ),
            if (_isGlobalScope)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  medicationLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                  ),
                ),
              ),
            if (entry.tags.isNotEmpty)
              Text(
                'Tags: ${entry.tags.map(_tagLabel).join(', ')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            if (entry.severity != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Severity: ${entry.severity}/10',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ),
            if ((entry.notes ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  entry.notes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entriesForScope();
    final grouped = <DateTime, List<JournalEntry>>{};
    for (final entry in entries) {
      final day = DateUtils.dateOnly(entry.createdAt);
      grouped.putIfAbsent(day, () => <JournalEntry>[]).add(entry);
    }
    final days = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isGlobalScope
              ? 'Journal - All medications'
              : 'Journal - ${widget.medication!.name}',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: entries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.note_alt_outlined,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.7)),
                    const SizedBox(height: 10),
                    Text(
                      'No journal entries yet',
                      style: Theme.of(context).textTheme.titleSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap Journal to add one.',
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
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                for (final day in days) ...[
                  Text(
                    formatDate(day),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.75),
                        ),
                  ),
                  const SizedBox(height: 8),
                  for (final entry in grouped[day]!) ...[
                    _buildEntryCard(context, entry),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 6),
                ],
              ],
            ),
    );
  }
}

