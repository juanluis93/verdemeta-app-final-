import '../../domain/models/planner_types.dart';
import '../../domain/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class UserProfileRepository {
  Future<UserProfile> getCurrentProfile();
  Future<void> saveCurrentProfile(UserProfile profile);
}

class LocalUserProfileRepository implements UserProfileRepository {
  static const _undesiredFoodsKey = 'planner_undesired_food_ids';

  UserProfile _profile = const UserProfile(
    id: 1,
    age: 30,
    sex: 'female',
    weightKg: 67,
    heightCm: 168,
    activityLevel: 1.55,
    goalType: GoalType.maintain,
    dietaryPreferences: {'vegetariano'},
    restrictions: {'sin lactosa'},
  );

  @override
  Future<UserProfile> getCurrentProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final rawIds = prefs.getStringList(_undesiredFoodsKey) ?? const [];
    final parsedIds = rawIds
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toSet();
    _profile = _profile.copyWith(undesiredFoodIds: parsedIds);
    return _profile;
  }

  @override
  Future<void> saveCurrentProfile(UserProfile profile) async {
    _profile = profile;
    final prefs = await SharedPreferences.getInstance();
    final ids = profile.undesiredFoodIds.map((id) => id.toString()).toList();
    await prefs.setStringList(_undesiredFoodsKey, ids);
  }
}
