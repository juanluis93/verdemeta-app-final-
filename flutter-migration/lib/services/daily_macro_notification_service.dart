<<<<<<< HEAD
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/food_models.dart';

class DailyMacroNotificationService {
  static const int _notificationId = 1001;
  static const String _channelId = 'daily_macro_summary_channel';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      'Daily Macro Summary',
      description: 'Daily end-of-day macronutrient performance summary',
      importance: Importance.high,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  static Future<bool> requestPermissionIfNeeded() async {
    if (kIsWeb) return false;
    await initialize();

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    return await androidPlugin?.requestNotificationsPermission() ?? true;
  }

  static Future<void> scheduleEndOfDaySummary({
    required bool isSpanish,
    required NutritionInfo totals,
    required UserProfile? profile,
    int hour = 21,
    int minute = 0,
  }) async {
    if (kIsWeb) return;
    await initialize();

    final now = DateTime.now();
    final scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    if (!scheduledDate.isAfter(now)) {
      await cancelEndOfDaySummary();
      return;
    }

    final proteinTarget = profile?.proteinTarget ?? 120.0;
    final carbsTarget = profile?.carbsTarget ?? 220.0;
    final fatTarget = profile?.fatTarget ?? 70.0;

    String formatMacro(String label, double current, double target) {
      final pct = target <= 0 ? 0 : ((current / target) * 100).round();
      return '$label ${current.toStringAsFixed(0)}/${target.toStringAsFixed(0)} g ($pct%)';
    }

    final proteinPct =
        proteinTarget <= 0 ? 0 : (totals.protein / proteinTarget);
    final carbsPct = carbsTarget <= 0 ? 0 : (totals.carbs / carbsTarget);
    final fatPct = fatTarget <= 0 ? 0 : (totals.fat / fatTarget);
    final averagePct = ((proteinPct + carbsPct + fatPct) / 3) * 100;

    final resultEmoji = averagePct >= 95
        ? 'Excelente'
        : averagePct >= 75
            ? 'Bien'
            : 'A mejorar';

    final title = isSpanish
        ? 'Resumen de macros del dia: $resultEmoji'
        : 'Daily macro summary: $resultEmoji';

    final body = isSpanish
        ? '${formatMacro('P', totals.protein, proteinTarget)} | ${formatMacro('C', totals.carbs, carbsTarget)} | ${formatMacro('G', totals.fat, fatTarget)}'
        : '${formatMacro('P', totals.protein, proteinTarget)} | ${formatMacro('C', totals.carbs, carbsTarget)} | ${formatMacro('F', totals.fat, fatTarget)}';

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Daily Macro Summary',
        channelDescription:
            'Daily end-of-day macronutrient performance summary',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(body),
      ),
    );

    await _plugin.zonedSchedule(
      _notificationId,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelEndOfDaySummary() async {
    if (kIsWeb) return;
    await initialize();
    await _plugin.cancel(_notificationId);
  }
=======
class DailyMacroNotificationService {
  static Future<void> initialize() async {
    // Placeholder service: keeps app flow stable until full notifications are reintroduced.
  }

  static Future<bool> requestPermissionIfNeeded() async {
    return true;
  }

  static Future<void> cancelEndOfDaySummary() async {}

  static Future<void> scheduleEndOfDaySummary({
    required bool isSpanish,
    required dynamic totals,
    required dynamic profile,
  }) async {}
>>>>>>> b9d1389 (fix: restaurar servicio de notificaciones y habilitar desugaring android)
}
