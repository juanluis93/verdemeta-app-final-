/// ═══════════════════════════════════════════════════
/// MODELO: Food (Alimento)
/// Representa un alimento en la base de datos
/// ═══════════════════════════════════════════════════
library;

import 'dart:convert';

class HealthCondition {
  final int id;
  final String nombre;
  final String descripcion;
  final double ajusteCalorias;
  final double ajusteProteinas;
  final double ajusteCarbohidratos;
  final double ajusteGrasas;

  const HealthCondition({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.ajusteCalorias,
    required this.ajusteProteinas,
    required this.ajusteCarbohidratos,
    required this.ajusteGrasas,
  });

  factory HealthCondition.fromMap(Map<String, dynamic> map) {
    return HealthCondition(
      id: map['id'] as int,
      nombre: (map['nombre'] as String?) ?? '',
      descripcion: (map['descripcion'] as String?) ?? '',
      ajusteCalorias: (map['ajuste_calorias'] as num?)?.toDouble() ?? 0,
      ajusteProteinas: (map['ajuste_proteinas'] as num?)?.toDouble() ?? 0,
      ajusteCarbohidratos:
          (map['ajuste_carbohidratos'] as num?)?.toDouble() ?? 0,
      ajusteGrasas: (map['ajuste_grasas'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Food {
  final int? id;
  final String name;
  final String emoji;

  // Macronutrientes (por 100g)
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  // Micronutrientes (por 100g)
  final double fiber;
  final double sugar;
  final double iron;
  final double calcium;
  final double b12;
  final double zinc;

  // Metadata
  final bool isQuickFood;
  final int createdAt;

  Food({
    this.id,
    required this.name,
    this.emoji = '🍽️',
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.iron = 0,
    this.calcium = 0,
    this.b12 = 0,
    this.zinc = 0,
    this.isQuickFood = false,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

  /// Crea Food desde un Map (desde base de datos)
  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      id: map['id'] as int?,
      name: map['name'] as String,
      emoji: map['emoji'] as String? ?? '🍽️',
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      fiber: (map['fiber'] as num?)?.toDouble() ?? 0,
      sugar: (map['sugar'] as num?)?.toDouble() ?? 0,
      iron: (map['iron'] as num?)?.toDouble() ?? 0,
      calcium: (map['calcium'] as num?)?.toDouble() ?? 0,
      b12: (map['b12'] as num?)?.toDouble() ?? 0,
      zinc: (map['zinc'] as num?)?.toDouble() ?? 0,
      isQuickFood: (map['is_quick_food'] as int?) == 1,
      createdAt: map['created_at'] as int?,
    );
  }

  /// Convierte Food a Map (para base de datos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'iron': iron,
      'calcium': calcium,
      'b12': b12,
      'zinc': zinc,
      'is_quick_food': isQuickFood ? 1 : 0,
      'created_at': createdAt,
    };
  }

  /// Calcula macros para una cantidad específica
  NutritionInfo calculateForQuantity(double grams) {
    final factor = grams / 100;
    return NutritionInfo(
      calories: calories * factor,
      protein: protein * factor,
      carbs: carbs * factor,
      fat: fat * factor,
      fiber: fiber * factor,
      sugar: sugar * factor,
      iron: iron * factor,
      calcium: calcium * factor,
      b12: b12 * factor,
      zinc: zinc * factor,
    );
  }

  @override
  String toString() =>
      '$emoji $name (${calories.toStringAsFixed(0)} kcal/100g)';
}

/// ═══════════════════════════════════════════════════
/// MODELO: FoodLogEntry (Registro de alimento consumido)
/// ═══════════════════════════════════════════════════

class FoodLogEntry {
  final int? id;
  final int? foodId; // Puede ser null si es alimento personalizado/IA
  final String foodName;
  final String mealTime; // 'Desayuno', 'Almuerzo', 'Cena', 'Merienda'

  final double quantity; // gramos/ml consumidos

  // Macros consumidos (ya calculados)
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  // Micros consumidos
  final double fiber;
  final double sugar;
  final double iron;
  final double calcium;
  final double b12;
  final double zinc;

  // Metadata
  final bool isAiEstimated;
  final int loggedAt;
  final String date; // YYYY-MM-DD

  FoodLogEntry({
    this.id,
    this.foodId,
    required this.foodName,
    required this.mealTime,
    required this.quantity,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.iron = 0,
    this.calcium = 0,
    this.b12 = 0,
    this.zinc = 0,
    this.isAiEstimated = false,
    int? loggedAt,
    String? date,
  })  : loggedAt = loggedAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        date = date ?? DateTime.now().toIso8601String().split('T')[0];

  factory FoodLogEntry.fromMap(Map<String, dynamic> map) {
    return FoodLogEntry(
      id: map['id'] as int?,
      foodId: map['food_id'] as int?,
      foodName: map['food_name'] as String,
      mealTime: map['meal_time'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      fiber: (map['fiber'] as num?)?.toDouble() ?? 0,
      sugar: (map['sugar'] as num?)?.toDouble() ?? 0,
      iron: (map['iron'] as num?)?.toDouble() ?? 0,
      calcium: (map['calcium'] as num?)?.toDouble() ?? 0,
      b12: (map['b12'] as num?)?.toDouble() ?? 0,
      zinc: (map['zinc'] as num?)?.toDouble() ?? 0,
      isAiEstimated: (map['is_ai_estimated'] as int?) == 1,
      loggedAt: map['logged_at'] as int?,
      date: map['date'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'food_id': foodId,
      'food_name': foodName,
      'meal_time': mealTime,
      'quantity': quantity,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'iron': iron,
      'calcium': calcium,
      'b12': b12,
      'zinc': zinc,
      'is_ai_estimated': isAiEstimated ? 1 : 0,
      'logged_at': loggedAt,
      'date': date,
    };
  }

  /// Crea un registro desde un Food y cantidad
  factory FoodLogEntry.fromFood({
    required Food food,
    required double quantity,
    required String mealTime,
    bool isAiEstimated = false,
  }) {
    final nutrition = food.calculateForQuantity(quantity);
    return FoodLogEntry(
      foodId: food.id,
      foodName: food.name,
      mealTime: mealTime,
      quantity: quantity,
      calories: nutrition.calories,
      protein: nutrition.protein,
      carbs: nutrition.carbs,
      fat: nutrition.fat,
      fiber: nutrition.fiber,
      sugar: nutrition.sugar,
      iron: nutrition.iron,
      calcium: nutrition.calcium,
      b12: nutrition.b12,
      zinc: nutrition.zinc,
      isAiEstimated: isAiEstimated,
    );
  }
}

/// ═══════════════════════════════════════════════════
/// MODELO: UserAccount (Cuenta local para login)
/// ═══════════════════════════════════════════════════

class UserAccount {
  final int id;
  final String username;
  final String passwordHash;
  final int createdAt;
  final int updatedAt;

  const UserAccount({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      id: map['id'] as int,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      createdAt: map['created_at'] as int? ?? 0,
      updatedAt: map['updated_at'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

/// ═══════════════════════════════════════════════════
/// MODELO: UserProfile (Perfil del usuario)
/// ═══════════════════════════════════════════════════

class UserProfile {
  final int? id;
  final String name;
  final int age;
  final String gender; // 'male', 'female', 'other'
  final double weight; // kg
  final double height; // cm
  final double activityLevel; // 1.2 - 1.9
  final String goal; // 'deficit', 'maintain', 'gain', 'health'
  final List<int> diseaseIds;

  // Medidas corporales
  final double? waist;
  final double? neck;
  final double? hip;
  final double? thigh;
  final double? arm;
  final double? calf;

  // Metas calculadas
  final double calorieTarget;
  final double proteinTarget;
  final double carbsTarget;
  final double fatTarget;

  // Composición corporal estimada
  final double? bodyFatPct;
  final double? musclePct;
  final double? leanBodyMass;
  final double? muscleMass;
  final double? boneMass;
  final double? waterMass;

  final int createdAt;
  final int updatedAt;

  UserProfile({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.weight,
    required this.height,
    this.activityLevel = 1.55,
    required this.goal,
    this.diseaseIds = const [],
    this.waist,
    this.neck,
    this.hip,
    this.thigh,
    this.arm,
    this.calf,
    required this.calorieTarget,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
    this.bodyFatPct,
    this.musclePct,
    this.leanBodyMass,
    this.muscleMass,
    this.boneMass,
    this.waterMass,
    int? createdAt,
    int? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      name: map['name'] as String,
      age: map['age'] as int,
      gender: map['gender'] as String,
      weight: (map['weight'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      activityLevel: (map['activity_level'] as num?)?.toDouble() ?? 1.55,
      goal: map['goal'] as String,
      diseaseIds: _parseDiseaseIds(map['selected_disease_ids']),
      waist: (map['waist'] as num?)?.toDouble(),
      neck: (map['neck'] as num?)?.toDouble(),
      hip: (map['hip'] as num?)?.toDouble(),
      thigh: (map['thigh'] as num?)?.toDouble(),
      arm: (map['arm'] as num?)?.toDouble(),
      calf: (map['calf'] as num?)?.toDouble(),
      calorieTarget: (map['calorie_target'] as num).toDouble(),
      proteinTarget: (map['protein_target'] as num).toDouble(),
      carbsTarget: (map['carbs_target'] as num).toDouble(),
      fatTarget: (map['fat_target'] as num).toDouble(),
      bodyFatPct: (map['body_fat_pct'] as num?)?.toDouble(),
      musclePct: (map['muscle_pct'] as num?)?.toDouble(),
      leanBodyMass: (map['lean_body_mass'] as num?)?.toDouble(),
      muscleMass: (map['muscle_mass'] as num?)?.toDouble(),
      boneMass: (map['bone_mass'] as num?)?.toDouble(),
      waterMass: (map['water_mass'] as num?)?.toDouble(),
      createdAt: map['created_at'] as int?,
      updatedAt: map['updated_at'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'weight': weight,
      'height': height,
      'activity_level': activityLevel,
      'goal': goal,
      'selected_disease_ids': jsonEncode(diseaseIds),
      'waist': waist,
      'neck': neck,
      'hip': hip,
      'thigh': thigh,
      'arm': arm,
      'calf': calf,
      'calorie_target': calorieTarget,
      'protein_target': proteinTarget,
      'carbs_target': carbsTarget,
      'fat_target': fatTarget,
      'body_fat_pct': bodyFatPct,
      'muscle_pct': musclePct,
      'lean_body_mass': leanBodyMass,
      'muscle_mass': muscleMass,
      'bone_mass': boneMass,
      'water_mass': waterMass,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  static List<int> _parseDiseaseIds(dynamic raw) {
    if (raw == null) return const [];

    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map((e) => e is num ? e.toInt() : int.tryParse('$e'))
              .whereType<int>()
              .toSet()
              .toList();
        }
      } catch (_) {
        return const [];
      }
    }

    return const [];
  }
}

/// ═══════════════════════════════════════════════════
/// HELPER: NutritionInfo (Info nutricional calculada)
/// ═══════════════════════════════════════════════════

class NutritionInfo {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double iron;
  final double calcium;
  final double b12;
  final double zinc;

  NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.iron = 0,
    this.calcium = 0,
    this.b12 = 0,
    this.zinc = 0,
  });

  /// Suma múltiples NutritionInfo
  NutritionInfo operator +(NutritionInfo other) {
    return NutritionInfo(
      calories: calories + other.calories,
      protein: protein + other.protein,
      carbs: carbs + other.carbs,
      fat: fat + other.fat,
      fiber: fiber + other.fiber,
      sugar: sugar + other.sugar,
      iron: iron + other.iron,
      calcium: calcium + other.calcium,
      b12: b12 + other.b12,
      zinc: zinc + other.zinc,
    );
  }
}

/// ═══════════════════════════════════════════════════
/// MODELO: ProfileRecord (Historial de medidas)
/// ═══════════════════════════════════════════════════

class ProfileRecord {
  final int? id;
  final int userId;
  final String goal;
  final double weight;
  final double height;
  final double? waist;
  final double? neck;
  final double? hip;
  final double? thigh;
  final double? arm;
  final double? calf;
  final double? bodyFatPct;
  final double? muscleMass;
  final int recordedAt;
  final bool isBaseline;

  const ProfileRecord({
    this.id,
    required this.userId,
    required this.goal,
    required this.weight,
    required this.height,
    this.waist,
    this.neck,
    this.hip,
    this.thigh,
    this.arm,
    this.calf,
    this.bodyFatPct,
    this.muscleMass,
    required this.recordedAt,
    this.isBaseline = false,
  });

  factory ProfileRecord.fromMap(Map<String, dynamic> map) {
    return ProfileRecord(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      goal: map['goal'] as String,
      weight: (map['weight'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      waist: (map['waist'] as num?)?.toDouble(),
      neck: (map['neck'] as num?)?.toDouble(),
      hip: (map['hip'] as num?)?.toDouble(),
      thigh: (map['thigh'] as num?)?.toDouble(),
      arm: (map['arm'] as num?)?.toDouble(),
      calf: (map['calf'] as num?)?.toDouble(),
      bodyFatPct: (map['body_fat_pct'] as num?)?.toDouble(),
      muscleMass: (map['muscle_mass'] as num?)?.toDouble(),
      recordedAt: map['recorded_at'] as int? ?? 0,
      isBaseline: (map['is_baseline'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'goal': goal,
      'weight': weight,
      'height': height,
      'waist': waist,
      'neck': neck,
      'hip': hip,
      'thigh': thigh,
      'arm': arm,
      'calf': calf,
      'body_fat_pct': bodyFatPct,
      'muscle_mass': muscleMass,
      'recorded_at': recordedAt,
      'is_baseline': isBaseline ? 1 : 0,
    };
  }
}

/// Resultado del guardado de perfil para feedback de progreso.
class ProfileSaveResult {
  final bool isInitialRecord;
  final bool recordCreated;
  final String progressStatus;

  const ProfileSaveResult({
    required this.isInitialRecord,
    required this.recordCreated,
    required this.progressStatus,
  });
}
