// lib/data/models/coping_plan.dart

import 'package:flutter/material.dart';

class CopingPlan {
  const CopingPlan({
    required this.id,
    required this.title,
    required this.warningSigns,
    required this.steps,
    required this.supportContacts,
    required this.safeLocations,
    this.checkInTime,
    this.pinnedAt,
  });

  final String id;
  final String title;
  final List<String> warningSigns;
  final List<CopingPlanStep> steps;
  final List<SupportContact> supportContacts;
  final List<String> safeLocations;
  final TimeOfDay? checkInTime;
  final DateTime? pinnedAt;

  CopingPlan copyWith({
    String? id,
    String? title,
    List<String>? warningSigns,
    List<CopingPlanStep>? steps,
    List<SupportContact>? supportContacts,
    List<String>? safeLocations,
    TimeOfDay? checkInTime,
    DateTime? pinnedAt,
  }) {
    return CopingPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      warningSigns: warningSigns ?? this.warningSigns,
      steps: steps ?? this.steps,
      supportContacts: supportContacts ?? this.supportContacts,
      safeLocations: safeLocations ?? this.safeLocations,
      checkInTime: checkInTime ?? this.checkInTime,
      pinnedAt: pinnedAt ?? this.pinnedAt,
    );
  }
}

class CopingPlanStep {
  const CopingPlanStep({
    required this.description,
    this.estimatedDuration = const Duration(minutes: 2),
  });

  final String description;
  final Duration estimatedDuration;
}

class SupportContact {
  const SupportContact({
    required this.name,
    required this.phone,
  });

  final String name;
  final String phone;
}
