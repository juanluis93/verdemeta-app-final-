import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/food_repository.dart';
import '../../services/daily_macro_notification_service.dart';
import '../../services/food_name_translator.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FoodRepository(),
);

final userSessionFactoryProvider = Provider<UserSessionFactory>(
  (ref) => FoodRepositorySessionFactory(),
);

final macroNotificationServiceProvider = Provider<MacroNotificationService>(
  (ref) => const DefaultDailyMacroNotificationService(),
);

final foodNameTranslationServiceProvider =
    Provider<FoodNameTranslationService>(
  (ref) => const DefaultFoodNameTranslationService(),
);
