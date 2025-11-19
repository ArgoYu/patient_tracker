enum PlanSource { goals, prescription, mood, trends, sud, ai }

class PlanItem {
  final DateTime when;
  final String text;
  final PlanSource source;
  const PlanItem(this.when, this.text, this.source);
}

abstract class GoalsRepo {
  Future<List<PlanItem>> todayGoals();
}

abstract class PrescriptionRepo {
  Future<List<PlanItem>> todayMeds();
}

abstract class MoodRepo {
  Future<List<PlanItem>> todayMoodPrompts();
}

abstract class TrendsRepo {
  Future<List<PlanItem>> todayTrendsChecks();
}

abstract class SudRepo {
  Future<List<PlanItem>> todaySupports();
}

/// Default mock adapters (non-invasive; swap when real repos are ready)
class MockGoalsRepo implements GoalsRepo {
  @override
  Future<List<PlanItem>> todayGoals() async => [
        PlanItem(
          DateTime.now().add(const Duration(hours: 2)),
          'Walk 20 minutes',
          PlanSource.goals,
        ),
      ];
}

class MockPrescriptionRepo implements PrescriptionRepo {
  @override
  Future<List<PlanItem>> todayMeds() async => [
        PlanItem(
          DateTime.now().add(const Duration(hours: 0)),
          'Naproxen 250 mg with food',
          PlanSource.prescription,
        ),
        PlanItem(
          DateTime.now().add(const Duration(hours: 12)),
          'Naproxen 250 mg (second dose)',
          PlanSource.prescription,
        ),
      ];
}

class MockMoodRepo implements MoodRepo {
  @override
  Future<List<PlanItem>> todayMoodPrompts() async => [
        PlanItem(
          DateTime.now().add(const Duration(hours: 18)),
          'Evening mood check-in',
          PlanSource.mood,
        ),
      ];
}

class MockTrendsRepo implements TrendsRepo {
  @override
  Future<List<PlanItem>> todayTrendsChecks() async => [
        PlanItem(
          DateTime.now().add(const Duration(hours: 8)),
          'Log BP reading',
          PlanSource.trends,
        ),
      ];
}

class MockSudRepo implements SudRepo {
  @override
  Future<List<PlanItem>> todaySupports() async => [
        PlanItem(
          DateTime.now().add(const Duration(hours: 20)),
          'Craving coping skill: 5-min breathing',
          PlanSource.sud,
        ),
      ];
}

class PlannerService {
  final GoalsRepo goals;
  final PrescriptionRepo rx;
  final MoodRepo mood;
  final TrendsRepo trends;
  final SudRepo sud;

  PlannerService({
    GoalsRepo? goals,
    PrescriptionRepo? rx,
    MoodRepo? mood,
    TrendsRepo? trends,
    SudRepo? sud,
  })  : goals = goals ?? MockGoalsRepo(),
        rx = rx ?? MockPrescriptionRepo(),
        mood = mood ?? MockMoodRepo(),
        trends = trends ?? MockTrendsRepo(),
        sud = sud ?? MockSudRepo();

  /// Merge home data with AI follow-ups (from AiCareContext.followUps).
  Future<List<PlanItem>> buildTodayPlan({
    List<String> aiFollowUps = const [],
  }) async {
    final items = <PlanItem>[
      ...await goals.todayGoals(),
      ...await rx.todayMeds(),
      ...await mood.todayMoodPrompts(),
      ...await trends.todayTrendsChecks(),
      ...await sud.todaySupports(),
      ...aiFollowUps.map(
        (t) => PlanItem(
          DateTime.now().add(const Duration(hours: 1)),
          t,
          PlanSource.ai,
        ),
      ),
    ];
    items.sort((a, b) => a.when.compareTo(b.when));
    return items;
  }
}
