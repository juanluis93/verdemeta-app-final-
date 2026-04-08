import '../../domain/models/nutritional_goals.dart';
import '../../domain/models/planner_types.dart';
import '../../domain/models/user_profile.dart';

class GoalsCalculator {
  NutritionalGoals calculateDailyGoals(UserProfile profile) {
    final bmr = _mifflinStJeor(profile);
    final tdee = bmr * profile.activityLevel;
    final calories = _adjustCaloriesByGoal(tdee, profile.goalType);

    final protein = switch (profile.goalType) {
      GoalType.deficit => profile.weightKg * 1.9,
      GoalType.gain => profile.weightKg * 2.0,
      _ => profile.weightKg * 1.7,
    };

    final fat = (calories * 0.28) / 9;
    final carbs = (calories - (protein * 4 + fat * 9)) / 4;

    final micros = _computeMicrosBySexAge(profile.sex, profile.age);

    return NutritionalGoals(
      calories: calories,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      fiberG: micros.fiber,
      ironMg: micros.iron,
      calciumMg: micros.calcium,
      zincMg: micros.zinc,
      b12Mcg: micros.b12,
    );
  }

  double _mifflinStJeor(UserProfile profile) {
    final base =
        (10 * profile.weightKg) + (6.25 * profile.heightCm) - (5 * profile.age);
    final sexDelta = profile.sex.toLowerCase() == 'female' ? -161 : 5;
    return base + sexDelta;
  }

  double _adjustCaloriesByGoal(double tdee, GoalType goalType) {
    return switch (goalType) {
      GoalType.deficit => tdee - 300,
      GoalType.gain => tdee + 250,
      _ => tdee,
    };
  }

  ({double fiber, double iron, double calcium, double zinc, double b12})
      _computeMicrosBySexAge(String sex, int age) {
    final female = sex.toLowerCase() == 'female';
    final fiber = female ? (age > 50 ? 21.0 : 25.0) : (age > 50 ? 30.0 : 38.0);
    final iron = female ? (age >= 51 ? 8.0 : 18.0) : 8.0;
    final calcium = age >= 71 || (female && age >= 51) ? 1200.0 : 1000.0;
    final zinc = female ? 8.0 : 11.0;
    return (fiber: fiber, iron: iron, calcium: calcium, zinc: zinc, b12: 2.4);
  }
}
