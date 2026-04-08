import 'dart:math' as math;

import '../../core/constants/nutrition_constants.dart';
import '../../domain/models/day_plan.dart';
import '../../domain/models/day_validation_result.dart';
import '../../domain/models/food_item.dart';
import '../../domain/models/meal_item.dart';
import '../../domain/models/nutritional_goals.dart';
import '../../domain/models/planner_types.dart';
import '../../domain/models/suggestion.dart';
import 'day_validation_service.dart';

class DayRebalanceService {
  DayRebalanceService(this._validator);

  final DayValidationService _validator;

  /*
  PSEUDOCODE
  function rebalanceDay(dayPlan, goals, catalog):
    workingItems = clone(dayPlan.items)
    repeat maxIterations:
      totals = computeTotals(workingItems, catalog)
      validation = validateDay(totals, goals)
      if validation.isValid:
        return day(valid)
      workingItems = adjustPortions(workingItems, totals, goals)
    return day(invalid + suggestions)
  */

  DayPlan rebalanceDay({
    required DayPlan dayPlan,
    required NutritionalGoals goals,
    required List<FoodItem> catalog,
  }) {
    var workingItems = List<MealItem>.from(dayPlan.items);

    for (var i = 0; i < NutritionConstants.rebalanceMaxIterations; i++) {
      final totals = computeTotals(workingItems, catalog);
      final tempPlan = dayPlan.copyWith(items: workingItems, totals: totals);
      final validation = _validator.validateDay(tempPlan, goals);
      if (validation.isValid) {
        return tempPlan.copyWith(
          validationStatus: ValidationStatus.valid,
          suggestions: const [],
        );
      }

      workingItems = _adjustPortions(workingItems, goals, totals, catalog);
    }

    final totals = computeTotals(workingItems, catalog);
    final finalPlan = dayPlan.copyWith(items: workingItems, totals: totals);
    final finalValidation = _validator.validateDay(finalPlan, goals);

    return finalPlan.copyWith(
      validationStatus: finalValidation.isValid
          ? ValidationStatus.valid
          : ValidationStatus.invalid,
      suggestions: _toSuggestions(finalValidation, finalPlan.date),
    );
  }

  List<Suggestion> suggestChanges({
    required DayValidationResult validation,
    required DateTime date,
  }) {
    return _toSuggestions(validation, date);
  }

  NutritionalGoals computeTotals(List<MealItem> items, List<FoodItem> catalog) {
    NutritionalGoals totals = const NutritionalGoals.zero();
    final foodById = {for (final f in catalog) f.id: f};

    for (final item in items) {
      final food = foodById[item.foodItemId];
      if (food == null) continue;
      totals = totals + food.forGrams(item.grams);
    }

    return totals;
  }

  List<MealItem> _adjustPortions(
    List<MealItem> items,
    NutritionalGoals goals,
    NutritionalGoals totals,
    List<FoodItem> catalog,
  ) {
    final calorieRatio = goals.calories <= 0
        ? 1.0
        : (goals.calories / math.max(1, totals.calories)).clamp(0.92, 1.08);

    return items
        .map((meal) => meal.copyWith(
              grams: (meal.grams * calorieRatio)
                  .clamp(
                    NutritionConstants.minPortionGrams,
                    NutritionConstants.maxPortionGrams,
                  )
                  .toDouble(),
            ))
        .toList();
  }

  List<Suggestion> _toSuggestions(
      DayValidationResult validation, DateTime date) {
    return validation.errors
        .asMap()
        .entries
        .map(
          (entry) => Suggestion(
            id: 'sug-${date.millisecondsSinceEpoch}-${entry.key}',
            day: date,
            severity: SuggestionSeverity.medium,
            type: SuggestionType.adjustPortion,
            message: entry.value,
            actionPayload: const {},
          ),
        )
        .toList();
  }
}
