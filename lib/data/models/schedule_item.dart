// lib/data/models/schedule_item.dart
import 'package:flutter/material.dart';

/// A scheduled item such as visits or lab tests.
class ScheduleItem {
  ScheduleItem({
    required this.title,
    required this.date,
    this.notes,
    required this.kind,
    this.location,
    this.link,
    this.doctor,
    this.attendees = const [],
  });

  final String title;
  final DateTime date;
  final String? notes;
  final ScheduleKind kind;
  final String? location;
  final String? link;
  final String? doctor;
  final List<String> attendees;
}

enum ScheduleKind { surgery, discharge, lab, other }

extension ScheduleKindPresentation on ScheduleKind {
  String label() => switch (this) {
        ScheduleKind.surgery => 'Surgery',
        ScheduleKind.discharge => 'Discharge',
        ScheduleKind.lab => 'Lab test',
        ScheduleKind.other => 'Other',
      };

  IconData icon() => switch (this) {
        ScheduleKind.surgery => Icons.healing,
        ScheduleKind.discharge => Icons.exit_to_app,
        ScheduleKind.lab => Icons.biotech,
        ScheduleKind.other => Icons.event_note,
      };
}
