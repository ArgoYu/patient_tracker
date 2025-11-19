import 'package:flutter/material.dart';

enum PlanType { rx, goals, trends, mood, sud, other }

class PlanItem {
  PlanItem({
    required this.id,
    required this.time,
    required this.title,
    required this.type,
    this.note,
    this.sourceRoute,
    this.done = false,
  });

  final String id;
  TimeOfDay time; // mutable to support snooze adjustments
  final String title;
  final PlanType type;
  final String? note;
  final String? sourceRoute;
  bool done;
}

String planTypeLabel(PlanType type) {
  switch (type) {
    case PlanType.rx:
      return 'Rx';
    case PlanType.goals:
      return 'Goals';
    case PlanType.trends:
      return 'Trends';
    case PlanType.mood:
      return 'Mood';
    case PlanType.sud:
      return 'SUD';
    case PlanType.other:
      return 'Task';
  }
}

Color planTypeColor(PlanType type) {
  switch (type) {
    case PlanType.rx:
      return Colors.indigo;
    case PlanType.goals:
      return Colors.teal;
    case PlanType.trends:
      return Colors.blueGrey;
    case PlanType.mood:
      return Colors.purple;
    case PlanType.sud:
      return Colors.orange;
    case PlanType.other:
      return Colors.grey;
  }
}
