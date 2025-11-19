// lib/data/models/goal.dart
import 'package:flutter/material.dart';

/// Represents a care goal with optional instructions and customisation.
class Goal {
  Goal({
    required this.title,
    this.instructions,
    this.progress = 0,
    required this.category,
    required this.frequency,
    this.timesPerPeriod = 1,
    required this.startDate,
    this.endDate,
    required this.reminder,
    this.importance = GoalImportance.medium,
    this.customCategoryName,
    this.customCategoryIcon,
  })  : assert(timesPerPeriod > 0, 'timesPerPeriod must be positive'),
        assert(
          endDate == null || !endDate.isBefore(startDate),
          'endDate cannot be before startDate',
        );

  String title;
  String? instructions;
  double progress;
  GoalCategory category;
  GoalFrequency frequency;
  int timesPerPeriod;
  DateTime startDate;
  DateTime? endDate;
  TimeOfDay reminder;
  GoalImportance importance;
  String? customCategoryName;
  IconData? customCategoryIcon;
}

/// Helpers for formatting goal metadata for display.
extension GoalCategoryPresentation on Goal {
  String displayCategoryLabel() {
    if (category == GoalCategory.custom) {
      final name = customCategoryName?.trim();
      return (name == null || name.isEmpty)
          ? GoalCategory.custom.label()
          : name;
    }
    return category.label();
  }

  IconData displayCategoryIcon() {
    if (category == GoalCategory.custom) {
      if (customCategoryIcon != null) {
        return customCategoryIcon!;
      }
      final name = customCategoryName?.trim().toLowerCase();
      switch (name) {
        case 'sleep':
        case 'bedtime':
        case 'rest':
          return Icons.nightlight_round;
        case 'social':
        case 'friends':
        case 'family':
          return Icons.people_outline;
        case 'hydration':
        case 'water':
        case 'drink water':
          return Icons.local_drink_outlined;
        case 'exercise':
        case 'workout':
        case 'fitness':
          return Icons.fitness_center_outlined;
        case 'diet':
        case 'nutrition':
        case 'meal':
          return Icons.restaurant_outlined;
        default:
          return Icons.category_outlined;
      }
    }
    return category.icon();
  }

  Color displayCategoryColor(ColorScheme scheme) {
    if (category == GoalCategory.custom) {
      if (customCategoryIcon != null) {
        switch (customCategoryIcon) {
          case Icons.nightlight_round:
            return scheme.primaryContainer;
          case Icons.people_outline:
            return scheme.secondaryContainer;
          case Icons.local_drink_outlined:
            return scheme.tertiaryContainer;
          case Icons.fitness_center_outlined:
            return scheme.primary;
          case Icons.restaurant_outlined:
            return scheme.secondary;
          case Icons.self_improvement_outlined:
            return scheme.tertiary;
          case Icons.flag_outlined:
            return scheme.secondaryContainer;
          case Icons.local_florist_outlined:
            return scheme.tertiary;
          case Icons.waves_outlined:
            return scheme.primaryContainer;
          case Icons.health_and_safety_outlined:
            return scheme.secondary;
          case Icons.favorite_outline:
          case Icons.star_outline:
            return scheme.errorContainer;
          default:
            return scheme.primary;
        }
      }
      final name = customCategoryName?.trim().toLowerCase();
      switch (name) {
        case 'sleep':
        case 'bedtime':
        case 'rest':
          return scheme.primaryContainer;
        case 'social':
        case 'friends':
        case 'family':
          return scheme.secondaryContainer;
        case 'hydration':
        case 'water':
        case 'drink water':
          return scheme.tertiaryContainer;
        case 'exercise':
        case 'workout':
        case 'fitness':
          return scheme.primary;
        case 'diet':
        case 'nutrition':
        case 'meal':
          return scheme.secondary;
        default:
          return scheme.primary;
      }
    }
    return category.color(scheme);
  }
}

enum GoalCategory {
  diet,
  exercises,
  meditation,
  treatment,
  sleep,
  social,
  hydration,
  custom,
}

extension GoalCategoryLabels on GoalCategory {
  String label() => switch (this) {
        GoalCategory.diet => 'Diet',
        GoalCategory.exercises => 'Exercise',
        GoalCategory.meditation => 'Mindfulness',
        GoalCategory.treatment => 'Treatment',
        GoalCategory.sleep => 'Sleep',
        GoalCategory.social => 'Social',
        GoalCategory.hydration => 'Hydration',
        GoalCategory.custom => 'Custom',
      };

  IconData icon() => switch (this) {
        GoalCategory.diet => Icons.restaurant_outlined,
        GoalCategory.exercises => Icons.fitness_center_outlined,
        GoalCategory.meditation => Icons.self_improvement_outlined,
        GoalCategory.treatment => Icons.healing_outlined,
        GoalCategory.sleep => Icons.nightlight_round,
        GoalCategory.social => Icons.people_outline,
        GoalCategory.hydration => Icons.local_drink_outlined,
        GoalCategory.custom => Icons.category_outlined,
      };

  Color color(ColorScheme scheme) => switch (this) {
        GoalCategory.diet => scheme.secondary,
        GoalCategory.exercises => scheme.primary,
        GoalCategory.meditation => scheme.tertiary,
        GoalCategory.treatment => scheme.error,
        GoalCategory.sleep => scheme.primaryContainer,
        GoalCategory.social => scheme.secondaryContainer,
        GoalCategory.hydration => scheme.tertiaryContainer,
        GoalCategory.custom => scheme.primary,
      };
}

enum GoalFrequency { daily, weekly, monthly }

extension GoalFrequencyLabels on GoalFrequency {
  String label() => switch (this) {
        GoalFrequency.daily => 'Daily',
        GoalFrequency.weekly => 'Weekly',
        GoalFrequency.monthly => 'Monthly',
      };

  String timesLabel() => switch (this) {
        GoalFrequency.daily => 'Times per day',
        GoalFrequency.weekly => 'Times per week',
        GoalFrequency.monthly => 'Times per month',
      };

  String shortPeriod() => switch (this) {
        GoalFrequency.daily => 'day',
        GoalFrequency.weekly => 'week',
        GoalFrequency.monthly => 'month',
      };
}

enum GoalImportance { low, medium, high }

extension GoalImportanceLabels on GoalImportance {
  String label() => switch (this) {
        GoalImportance.low => 'Low',
        GoalImportance.medium => 'Medium',
        GoalImportance.high => 'High',
      };

  IconData icon() => switch (this) {
        GoalImportance.low => Icons.south_outlined,
        GoalImportance.medium => Icons.remove_outlined,
        GoalImportance.high => Icons.priority_high_outlined,
      };

  int weight() => switch (this) {
        GoalImportance.low => 0,
        GoalImportance.medium => 1,
        GoalImportance.high => 2,
      };

  Color color(ColorScheme scheme) => switch (this) {
        GoalImportance.low => scheme.tertiary,
        GoalImportance.medium => scheme.primary,
        GoalImportance.high => scheme.error,
      };
}

enum GoalSortMode { category, startDate, reminderTime, importance, custom }

extension GoalSortModeLabels on GoalSortMode {
  String label() => switch (this) {
        GoalSortMode.category => 'Category',
        GoalSortMode.startDate => 'Start date',
        GoalSortMode.reminderTime => 'Reminder time',
        GoalSortMode.importance => 'Importance',
        GoalSortMode.custom => 'Custom order',
      };

  IconData icon() => switch (this) {
        GoalSortMode.category => Icons.category_outlined,
        GoalSortMode.startDate => Icons.calendar_today_outlined,
        GoalSortMode.reminderTime => Icons.alarm_outlined,
        GoalSortMode.importance => Icons.priority_high_outlined,
        GoalSortMode.custom => Icons.swap_vert,
      };
}
