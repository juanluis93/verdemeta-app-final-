import 'planner_types.dart';

class MealItem {
  final String id;
  final int foodItemId;
  final double grams;
  final MealType mealType;

  const MealItem({
    required this.id,
    required this.foodItemId,
    required this.grams,
    required this.mealType,
  });

  MealItem copyWith({
    String? id,
    int? foodItemId,
    double? grams,
    MealType? mealType,
  }) {
    return MealItem(
      id: id ?? this.id,
      foodItemId: foodItemId ?? this.foodItemId,
      grams: grams ?? this.grams,
      mealType: mealType ?? this.mealType,
    );
  }
}
