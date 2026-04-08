import 'day_plan.dart';

class MonthPlan {
  final int year;
  final int month;
  final int userId;
  final List<DayPlan> dayPlans;
  final bool isLockedForPublish;
  final DateTime updatedAt;

  const MonthPlan({
    required this.year,
    required this.month,
    required this.userId,
    required this.dayPlans,
    required this.isLockedForPublish,
    required this.updatedAt,
  });

  MonthPlan copyWith({
    int? year,
    int? month,
    int? userId,
    List<DayPlan>? dayPlans,
    bool? isLockedForPublish,
    DateTime? updatedAt,
  }) {
    return MonthPlan(
      year: year ?? this.year,
      month: month ?? this.month,
      userId: userId ?? this.userId,
      dayPlans: dayPlans ?? this.dayPlans,
      isLockedForPublish: isLockedForPublish ?? this.isLockedForPublish,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
