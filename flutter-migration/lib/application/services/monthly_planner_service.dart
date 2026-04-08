import '../../domain/models/day_plan.dart';
import '../../domain/models/food_item.dart';
import '../../domain/models/meal_item.dart';
import '../../domain/models/month_plan.dart';
import '../../domain/models/nutritional_goals.dart';
import '../../domain/models/planner_types.dart';
import '../../domain/models/user_profile.dart';
import 'day_rebalance_service.dart';

class MonthlyPlannerService {
  MonthlyPlannerService(this._rebalanceService);

  final DayRebalanceService _rebalanceService;

  MonthPlan createMonthlyPlan({
    required int year,
    required int month,
    required UserProfile profile,
    required NutritionalGoals goals,
    required List<FoodItem> catalog,
  }) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final dayPlans = <DayPlan>[];

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final draft = _buildInitialDayPlan(date, catalog);
      final balanced = _rebalanceService.rebalanceDay(
        dayPlan: draft,
        goals: goals,
        catalog: catalog,
      );
      dayPlans.add(balanced);
    }

    return MonthPlan(
      year: year,
      month: month,
      userId: profile.id,
      dayPlans: dayPlans,
      isLockedForPublish: false,
      updatedAt: DateTime.now(),
    );
  }

  DayPlan _buildInitialDayPlan(DateTime date, List<FoodItem> catalog) {
    final breakfast =
        catalog.isNotEmpty ? catalog[0] : throw StateError('Catalog empty');
    final lunch = catalog.length > 1 ? catalog[1] : breakfast;
    final snack = catalog.length > 2 ? catalog[2] : breakfast;
    final dinner = catalog.length > 3 ? catalog[3] : lunch;

    final items = <MealItem>[
      MealItem(
          id: '${date.millisecondsSinceEpoch}-b',
          foodItemId: breakfast.id,
          grams: 140,
          mealType: MealType.breakfast),
      MealItem(
          id: '${date.millisecondsSinceEpoch}-l',
          foodItemId: lunch.id,
          grams: 180,
          mealType: MealType.lunch),
      MealItem(
          id: '${date.millisecondsSinceEpoch}-s',
          foodItemId: snack.id,
          grams: 80,
          mealType: MealType.snack),
      MealItem(
          id: '${date.millisecondsSinceEpoch}-d',
          foodItemId: dinner.id,
          grams: 180,
          mealType: MealType.dinner),
      MealItem(
          id: '${date.millisecondsSinceEpoch}-bev',
          foodItemId: dinner.id,
          grams: 120,
          mealType: MealType.beverage),
    ];

    final totals = _rebalanceService.computeTotals(items, catalog);
    return DayPlan(
      date: date,
      items: items,
      totals: totals,
      validationStatus: ValidationStatus.pending,
      suggestions: const [],
    );
  }
}
