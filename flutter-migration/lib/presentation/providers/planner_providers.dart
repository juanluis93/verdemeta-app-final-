import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/iterable_extensions.dart';
import '../../application/services/day_rebalance_service.dart';
import '../../application/services/day_validation_service.dart';
import '../../application/services/goals_calculator.dart';
import '../../application/services/monthly_planner_service.dart';
import '../../data/repositories/food_catalog_repository.dart';
import '../../data/repositories/month_plan_repository.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../../domain/models/day_plan.dart';
import '../../domain/models/day_validation_result.dart';
import '../../domain/models/meal_item.dart';
import '../../domain/models/month_plan.dart';
import '../../domain/models/nutritional_goals.dart';
import '../../domain/models/planner_types.dart';
import '../../domain/models/user_profile.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => LocalUserProfileRepository(),
);

final foodCatalogRepositoryProvider = Provider<FoodCatalogRepository>(
  (ref) => SqlFoodCatalogRepository(),
);

final monthPlanRepositoryProvider = Provider<MonthPlanRepository>(
  (ref) => InMemoryMonthPlanRepository(),
);

final goalsCalculatorProvider = Provider((ref) => GoalsCalculator());
final dayValidationServiceProvider = Provider((ref) => DayValidationService());
final dayRebalanceServiceProvider = Provider(
  (ref) => DayRebalanceService(ref.read(dayValidationServiceProvider)),
);
final monthlyPlannerServiceProvider = Provider(
  (ref) => MonthlyPlannerService(ref.read(dayRebalanceServiceProvider)),
);

final userProfileProvider = FutureProvider<UserProfile>(
  (ref) => ref.read(userProfileRepositoryProvider).getCurrentProfile(),
);

final foodCatalogProvider = FutureProvider(
  (ref) => ref.read(foodCatalogRepositoryProvider).getFoodCatalog(),
);

final nutritionalGoalsProvider = FutureProvider<NutritionalGoals>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return ref.read(goalsCalculatorProvider).calculateDailyGoals(profile);
});

class MonthPlanState {
  final MonthPlan? monthPlan;
  final bool isCreating;
  final String? error;

  const MonthPlanState({
    this.monthPlan,
    this.isCreating = false,
    this.error,
  });

  MonthPlanState copyWith({
    MonthPlan? monthPlan,
    bool? isCreating,
    String? error,
  }) {
    return MonthPlanState(
      monthPlan: monthPlan ?? this.monthPlan,
      isCreating: isCreating ?? this.isCreating,
      error: error,
    );
  }
}

class MonthPlanNotifier extends AsyncNotifier<MonthPlanState> {
  @override
  Future<MonthPlanState> build() async {
    return const MonthPlanState();
  }

  Future<void> createMonthlyPlan(
      {required int year, required int month}) async {
    state = const AsyncLoading();

    try {
      final profile = await ref.read(userProfileProvider.future);
      final goals = await ref.read(nutritionalGoalsProvider.future);
      final catalog = await ref.read(foodCatalogProvider.future);

      final monthPlan =
          ref.read(monthlyPlannerServiceProvider).createMonthlyPlan(
                year: year,
                month: month,
                profile: profile,
                goals: goals,
                catalog: catalog,
              );

      await ref.read(monthPlanRepositoryProvider).saveMonthPlan(monthPlan);
      state = AsyncData(MonthPlanState(monthPlan: monthPlan));
    } catch (e) {
      state = AsyncData(MonthPlanState(error: e.toString()));
    }
  }

  Future<void> setMonthPlan(MonthPlan monthPlan) async {
    await ref.read(monthPlanRepositoryProvider).saveMonthPlan(monthPlan);
    state = AsyncData(MonthPlanState(monthPlan: monthPlan));
  }
}

final monthPlanProvider =
    AsyncNotifierProvider<MonthPlanNotifier, MonthPlanState>(
        MonthPlanNotifier.new);

class DayEditorState {
  final DayPlan? workingDay;
  final DayValidationResult? validation;
  final bool isDirty;
  final bool isRebalancing;

  const DayEditorState({
    this.workingDay,
    this.validation,
    this.isDirty = false,
    this.isRebalancing = false,
  });

  DayEditorState copyWith({
    DayPlan? workingDay,
    DayValidationResult? validation,
    bool? isDirty,
    bool? isRebalancing,
  }) {
    return DayEditorState(
      workingDay: workingDay ?? this.workingDay,
      validation: validation ?? this.validation,
      isDirty: isDirty ?? this.isDirty,
      isRebalancing: isRebalancing ?? this.isRebalancing,
    );
  }
}

class DayEditorNotifier extends FamilyNotifier<DayEditorState, DateTime> {
  @override
  DayEditorState build(DateTime arg) {
    final monthState = ref.watch(monthPlanProvider).valueOrNull;
    final day = monthState?.monthPlan?.dayPlans
        .where((d) =>
            d.date.year == arg.year &&
            d.date.month == arg.month &&
            d.date.day == arg.day)
        .firstOrNull;

    return DayEditorState(workingDay: day, validation: null, isDirty: false);
  }

  void editMealItem({required String mealItemId, required int newFoodItemId}) {
    final day = state.workingDay;
    if (day == null) return;

    final nextItems = day.items
        .map((item) => item.id == mealItemId
            ? item.copyWith(foodItemId: newFoodItemId)
            : item)
        .toList();

    _updateDayItems(nextItems);
  }

  void addMealItem({required MealType mealType, required int foodItemId}) {
    final day = state.workingDay;
    if (day == null) return;

    final newItem = MealItem(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      foodItemId: foodItemId,
      grams: 120,
      mealType: mealType,
    );

    _updateDayItems([...day.items, newItem]);
  }

  void removeMealItem({required String mealItemId}) {
    final day = state.workingDay;
    if (day == null) return;
    _updateDayItems(day.items.where((item) => item.id != mealItemId).toList());
  }

  Future<void> rebalanceDay() async {
    final day = state.workingDay;
    if (day == null) return;

    state = state.copyWith(isRebalancing: true);

    final goals = await ref.read(nutritionalGoalsProvider.future);
    final catalog = await ref.read(foodCatalogProvider.future);

    final rebalanced = ref.read(dayRebalanceServiceProvider).rebalanceDay(
          dayPlan: day,
          goals: goals,
          catalog: catalog,
        );

    final validation =
        ref.read(dayValidationServiceProvider).validateDay(rebalanced, goals);

    state = state.copyWith(
      workingDay: rebalanced,
      validation: validation,
      isDirty: true,
      isRebalancing: false,
    );
  }

  Future<void> validateDay() async {
    final day = state.workingDay;
    if (day == null) return;

    final goals = await ref.read(nutritionalGoalsProvider.future);
    final result =
        ref.read(dayValidationServiceProvider).validateDay(day, goals);
    state = state.copyWith(validation: result);
  }

  Future<bool> saveDay() async {
    final day = state.workingDay;
    if (day == null) return false;

    final goals = await ref.read(nutritionalGoalsProvider.future);
    final validation =
        ref.read(dayValidationServiceProvider).validateDay(day, goals);

    if (!validation.isValid) {
      state = state.copyWith(validation: validation);
      return false;
    }

    final monthState = ref.read(monthPlanProvider).valueOrNull;
    final currentPlan = monthState?.monthPlan;
    if (currentPlan == null) return false;

    final updatedDays = currentPlan.dayPlans
        .map((dp) => (dp.date.year == day.date.year &&
                dp.date.month == day.date.month &&
                dp.date.day == day.date.day)
            ? day.copyWith(validationStatus: ValidationStatus.valid)
            : dp)
        .toList();

    final updatedPlan = currentPlan.copyWith(
      dayPlans: updatedDays,
      updatedAt: DateTime.now(),
    );

    await ref.read(monthPlanProvider.notifier).setMonthPlan(updatedPlan);
    state = state.copyWith(validation: validation, isDirty: false);
    return true;
  }

  Future<void> _updateDayItems(List<MealItem> nextItems) async {
    final day = state.workingDay;
    if (day == null) return;

    final catalog = await ref.read(foodCatalogProvider.future);
    final totals =
        ref.read(dayRebalanceServiceProvider).computeTotals(nextItems, catalog);

    state = state.copyWith(
      workingDay: day.copyWith(
          items: nextItems,
          totals: totals,
          validationStatus: ValidationStatus.pending),
      isDirty: true,
    );
  }
}

final dayEditorProvider =
    NotifierProvider.family<DayEditorNotifier, DayEditorState, DateTime>(
  DayEditorNotifier.new,
);

final todayPlanProvider = Provider<DayPlan?>((ref) {
  final monthState = ref.watch(monthPlanProvider).valueOrNull;
  final plan = monthState?.monthPlan;
  if (plan == null) return null;

  final now = DateTime.now();
  return plan.dayPlans
      .where((d) =>
          d.date.year == now.year &&
          d.date.month == now.month &&
          d.date.day == now.day)
      .firstOrNull;
});
