// lib/features/medications/medication_timeline_screen.dart

import 'dart:collection';

import 'package:flutter/material.dart';

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

class MedicationTimelineScreen extends StatelessWidget {
  const MedicationTimelineScreen({
    super.key,
    required this.medicationId,
    this.medicationDisplayName,
    this.checkIns = const <RxCheckIn>[],
  });

  final String medicationId;
  final String? medicationDisplayName;
  final List<RxCheckIn> checkIns;

  Map<DateTime, List<RxCheckIn>> _groupByDay(List<RxCheckIn> entries) {
    final map = <DateTime, List<RxCheckIn>>{};
    for (final entry in entries) {
      final timestamp = entry.timestamp;
      final dayKey = DateTime(timestamp.year, timestamp.month, timestamp.day);
      map.putIfAbsent(dayKey, () => <RxCheckIn>[]).add(entry);
    }
    for (final bucket in map.values) {
      bucket.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    final sortedMap = LinkedHashMap<DateTime, List<RxCheckIn>>();
    for (final key in sortedKeys) {
      sortedMap[key] = map[key] ?? <RxCheckIn>[];
    }
    return sortedMap;
  }

  String _titleText() {
    final label = medicationDisplayName ?? medicationId;
    if (label.trim().isEmpty) {
      return 'Medication history';
    }
    return '$label history';
  }

  @override
  Widget build(BuildContext context) {
    final sortedEntries = List<RxCheckIn>.from(checkIns)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final grouped = _groupByDay(sortedEntries);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleText()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: grouped.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_toggle_off,
                        size: 36,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No medication history yet',
                        style: Theme.of(context).textTheme.titleSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Check in to start tracking your timeline.',
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
                children: [
                  for (final entry in grouped.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 6),
                      child: Text(
                        formatDate(entry.key),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.75),
                            ),
                      ),
                    ),
                    for (final checkIn in entry.value)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatTime(checkIn.timestamp),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Checked in',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.75),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
      ),
    );
  }
}
