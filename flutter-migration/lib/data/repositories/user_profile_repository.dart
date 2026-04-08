import '../../domain/models/planner_types.dart';
import '../../domain/models/user_profile.dart';

abstract class UserProfileRepository {
  Future<UserProfile> getCurrentProfile();
}

class LocalUserProfileRepository implements UserProfileRepository {
  @override
  Future<UserProfile> getCurrentProfile() async {
    return const UserProfile(
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
  }
}
