// lib/data/models/meal_option.dart
import 'package:flutter/material.dart';

enum MealSlot { breakfast, lunch, dinner, snack }

/// Represents a selectable meal option for a given slot.
class MealOption {
  const MealOption({
    required this.title,
    required this.description,
    required this.calories,
    this.tags = const [],
    this.note,
  });

  final String title;
  final String description;
  final int calories;
  final List<String> tags;
  final String? note;
}

/// Default curated meal options surfaced in the home experience.
const Map<MealSlot, List<MealOption>> kDefaultMealMenu = {
  MealSlot.breakfast: [
    MealOption(
      title: 'Sunrise Power Bowl',
      description: 'Steel-cut oats, berries, chia & almond butter',
      calories: 360,
      tags: ['Vegetarian', 'High fiber'],
      note: 'Pairs well with morning medication. Hydrate first!',
    ),
    MealOption(
      title: 'Protein Omelette',
      description: 'Egg whites, spinach, mushroom & feta with toast',
      calories: 420,
      tags: ['High protein'],
    ),
    MealOption(
      title: 'Yogurt Parfait',
      description: 'Greek yogurt, strawberry compote & granola crunch',
      calories: 310,
      tags: ['Gut friendly'],
    ),
  ],
  MealSlot.lunch: [
    MealOption(
      title: 'Mediterranean Plate',
      description: 'Herbed chicken, quinoa tabbouleh & roasted veggies',
      calories: 520,
      tags: ['Anti-inflammatory'],
    ),
    MealOption(
      title: 'Garden Wrap',
      description: 'Whole-wheat wrap, hummus, avocado & crisp greens',
      calories: 460,
      tags: ['Plant-based'],
    ),
    MealOption(
      title: 'Pho Comfort Bowl',
      description: 'Light chicken broth, rice noodles, bok choy & herbs',
      calories: 430,
      tags: ['Gluten-aware'],
    ),
  ],
  MealSlot.dinner: [
    MealOption(
      title: 'Salmon Recharge',
      description: 'Miso-glazed salmon, roasted pumpkin & jasmine rice',
      calories: 540,
      tags: ['Omega-3 boost'],
    ),
    MealOption(
      title: 'Lentil Hearth Stew',
      description: 'French lentils simmered with root veggies & thyme',
      calories: 480,
      tags: ['Vegetarian', 'Iron rich'],
    ),
    MealOption(
      title: 'Turkey Stir-fry',
      description: 'Snow peas, bell pepper & sesame brown rice',
      calories: 510,
      tags: ['High protein'],
    ),
  ],
  MealSlot.snack: [
    MealOption(
      title: 'Calm Focus Smoothie',
      description: 'Spinach, banana, flax & probiotic yogurt',
      calories: 220,
      tags: ['Brain friendly'],
    ),
    MealOption(
      title: 'Apple & Nut Butter',
      description: 'Honeycrisp slices with almond butter dip',
      calories: 190,
      tags: ['Quick energy'],
    ),
    MealOption(
      title: 'Trail Mix Bites',
      description: 'Walnuts, cranberries & dark chocolate shards',
      calories: 210,
      tags: ['Mood support'],
    ),
  ],
};

const Map<MealSlot, TimeOfDay> kDefaultMealWindows = {
  MealSlot.breakfast: TimeOfDay(hour: 8, minute: 0),
  MealSlot.lunch: TimeOfDay(hour: 12, minute: 30),
  MealSlot.dinner: TimeOfDay(hour: 18, minute: 0),
  MealSlot.snack: TimeOfDay(hour: 15, minute: 30),
};

const String kDefaultMealNotes = 'Hydrate before meals · light seasoning.';
