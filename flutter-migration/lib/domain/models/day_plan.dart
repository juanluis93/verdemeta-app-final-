import 'meal_item.dart';
import 'nutritional_goals.dart';
import 'planner_types.dart';
import 'suggestion.dart';

class DayPlan {
  final DateTime date;
  final List<MealItem> items;
  final NutritionalGoals totals;
  final ValidationStatus validationStatus;
  final List<Suggestion> suggestions;

  const DayPlan({
    required this.date,
    required this.items,
    required this.totals,
    required this.validationStatus,
    required this.suggestions,
  });

  DayPlan copyWith({
    DateTime? date,
    List<MealItem>? items,
    NutritionalGoals? totals,
    ValidationStatus? validationStatus,
    List<Suggestion>? suggestions,
  }) {
    return DayPlan(
      date: date ?? this.date,
      items: items ?? this.items,
      totals: totals ?? this.totals,
      validationStatus: validationStatus ?? this.validationStatus,
      suggestions: suggestions ?? this.suggestions,
    );
  }
}
