import '../../core/constants/nutrition_constants.dart';
import '../../domain/models/day_plan.dart';
import '../../domain/models/day_validation_result.dart';
import '../../domain/models/nutritional_goals.dart';

class DayValidationService {
  DayValidationResult validateDay(DayPlan dayPlan, NutritionalGoals goals) {
    final t = dayPlan.totals;
    final errors = <String>[];

    if (!_inRange(
        t.calories,
        goals.calories,
        NutritionConstants.caloriesMinRatio,
        NutritionConstants.caloriesMaxRatio)) {
      errors.add('Calorias fuera de rango');
    }

    if (!_inRange(
        t.proteinG,
        goals.proteinG,
        NutritionConstants.proteinMinRatio,
        NutritionConstants.proteinMaxRatio)) {
      errors.add('Proteina fuera de rango');
    }

    if (!_inRange(t.carbsG, goals.carbsG, NutritionConstants.carbsMinRatio,
        NutritionConstants.carbsMaxRatio)) {
      errors.add('Carbohidratos fuera de rango');
    }

    if (!_inRange(t.fatG, goals.fatG, NutritionConstants.fatMinRatio,
        NutritionConstants.fatMaxRatio)) {
      errors.add('Grasas fuera de rango');
    }

    if (t.fiberG < goals.fiberG * NutritionConstants.microsMinRatio) {
      errors.add('Fibra insuficiente');
    }
    if (t.ironMg < goals.ironMg * NutritionConstants.microsMinRatio) {
      errors.add('Hierro insuficiente');
    }
    if (t.calciumMg < goals.calciumMg * NutritionConstants.calciumMinRatio) {
      errors.add('Calcio insuficiente');
    }
    if (t.zincMg < goals.zincMg * NutritionConstants.microsMinRatio) {
      errors.add('Zinc insuficiente');
    }
    if (t.b12Mcg < goals.b12Mcg * NutritionConstants.microsMinRatio) {
      errors.add('B12 insuficiente');
    }

    return DayValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  bool _inRange(double value, double target, double minRatio, double maxRatio) {
    return value >= target * minRatio && value <= target * maxRatio;
  }
}
