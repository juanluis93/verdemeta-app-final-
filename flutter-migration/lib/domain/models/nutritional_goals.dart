class NutritionalGoals {
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final double ironMg;
  final double calciumMg;
  final double zincMg;
  final double b12Mcg;

  const NutritionalGoals({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.ironMg,
    required this.calciumMg,
    required this.zincMg,
    required this.b12Mcg,
  });

  const NutritionalGoals.zero()
      : calories = 0,
        proteinG = 0,
        carbsG = 0,
        fatG = 0,
        fiberG = 0,
        ironMg = 0,
        calciumMg = 0,
        zincMg = 0,
        b12Mcg = 0;

  NutritionalGoals copyWith({
    double? calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
    double? fiberG,
    double? ironMg,
    double? calciumMg,
    double? zincMg,
    double? b12Mcg,
  }) {
    return NutritionalGoals(
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      fiberG: fiberG ?? this.fiberG,
      ironMg: ironMg ?? this.ironMg,
      calciumMg: calciumMg ?? this.calciumMg,
      zincMg: zincMg ?? this.zincMg,
      b12Mcg: b12Mcg ?? this.b12Mcg,
    );
  }

  NutritionalGoals operator +(NutritionalGoals other) {
    return NutritionalGoals(
      calories: calories + other.calories,
      proteinG: proteinG + other.proteinG,
      carbsG: carbsG + other.carbsG,
      fatG: fatG + other.fatG,
      fiberG: fiberG + other.fiberG,
      ironMg: ironMg + other.ironMg,
      calciumMg: calciumMg + other.calciumMg,
      zincMg: zincMg + other.zincMg,
      b12Mcg: b12Mcg + other.b12Mcg,
    );
  }
}
