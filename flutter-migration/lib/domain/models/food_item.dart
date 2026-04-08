import 'nutritional_goals.dart';

class FoodItem {
  final int id;
  final String name;
  final String emoji;
  final Set<String> tags;
  final NutritionalGoals per100;

  const FoodItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.tags,
    required this.per100,
  });

  FoodItem copyWith({
    int? id,
    String? name,
    String? emoji,
    Set<String>? tags,
    NutritionalGoals? per100,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      tags: tags ?? this.tags,
      per100: per100 ?? this.per100,
    );
  }

  NutritionalGoals forGrams(double grams) {
    final factor = grams / 100;
    return NutritionalGoals(
      calories: per100.calories * factor,
      proteinG: per100.proteinG * factor,
      carbsG: per100.carbsG * factor,
      fatG: per100.fatG * factor,
      fiberG: per100.fiberG * factor,
      ironMg: per100.ironMg * factor,
      calciumMg: per100.calciumMg * factor,
      zincMg: per100.zincMg * factor,
      b12Mcg: per100.b12Mcg * factor,
    );
  }
}
