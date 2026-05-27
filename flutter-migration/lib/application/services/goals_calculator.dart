import '../../domain/models/nutritional_goals.dart';
import '../../domain/models/planner_types.dart';
import '../../domain/models/user_profile.dart';

class GoalsCalculator {
  NutritionalGoals calculateDailyGoals(UserProfile profile) {
    final bmi = _bmi(profile.weightKg, profile.heightCm);
    final activityTier = _activityTier(profile.activityLevel);
    final calories = _adjustCaloriesByGoal(
      _mifflinStJeor(profile) * profile.activityLevel,
      profile.goalType,
    );

    final macros = _macroTargets(
      calories: calories,
      weightKg: profile.weightKg,
      goalType: profile.goalType,
      activityTier: activityTier,
      bmi: bmi,
    );

    final micros = _computeMicros(
      sex: profile.sex,
      age: profile.age,
      goalType: profile.goalType,
      activityTier: activityTier,
      bmi: bmi,
    );

    return NutritionalGoals(
      calories: calories,
      proteinG: macros.protein,
      carbsG: macros.carbs,
      fatG: macros.fat,
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
    final adjusted = switch (goalType) {
      GoalType.deficit => tdee * 0.85,
      GoalType.gain => tdee * 1.10,
      _ => tdee,
    };

    final minCal = tdee * 0.75;
    final maxCal = tdee * 1.25;
    return adjusted.clamp(minCal, maxCal).toDouble();
  }

  double _bmi(double weightKg, double heightCm) {
    final heightM = (heightCm / 100).clamp(1.2, 2.4);
    return weightKg / (heightM * heightM);
  }

  _ActivityTier _activityTier(double activityLevel) {
    if (activityLevel <= 1.30) return _ActivityTier.sedentary;
    if (activityLevel <= 1.45) return _ActivityTier.light;
    if (activityLevel <= 1.60) return _ActivityTier.moderate;
    if (activityLevel <= 1.75) return _ActivityTier.active;
    return _ActivityTier.veryActive;
  }

  ({double protein, double carbs, double fat}) _macroTargets({
    required double calories,
    required double weightKg,
    required GoalType goalType,
    required _ActivityTier activityTier,
    required double bmi,
  }) {
    final ranges = _macroRanges(goalType);
    final adjustedBase = _applyMacroAdjustments(
      base: (p: ranges.baseProtein, f: ranges.baseFat, c: ranges.baseCarbs),
      activityTier: activityTier,
      bmi: bmi,
    );

    final proteinPerKg = _proteinPerKg(
      goalType: goalType,
      activityTier: activityTier,
      bmi: bmi,
    );

    var protein = weightKg * proteinPerKg;
    final minProtein = (calories * ranges.minProtein) / 4;
    final maxProtein = (calories * ranges.maxProtein) / 4;
    protein = protein.clamp(minProtein, maxProtein).toDouble();
    var proteinPct = (protein * 4) / calories;

    var fatPct = adjustedBase.f.clamp(ranges.minFat, ranges.maxFat);
    var carbPct = 1 - proteinPct - fatPct;

    if (carbPct < ranges.minCarbs) {
      final targetFat = (1 - proteinPct - ranges.minCarbs)
          .clamp(ranges.minFat, ranges.maxFat);
      fatPct = targetFat.toDouble();
      carbPct = 1 - proteinPct - fatPct;
    } else if (carbPct > ranges.maxCarbs) {
      final targetFat = (1 - proteinPct - ranges.maxCarbs)
          .clamp(ranges.minFat, ranges.maxFat);
      fatPct = targetFat.toDouble();
      carbPct = 1 - proteinPct - fatPct;
    }

    if (carbPct < ranges.minCarbs || carbPct > ranges.maxCarbs) {
      final targetProtein = (1 - fatPct - carbPct.clamp(ranges.minCarbs, ranges.maxCarbs))
          .clamp(ranges.minProtein, ranges.maxProtein);
      proteinPct = targetProtein.toDouble();
      protein = (calories * proteinPct) / 4;
      carbPct = 1 - proteinPct - fatPct;
    }

    final fat = (calories * fatPct) / 9;
    final carbs = (calories * carbPct) / 4;

    return (protein: protein, carbs: carbs, fat: fat);
  }

  ({double minProtein, double maxProtein, double minFat, double maxFat,
    double minCarbs, double maxCarbs, double baseProtein, double baseFat, double baseCarbs})
      _macroRanges(GoalType goalType) {
    return switch (goalType) {
      GoalType.deficit => (
          minProtein: 0.30,
          maxProtein: 0.35,
          minFat: 0.25,
          maxFat: 0.30,
          minCarbs: 0.35,
          maxCarbs: 0.40,
          baseProtein: 0.33,
          baseFat: 0.27,
          baseCarbs: 0.40,
        ),
      GoalType.gain => (
          minProtein: 0.28,
          maxProtein: 0.35,
          minFat: 0.20,
          maxFat: 0.25,
          minCarbs: 0.45,
          maxCarbs: 0.55,
          baseProtein: 0.31,
          baseFat: 0.22,
          baseCarbs: 0.47,
        ),
      GoalType.maintain => (
          minProtein: 0.20,
          maxProtein: 0.25,
          minFat: 0.25,
          maxFat: 0.30,
          minCarbs: 0.45,
          maxCarbs: 0.50,
          baseProtein: 0.23,
          baseFat: 0.28,
          baseCarbs: 0.49,
        ),
      GoalType.health => (
          minProtein: 0.20,
          maxProtein: 0.25,
          minFat: 0.25,
          maxFat: 0.30,
          minCarbs: 0.45,
          maxCarbs: 0.55,
          baseProtein: 0.23,
          baseFat: 0.28,
          baseCarbs: 0.49,
        ),
    };
  }

  ({double p, double f, double c}) _applyMacroAdjustments({
    required ({double p, double f, double c}) base,
    required _ActivityTier activityTier,
    required double bmi,
  }) {
    var p = base.p;
    var f = base.f;
    var c = base.c;

    switch (activityTier) {
      case _ActivityTier.sedentary:
        p += 0.01;
        f += 0.02;
        c -= 0.03;
        break;
      case _ActivityTier.light:
        c += 0.02;
        f -= 0.01;
        break;
      case _ActivityTier.moderate:
        p += 0.01;
        c += 0.02;
        f -= 0.03;
        break;
      case _ActivityTier.active:
        p += 0.02;
        c += 0.03;
        f -= 0.05;
        break;
      case _ActivityTier.veryActive:
        p += 0.03;
        c += 0.05;
        f -= 0.08;
        break;
    }

    if (bmi >= 25) {
      p += 0.02;
      c -= 0.02;
    }

    return (p: p, f: f, c: c);
  }

  double _proteinPerKg({
    required GoalType goalType,
    required _ActivityTier activityTier,
    required double bmi,
  }) {
    final (min, max) = switch (goalType) {
      GoalType.health => (1.0, 1.2),
      GoalType.maintain => (1.2, 1.5),
      GoalType.deficit => (1.6, 2.0),
      GoalType.gain => (1.8, 2.4),
    };

    final activityAdj = switch (activityTier) {
      _ActivityTier.light => 0.1,
      _ActivityTier.moderate => 0.2,
      _ActivityTier.active => 0.3,
      _ActivityTier.veryActive => 0.4,
      _ActivityTier.sedentary => 0.0,
    };

    final bmiAdj = bmi >= 25 ? 0.1 : 0.0;
    final target = ((min + max) / 2) + activityAdj + bmiAdj;
    return target.clamp(min + activityAdj, max + activityAdj).toDouble();
  }

  ({double fiber, double iron, double calcium, double zinc, double b12})
      _computeMicros({
    required String sex,
    required int age,
    required GoalType goalType,
    required _ActivityTier activityTier,
    required double bmi,
  }) {
    final female = sex.toLowerCase() == 'female';
    final baseFiber = switch (goalType) {
      GoalType.deficit => 37.0,
      GoalType.maintain => 30.0,
      GoalType.health => 37.0,
      GoalType.gain => 32.0,
    };
    final maxFiber = switch (goalType) {
      GoalType.deficit => 45.0,
      GoalType.maintain => 35.0,
      GoalType.health => 45.0,
      GoalType.gain => 40.0,
    };
    var fiber = baseFiber + (bmi >= 25 ? 3.0 : 0.0);
    fiber = fiber.clamp(25.0, maxFiber).toDouble();

    final baseIron = female ? (age >= 51 ? 8.0 : 18.0) : 8.0;
    var iron = baseIron.clamp(8.0, 18.0).toDouble();
    iron = iron < 14.0 ? 14.0 : iron;
    if (activityTier == _ActivityTier.veryActive) {
      iron = 18.0;
    }

    final baseCalcium = age >= 71 || (female && age >= 51) ? 1200.0 : 1000.0;
    var calcium = baseCalcium.clamp(1000.0, 1300.0).toDouble();
    if (activityTier == _ActivityTier.veryActive) {
      calcium = 1300.0;
    }

    final baseZinc = female ? 8.0 : 11.0;
    var zinc = baseZinc.clamp(8.0, 14.0).toDouble();
    if (activityTier == _ActivityTier.veryActive) {
      zinc = 14.0;
    }

    return (
      fiber: fiber,
      iron: iron,
      calcium: calcium,
      zinc: zinc,
      b12: 2.4,
    );
  }
}

enum _ActivityTier { sedentary, light, moderate, active, veryActive }
