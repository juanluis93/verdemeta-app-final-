import 'dart:math' as math;

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

  static const int _varietyWindowDays = 7;
  static const List<String> _breakfastKeywords = [
    'desayuno',
    'avena',
    'pan',
    'tostad',
    'cereal',
    'granola',
    'yogur',
    'yogurt',
    'fruta',
    'frutas',
    'smoothie',
    'batido',
    'pancake',
    'pancakes',
    'muffin',
    'chia',
    'pudding',
    'platano',
    'banana',
    'manzana',
    'naranja',
    'pera',
    'mango',
    'acai',
    'porridge',
    'arepa',
    'tortita',
    'french toast',
  ];

  static const List<String> _breakfastAvoidKeywords = [
    'arroz',
    'pasta',
    'ramen',
    'curry',
    'taco',
    'burrito',
    'pizza',
    'pad thai',
    'estofado',
    'guiso',
    'sopa',
    'ensalada',
    'wrap',
    'fideo',
  ];

  static const List<String> _snackKeywords = [
    'fruta',
    'frutas',
    'nuez',
    'almendra',
    'semilla',
    'yogur',
    'yogurt',
    'barrita',
    'batido',
    'smoothie',
    'chia',
    'granola',
  ];

  String _normalizeFoodName(String name) {
    return name
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('ü', 'u');
  }

  bool _matchesKeywords(String name, List<String> keywords) {
    return keywords.any(name.contains);
  }

  List<FoodItem> _filterCatalogForMeal(List<FoodItem> catalog, MealType meal) {
    if (catalog.isEmpty) return catalog;
    final normalized = catalog
        .map((food) => MapEntry(food, _normalizeFoodName(food.name)))
        .toList(growable: false);

    if (meal == MealType.breakfast) {
      final preferred = normalized
          .where((entry) => _matchesKeywords(entry.value, _breakfastKeywords))
          .map((entry) => entry.key)
          .toList(growable: false);
      if (preferred.isNotEmpty) return preferred;

      final avoidHeavy = normalized
          .where(
            (entry) =>
                !_matchesKeywords(entry.value, _breakfastAvoidKeywords),
          )
          .map((entry) => entry.key)
          .toList(growable: false);
      if (avoidHeavy.isNotEmpty) return avoidHeavy;
    }

    if (meal == MealType.snack) {
      final preferred = normalized
          .where((entry) => _matchesKeywords(entry.value, _snackKeywords))
          .map((entry) => entry.key)
          .toList(growable: false);
      if (preferred.isNotEmpty) return preferred;
    }

    if (meal == MealType.lunch || meal == MealType.dinner) {
      final filtered = normalized
          .where((entry) => !_matchesKeywords(entry.value, _breakfastKeywords))
          .map((entry) => entry.key)
          .toList(growable: false);
      if (filtered.isNotEmpty) return filtered;
    }

    return catalog;
  }

  FoodItem _pickFoodUnique(
    List<FoodItem> foods,
    int seed,
    Set<int> used,
    Set<int> recent,
    FoodItem fallback,
  ) {
    if (foods.isEmpty) return fallback;
    final length = foods.length;
    for (var i = 0; i < length; i++) {
      final candidate = foods[(seed + i) % length];
      if (!used.contains(candidate.id) && !recent.contains(candidate.id)) {
        used.add(candidate.id);
        return candidate;
      }
    }
    for (var i = 0; i < length; i++) {
      final candidate = foods[(seed + i) % length];
      if (!used.contains(candidate.id)) {
        used.add(candidate.id);
        return candidate;
      }
    }
    final fallbackCandidate = foods[seed % length];
    used.add(fallbackCandidate.id);
    return fallbackCandidate;
  }

  int _createPlanSeed() {
    final rand = math.Random();
    return DateTime.now().microsecondsSinceEpoch ^ rand.nextInt(1 << 31);
  }

  MonthPlan createMonthlyPlan({
    required int year,
    required int month,
    required UserProfile profile,
    required NutritionalGoals goals,
    required List<FoodItem> catalog,
  }) {
    final effectiveCatalog = catalog
        .where((item) => !profile.undesiredFoodIds.contains(item.id))
        .toList(growable: false);
    if (effectiveCatalog.isEmpty) {
      throw StateError(
        'No hay alimentos disponibles despues de aplicar filtros del perfil.',
      );
    }

    final recentMealHistory = <MealType, List<Set<int>>>{
      MealType.breakfast: <Set<int>>[],
      MealType.lunch: <Set<int>>[],
      MealType.dinner: <Set<int>>[],
      MealType.snack: <Set<int>>[],
      MealType.beverage: <Set<int>>[],
    };
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final dayPlans = <DayPlan>[];
    final planSeed = _createPlanSeed();

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final recentIdsByMealType = <MealType, Set<int>>{
        for (final entry in recentMealHistory.entries)
          entry.key: entry.value.fold<Set<int>>(
            <int>{},
            (acc, ids) => acc..addAll(ids),
          ),
      };
      final draft = _buildInitialDayPlan(
        date,
        effectiveCatalog,
        planSeed,
        goals,
        recentIdsByMealType,
      );
      final balanced = _rebalanceService.rebalanceDay(
        dayPlan: draft,
        goals: goals,
        catalog: effectiveCatalog,
      );
      dayPlans.add(balanced);

      for (final item in balanced.items) {
        final history = recentMealHistory[item.mealType];
        if (history == null) continue;
        history.add({item.foodItemId});
        if (history.length > _varietyWindowDays) {
          history.removeAt(0);
        }
      }
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

  DayPlan _buildInitialDayPlan(
    DateTime date,
    List<FoodItem> catalog,
    int planSeed,
    NutritionalGoals goals,
    Map<MealType, Set<int>> recentIdsByMealType,
  ) {
    if (catalog.isEmpty) {
      throw StateError('Catalog empty');
    }

    final seed = planSeed + (date.day * 31) + (date.month * 13);
    final used = <int>{};
    final mealTypes = _mealTypesForCalories(goals.calories);

    final items = <MealItem>[];
    for (var index = 0; index < mealTypes.length; index++) {
      final mealType = mealTypes[index];
      final basePool = _filterCatalogForMeal(catalog, mealType);
      final recentIds = recentIdsByMealType[mealType] ?? const <int>{};
      final pool = _expandPoolForVariety(
        mealType,
        basePool,
        catalog,
        recentIds,
      );
      final fallback = pool.isNotEmpty ? pool.first : catalog.first;
      final pick = _pickFoodUnique(
        pool.isNotEmpty ? pool : catalog,
        seed + (index * 11),
        used,
        recentIds,
        fallback,
      );
      items.add(
        MealItem(
          id: '${date.millisecondsSinceEpoch}-${mealType.name}-$index',
          foodItemId: pick.id,
          grams: _portionForMealType(mealType),
          mealType: mealType,
        ),
      );
    }

    final totals = _rebalanceService.computeTotals(items, catalog);
    return DayPlan(
      date: date,
      items: items,
      totals: totals,
      validationStatus: ValidationStatus.pending,
      suggestions: const [],
    );
  }

  List<FoodItem> _expandPoolForVariety(
    MealType mealType,
    List<FoodItem> basePool,
    List<FoodItem> catalog,
    Set<int> recent,
  ) {
    if (basePool.isEmpty) return catalog;

    final hasFresh = basePool.any((food) => !recent.contains(food.id));
    if (hasFresh) return basePool;

    if (mealType == MealType.snack) {
      final breakfastPool = _filterCatalogForMeal(catalog, MealType.breakfast);
      if (breakfastPool.any((food) => !recent.contains(food.id))) {
        return breakfastPool;
      }
    }

    final catalogHasFresh = catalog.any((food) => !recent.contains(food.id));
    if (catalogHasFresh) return catalog;

    return basePool;
  }

  List<MealType> _mealTypesForCalories(double calories) {
    if (calories <= 0) {
      return const [MealType.breakfast, MealType.lunch, MealType.dinner];
    }

    if (calories < 1600) {
      return const [MealType.breakfast, MealType.lunch, MealType.dinner];
    }

    if (calories < 2200) {
      return const [
        MealType.breakfast,
        MealType.lunch,
        MealType.snack,
        MealType.dinner,
      ];
    }

    return const [
      MealType.breakfast,
      MealType.lunch,
      MealType.snack,
      MealType.dinner,
      MealType.beverage,
    ];
  }

  double _portionForMealType(MealType mealType) {
    return switch (mealType) {
      MealType.breakfast => 160,
      MealType.lunch => 190,
      MealType.dinner => 180,
      MealType.snack => 90,
      MealType.beverage => 120,
    };
  }
}
