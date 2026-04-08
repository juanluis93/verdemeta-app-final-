import 'planner_types.dart';

class UserProfile {
  final int id;
  final int age;
  final String sex;
  final double weightKg;
  final double heightCm;
  final double activityLevel;
  final GoalType goalType;
  final Set<String> dietaryPreferences;
  final Set<String> restrictions;

  const UserProfile({
    required this.id,
    required this.age,
    required this.sex,
    required this.weightKg,
    required this.heightCm,
    required this.activityLevel,
    required this.goalType,
    required this.dietaryPreferences,
    required this.restrictions,
  });

  UserProfile copyWith({
    int? id,
    int? age,
    String? sex,
    double? weightKg,
    double? heightCm,
    double? activityLevel,
    GoalType? goalType,
    Set<String>? dietaryPreferences,
    Set<String>? restrictions,
  }) {
    return UserProfile(
      id: id ?? this.id,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      activityLevel: activityLevel ?? this.activityLevel,
      goalType: goalType ?? this.goalType,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      restrictions: restrictions ?? this.restrictions,
    );
  }
}
