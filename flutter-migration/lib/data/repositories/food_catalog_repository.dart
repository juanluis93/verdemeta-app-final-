import '../../domain/models/food_item.dart';
import '../../domain/models/nutritional_goals.dart';
import '../../models/food_models.dart';
import '../../repositories/food_repository.dart';

abstract class FoodCatalogRepository {
  Future<List<FoodItem>> getFoodCatalog();
}

class SqlFoodCatalogRepository implements FoodCatalogRepository {
  final UserSessionRepository _foodRepository;

  SqlFoodCatalogRepository({UserSessionRepository? foodRepository})
      : _foodRepository = foodRepository ?? FoodRepository();

  @override
  Future<List<FoodItem>> getFoodCatalog() async {
    final foods = await _foodRepository.getAllFoods();

    return foods
        .where((food) => food.id != null)
        .map(_toDomainFood)
        .toList(growable: false);
  }

  FoodItem _toDomainFood(Food food) {
    return FoodItem(
      id: food.id!,
      name: food.name,
      emoji: food.emoji.isEmpty ? '🍽️' : food.emoji,
      tags: {
        if (food.isQuickFood) 'rapido',
      },
      per100: NutritionalGoals(
        calories: food.calories,
        proteinG: food.protein,
        carbsG: food.carbs,
        fatG: food.fat,
        fiberG: food.fiber,
        ironMg: food.iron,
        calciumMg: food.calcium,
        zincMg: food.zinc,
        b12Mcg: food.b12,
      ),
    );
  }
}

class LocalFoodCatalogRepository implements FoodCatalogRepository {
  @override
  Future<List<FoodItem>> getFoodCatalog() async {
    return const [
      FoodItem(
        id: 1,
        name: 'Tofu firme',
        emoji: '🧊',
        tags: {'rapido', 'economico', 'vegetariano'},
        per100: NutritionalGoals(
          calories: 80,
          proteinG: 8.5,
          carbsG: 1.9,
          fatG: 4.8,
          fiberG: 0.6,
          ironMg: 1.4,
          calciumMg: 350,
          zincMg: 1.0,
          b12Mcg: 0,
        ),
      ),
      FoodItem(
        id: 2,
        name: 'Lentejas cocidas',
        emoji: '🫘',
        tags: {'economico', 'vegetariano'},
        per100: NutritionalGoals(
          calories: 116,
          proteinG: 9,
          carbsG: 20,
          fatG: 0.4,
          fiberG: 8,
          ironMg: 3.3,
          calciumMg: 19,
          zincMg: 1.3,
          b12Mcg: 0,
        ),
      ),
      FoodItem(
        id: 3,
        name: 'Avena',
        emoji: '🥣',
        tags: {'economico', 'rapido', 'vegetariano'},
        per100: NutritionalGoals(
          calories: 389,
          proteinG: 17,
          carbsG: 66,
          fatG: 7,
          fiberG: 10,
          ironMg: 4.7,
          calciumMg: 54,
          zincMg: 4,
          b12Mcg: 0,
        ),
      ),
      FoodItem(
        id: 4,
        name: 'Bebida vegetal fortificada',
        emoji: '🥛',
        tags: {'rapido', 'sin lactosa', 'vegetariano'},
        per100: NutritionalGoals(
          calories: 45,
          proteinG: 3.3,
          carbsG: 2.5,
          fatG: 1.8,
          fiberG: 0.5,
          ironMg: 0.6,
          calciumMg: 120,
          zincMg: 0.5,
          b12Mcg: 0.4,
        ),
      ),
      FoodItem(
        id: 5,
        name: 'Quinoa cocida',
        emoji: '🌾',
        tags: {'vegetariano'},
        per100: NutritionalGoals(
          calories: 120,
          proteinG: 4.4,
          carbsG: 21.3,
          fatG: 1.9,
          fiberG: 2.8,
          ironMg: 1.5,
          calciumMg: 17,
          zincMg: 1.1,
          b12Mcg: 0,
        ),
      ),
    ];
  }
}
