import 'package:flutter/material.dart';

import 'timeline_models.dart';

class TimelinePlannerPage extends StatefulWidget {
  const TimelinePlannerPage({super.key});

  @override
  State<TimelinePlannerPage> createState() => _TimelinePlannerPageState();
}

class _TimelinePlannerPageState extends State<TimelinePlannerPage> {
  DateTime _day = DateTime.now();
  final Set<PlanType> _filters = <PlanType>{};
  late List<PlanItem> _items;

  @override
  void initState() {
    super.initState();
    _items = _mockFor(_day);
  }

  List<PlanItem> _mockFor(DateTime day) {
    final samples = [
      PlanItem(
        id: '1',
        time: const TimeOfDay(hour: 13, minute: 5),
        title: 'Naproxen 250 mg with food',
        type: PlanType.rx,
        note: 'With food to reduce GI upset.',
      ),
      PlanItem(
        id: '2',
        time: const TimeOfDay(hour: 15, minute: 5),
        title: 'Walk 20 minutes',
        type: PlanType.goals,
      ),
      PlanItem(
        id: '3',
        time: const TimeOfDay(hour: 21, minute: 5),
        title: 'Log BP reading',
        type: PlanType.trends,
      ),
      PlanItem(
        id: '4',
        time: const TimeOfDay(hour: 1, minute: 5),
        title: 'Naproxen 250 mg (second dose)',
        type: PlanType.rx,
      ),
      PlanItem(
        id: '5',
        time: const TimeOfDay(hour: 7, minute: 5),
        title: 'Evening mood check-in',
        type: PlanType.mood,
      ),
      PlanItem(
        id: '6',
        time: const TimeOfDay(hour: 9, minute: 5),
        title: 'Craving coping skill: 5-min breathing',
        type: PlanType.sud,
      ),
    ];
    samples.sort((a, b) => _toMinutes(a.time).compareTo(_toMinutes(b.time)));
    return samples;
  }

  int _toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  void _changeDay(int delta) {
    final next = DateTime(_day.year, _day.month, _day.day + delta);
    setState(() {
      _day = next;
      _items = _mockFor(next);
    });
  }

  void _toggleFilter(PlanType type) {
    setState(() {
      if (_filters.contains(type)) {
        _filters.remove(type);
      } else {
        _filters.add(type);
      }
    });
  }

  List<PlanItem> get _visible {
    final view = _filters.isEmpty
        ? List<PlanItem>.from(_items)
        : _items.where((item) => _filters.contains(item.type)).toList();
    view.sort((a, b) => _toMinutes(a.time).compareTo(_toMinutes(b.time)));
    return view;
  }

  Future<void> _addToCalendar() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to calendar (demo)')),
    );
  }

  void _markDone(PlanItem item) {
    setState(() => item.done = true);
  }

  void _snooze(PlanItem item) {
    final minutes = (_toMinutes(item.time) + 15) % (24 * 60);
    final newTime = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    setState(() {
      item.time = newTime;
      _items.sort((a, b) => _toMinutes(a.time).compareTo(_toMinutes(b.time)));
    });
  }

  void _openDetails(PlanItem item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final color = planTypeColor(item.type);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, size: 18, color: color),
                    const SizedBox(width: 6),
                    Text(
                      _fmtTime(item.time),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    _TypeChip(type: item.type),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                if (item.note != null) ...[
                  const SizedBox(height: 8),
                  Text(item.note!,
                      style: const TextStyle(color: Colors.black87)),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        _markDone(item);
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Mark done'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        _snooze(item);
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.snooze),
                      label: const Text('Snooze 15m'),
                    ),
                    const Spacer(),
                    if (item.sourceRoute != null)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.of(context).pushNamed(item.sourceRoute!);
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open source'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isDueSoon(PlanItem item) {
    if (item.done) return false;
    final nowMinutes = _toMinutes(TimeOfDay.now());
    final diff = (_toMinutes(item.time) - nowMinutes).abs();
    return diff <= 15;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Scaffold(
      appBar: AppBar(title: const Text('Timeline Planner')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _AddToCalendar(onTap: _addToCalendar),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () => _changeDay(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _labelFor(_day),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _changeDay(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in PlanType.values)
                  _FilterChipWidget(
                    label: planTypeLabel(type),
                    color: planTypeColor(type),
                    selected: _filters.contains(type),
                    onSelected: (_) => _toggleFilter(type),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: visible.isEmpty
                  ? const Center(child: Text('No tasks for this view.'))
                  : ListView.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final item = visible[index];
                        return Dismissible(
                          key: ValueKey(item.id),
                          background: const _SwipeBg(
                            color: Colors.green,
                            icon: Icons.check,
                            alignLeft: true,
                          ),
                          secondaryBackground: const _SwipeBg(
                            color: Colors.orange,
                            icon: Icons.snooze,
                            alignLeft: false,
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              _markDone(item);
                            } else {
                              _snooze(item);
                            }
                            return false;
                          },
                          child: _PlanTile(
                            item: item,
                            isDue: _isDueSoon(item),
                            onTap: () => _openDetails(item),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _labelFor(DateTime date) {
    final today = DateTime.now();
    final normalized = DateTime(date.year, date.month, date.day);
    final todayNormalized = DateTime(today.year, today.month, today.day);
    if (normalized == todayNormalized) return 'Today';
    if (normalized == todayNormalized.add(const Duration(days: 1))) {
      return 'Tomorrow';
    }
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _AddToCalendar extends StatelessWidget {
  const _AddToCalendar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available, size: 18),
            SizedBox(width: 8),
            Text('Add to Calendar',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _FilterChipWidget extends StatelessWidget {
  const _FilterChipWidget({
    required this.label,
    required this.color,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final Color color;
  final bool selected;
  final void Function(bool) onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      backgroundColor: color.withValues(alpha: 0.08),
      selectedColor: color.withValues(alpha: 0.22),
      labelStyle: TextStyle(
        color: Colors.black87,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.item,
    required this.onTap,
    required this.isDue,
  });

  final PlanItem item;
  final VoidCallback onTap;
  final bool isDue;

  @override
  Widget build(BuildContext context) {
    final color = planTypeColor(item.type);
    final timeLabel =
        '${item.time.hour.toString().padLeft(2, '0')}:${item.time.minute.toString().padLeft(2, '0')}';
    final borderColor = item.done
        ? Colors.green.withValues(alpha: 0.6)
        : isDue
            ? color.withValues(alpha: 0.6)
            : Colors.black12;
    final titleStyle = TextStyle(
      fontWeight: FontWeight.w600,
      decoration: item.done ? TextDecoration.lineThrough : null,
      color: item.done ? Colors.black54 : null,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          color: isDue ? color.withValues(alpha: 0.08) : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time_filled,
              size: 18,
              color: isDue ? color : Colors.black54,
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 56,
              child: Text(
                timeLabel,
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
            ),
            _TypeChip(type: item.type, color: color),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type, this.color});

  final PlanType type;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? planTypeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        planTypeLabel(type),
        style: TextStyle(color: tint, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  const _SwipeBg({
    required this.color,
    required this.icon,
    required this.alignLeft,
  });

  final Color color;
  final IconData icon;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Icon(icon, color: color),
    );
  }
}
