import '../../domain/models/month_plan.dart';

abstract class MonthPlanRepository {
  Future<MonthPlan?> getMonthPlan(int year, int month, int userId);
  Future<void> saveMonthPlan(MonthPlan plan);
}

class InMemoryMonthPlanRepository implements MonthPlanRepository {
  final Map<String, MonthPlan> _store = {};

  String _key(int year, int month, int userId) => '$userId-$year-$month';

  @override
  Future<MonthPlan?> getMonthPlan(int year, int month, int userId) async {
    return _store[_key(year, month, userId)];
  }

  @override
  Future<void> saveMonthPlan(MonthPlan plan) async {
    _store[_key(plan.year, plan.month, plan.userId)] = plan;
  }
}
