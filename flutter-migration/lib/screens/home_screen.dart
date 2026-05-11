import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/food_models.dart';
import '../models/shop_models.dart';
import '../repositories/food_repository.dart';
import '../services/daily_macro_notification_service.dart';
import '../widgets/food_logger_sheet.dart';
import '../presentation/screens/planificar_home_screen.dart';
import '../presentation/screens/recipe_today_screen.dart';
import 'profile_measurements_screen.dart';
import 'shop_screen.dart';
import 'package:fl_chart/fl_chart.dart';

enum _HomeMenuAction { settings, feedback, measurements, logout }

class _PlannerRequest {
  final int year;
  final int month;
  final bool prioritizeQuickFoods;
  final bool manualMode;

  const _PlannerRequest({
    required this.year,
    required this.month,
    required this.prioritizeQuickFoods,
    required this.manualMode,
  });
}

class _PlannerValidationResult {
  final bool isValid;
  final List<String> suggestions;

  const _PlannerValidationResult({
    required this.isValid,
    required this.suggestions,
  });
}

class _PlannedMealItem {
  final String mealKey;
  final Food food;
  final double grams;

  const _PlannedMealItem({
    required this.mealKey,
    required this.food,
    required this.grams,
  });

  NutritionInfo get nutrition => food.calculateForQuantity(grams);

  Map<String, dynamic> toMap() {
    return {
      'meal_key': mealKey,
      'grams': grams,
      'food': {
        'id': food.id,
        'name': food.name,
        'emoji': food.emoji,
        'calories': food.calories,
        'protein': food.protein,
        'carbs': food.carbs,
        'fat': food.fat,
        'fiber': food.fiber,
        'sugar': food.sugar,
        'iron': food.iron,
        'calcium': food.calcium,
        'b12': food.b12,
        'zinc': food.zinc,
        'is_quick_food': food.isQuickFood ? 1 : 0,
        'created_at': food.createdAt,
      },
    };
  }

  factory _PlannedMealItem.fromMap(Map<String, dynamic> map) {
    final foodMap = Map<String, dynamic>.from(map['food'] as Map);
    return _PlannedMealItem(
      mealKey: map['meal_key'] as String,
      grams: (map['grams'] as num).toDouble(),
      food: Food.fromMap(foodMap),
    );
  }
}

class _DailyDietPlan {
  final DateTime date;
  final List<_PlannedMealItem> items;
  final NutritionInfo totals;

  const _DailyDietPlan({
    required this.date,
    required this.items,
    required this.totals,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
    };
  }

  factory _DailyDietPlan.fromMap(Map<String, dynamic> map) {
    final itemsRaw = (map['items'] as List<dynamic>? ?? const []);
    final items = itemsRaw
        .map(
            (item) => _PlannedMealItem.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    var totals = NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0);
    for (final item in items) {
      totals = totals + item.nutrition;
    }

    return _DailyDietPlan(
      date: DateTime.parse(map['date'] as String),
      items: items,
      totals: totals,
    );
  }
}

class _MonthlyDietPlan {
  final int year;
  final int month;
  final double targetCalories;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;
  final List<_DailyDietPlan> days;

  const _MonthlyDietPlan({
    required this.year,
    required this.month,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
    required this.days,
  });

  int get dayCount => days.length;

  NutritionInfo get averageTotals {
    if (days.isEmpty) {
      return NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0);
    }

    var combined = NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0);
    for (final day in days) {
      combined = combined + day.totals;
    }

    final divisor = days.length;
    return NutritionInfo(
      calories: combined.calories / divisor,
      protein: combined.protein / divisor,
      carbs: combined.carbs / divisor,
      fat: combined.fat / divisor,
      fiber: combined.fiber / divisor,
      sugar: combined.sugar / divisor,
      iron: combined.iron / divisor,
      calcium: combined.calcium / divisor,
      b12: combined.b12 / divisor,
      zinc: combined.zinc / divisor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'year': year,
      'month': month,
      'target_calories': targetCalories,
      'target_protein': targetProtein,
      'target_carbs': targetCarbs,
      'target_fat': targetFat,
      'days': days.map((day) => day.toMap()).toList(),
    };
  }

  factory _MonthlyDietPlan.fromMap(Map<String, dynamic> map) {
    final daysRaw = (map['days'] as List<dynamic>? ?? const []);
    final days = daysRaw
        .map((day) => _DailyDietPlan.fromMap(Map<String, dynamic>.from(day)))
        .toList();

    return _MonthlyDietPlan(
      year: map['year'] as int,
      month: map['month'] as int,
      targetCalories: (map['target_calories'] as num).toDouble(),
      targetProtein: (map['target_protein'] as num).toDouble(),
      targetCarbs: (map['target_carbs'] as num).toDouble(),
      targetFat: (map['target_fat'] as num).toDouble(),
      days: days,
    );
  }
}

class _RecipeDetail {
  final String subtitle;
  final List<String> ingredients;
  final List<String> steps;

  const _RecipeDetail({
    required this.subtitle,
    required this.ingredients,
    required this.steps,
  });
}

class HomeScreen extends StatefulWidget {
  final FoodRepository repository;
  final Future<void> Function(BuildContext context) onLogoutRequested;
  final Locale locale;
  final ValueChanged<Locale> onLanguageChanged;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const HomeScreen({
    super.key,
    required this.repository,
    required this.onLogoutRequested,
    required this.locale,
    required this.onLanguageChanged,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _notificationsEnabledBaseKey =
      'daily_macro_notifications_enabled';
  static const _undesiredFoodsKey = 'planner_undesired_food_ids';
  static const _monthlyPlannerBaseKey = 'monthly_diet_plan_v2';
  static const _buildStamp = 'DIETA-2026-04-05-C';

  late final FoodRepository _repo;
  late Locale _currentLocale;
  late ThemeMode _currentThemeMode;

  List<Food> _quickFoods = [];
  List<Food> _allFoods = [];
  List<FoodLogEntry> _todayLog = [];
  Map<int, String> _emojiByFoodId = {};
  Map<String, String> _emojiByFoodName = {};
  Set<int> _undesiredFoodIds = <int>{};
  int _activeSection = 0;
  String? _loadError;
  UserProfile? _profile;
  int _todayWaterCups = 0;
  bool _notificationsEnabled = true;
  NutritionInfo _todayTotals = NutritionInfo(
    calories: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
  );
  bool _loading = true;
  Timer? _dayChangeTimer;
  String _lastLoadedDayKey = '';
  List<double> _weeklyCalories = [];
  List<int> _weeklyWater = [];
  List<String> _weeklyLabels = [];
  _MonthlyDietPlan? _monthlyDietPlan;
  bool _monthlyPlanIsValid = false;
  Map<int, List<String>> _planSuggestionsByDay = {};
  int _waterUpdateVersion = 0;
  Map<String, _RecipeDetail> _recipeDetailsByKey = {};

  bool get _isSpanish => _currentLocale.languageCode == 'es';

  String _t(String es, String en) => _isSpanish ? es : en;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _repo = widget.repository;
    _currentLocale = widget.locale;
    _currentThemeMode = widget.themeMode;
    _lastLoadedDayKey = _todayKey;
    unawaited(_restoreNotificationPreference());
    _startDayChangeWatcher();
    _loadData();
    unawaited(_loadRecipeDetails());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshIfDayChanged());
    }
  }

  @override
  void dispose() {
    _dayChangeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startDayChangeWatcher() {
    _dayChangeTimer?.cancel();
    _dayChangeTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(_refreshIfDayChanged());
    });
  }

  Future<void> _refreshIfDayChanged() async {
    if (!mounted || _loading) return;
    if (_todayKey == _lastLoadedDayKey) return;
    await _loadData();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locale != widget.locale) {
      _currentLocale = widget.locale;
    }
    if (oldWidget.themeMode != widget.themeMode) {
      _currentThemeMode = widget.themeMode;
    }
  }

  Future<void> _loadRecipeDetails() async {
    try {
      final jsonText = await rootBundle.loadString('assets/data/recipe_catalog.json');
      final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
      final details = <String, _RecipeDetail>{};

      for (final entry in decoded.entries) {
        final value = Map<String, dynamic>.from(entry.value as Map);
        details[entry.key] = _RecipeDetail(
          subtitle: value['subtitle'] as String? ?? '',
          ingredients: List<String>.from(value['ingredients'] as List<dynamic>? ?? const []),
          steps: List<String>.from(value['steps'] as List<dynamic>? ?? const []),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _recipeDetailsByKey = details;
      });
    } catch (error) {
      debugPrint('No se pudieron cargar las recetas detalladas: $error');
    }
  }

  Future<void> _loadData() async {
    final todayKey = _todayKey;
    final prefs = await SharedPreferences.getInstance();
    final rawUndesiredIds = prefs.getStringList(_undesiredFoodsKey) ?? const [];
    final undesiredFoodIds = rawUndesiredIds
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toSet();

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      await _repo.ensureDailyRollover(todayKey: todayKey);
      final quickFoods = await _repo.getQuickFoods();
      final allFoods = await _repo.getAllFoods();
      final todayLog = await _repo.getFoodLogByDate(todayKey);
      final totals = await _repo.getDailyTotals(todayKey);
      final waterCups = await _repo.getWaterIntake(todayKey);
      final profile = await _repo.getUserProfile();
      final emojiIndex = _buildEmojiIndex(allFoods);

      // Load weekly stats for charts
      final weekStats = await _repo.getDailyTotalsForDays(7);
      final List<double> weeklyCal = [];
      final List<int> weeklyWater = [];
      final List<String> weeklyLabels = [];
      final now = DateTime.now();
      final esDays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      final enDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final key = _dateKey(d);
        final stats = weekStats[key] ??
            NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0);
        weeklyCal.add(stats.calories);

        final water = await _repo.getWaterIntake(key);
        weeklyWater.add(water);
        weeklyLabels
            .add(_isSpanish ? esDays[d.weekday - 1] : enDays[d.weekday - 1]);
      }

      if (!mounted) return;
      setState(() {
        _quickFoods = quickFoods;
        _allFoods = allFoods;
        _todayLog = todayLog;
        _todayTotals = totals;
        _todayWaterCups = waterCups;
        _profile = profile;
        _undesiredFoodIds = undesiredFoodIds;
        _emojiByFoodId = emojiIndex.byId;
        _emojiByFoodName = emojiIndex.byName;
        _weeklyCalories = weeklyCal;
        _weeklyWater = weeklyWater;
        _weeklyLabels = weeklyLabels;
        _lastLoadedDayKey = todayKey;
        _loading = false;
      });

      unawaited(_restoreMonthlyPlanFromStorage());

      unawaited(_syncDailyMacroNotification());
    } catch (e) {
      if (!mounted) return;

      final fallbackFoods = kIsWeb ? _webPreviewFoods : <Food>[];
      final fallbackEmojiIndex = _buildEmojiIndex(fallbackFoods);

      setState(() {
        _quickFoods = fallbackFoods;
        _allFoods = fallbackFoods;
        _todayLog = [];
        _todayTotals = NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0);
        _todayWaterCups = 0;
        _profile = null;
        _undesiredFoodIds = undesiredFoodIds;
        _emojiByFoodId = fallbackEmojiIndex.byId;
        _emojiByFoodName = fallbackEmojiIndex.byName;
        _weeklyCalories = List.filled(7, 0.0);
        _weeklyWater = List.filled(7, 0);
        _weeklyLabels = List.generate(7, (i) => '');
        _lastLoadedDayKey = todayKey;
        _loadError = kIsWeb
            ? _t(
                'Modo vista previa web activo: SQLite no esta disponible en Chrome. Para guardado real usa Android/app nativa.',
                'Web preview mode is active: SQLite is not available in Chrome. For real persistence, use Android/native app.',
              )
            : _t(
                'No se pudieron cargar los datos: $e',
                'Could not load data: $e',
              );
        _loading = false;
      });

      unawaited(_restoreMonthlyPlanFromStorage());

      unawaited(_syncDailyMacroNotification());
    }
  }

  String get _monthlyPlannerStorageKey {
    final userId = _repo.currentUserId ?? 0;
    return '${_monthlyPlannerBaseKey}_$userId';
  }

  Future<void> _saveMonthlyPlanToStorage(_MonthlyDietPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonPayload = jsonEncode(plan.toMap());
    await prefs.setString(_monthlyPlannerStorageKey, jsonPayload);
  }

  Future<void> _restoreMonthlyPlanFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_monthlyPlannerStorageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final plan = _MonthlyDietPlan.fromMap(decoded);
      final validation = _evaluateMonthlyPlan(plan);

      if (!mounted) return;
      setState(() {
        _monthlyDietPlan = plan;
        _monthlyPlanIsValid = validation.$1;
        _planSuggestionsByDay = validation.$2;
      });
    } catch (_) {
      // Ignore malformed saved plans and keep current state.
    }
  }

  String get _notificationsPreferenceKey {
    final userId = _repo.currentUserId ?? 0;
    return '${_notificationsEnabledBaseKey}_$userId';
  }

  Future<void> _restoreNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final restored = prefs.getBool(_notificationsPreferenceKey) ?? true;

    if (!mounted) return;
    setState(() => _notificationsEnabled = restored);
    await _syncDailyMacroNotification();
  }

  Future<void> _setNotificationsEnabled(bool enabled) async {
    if (_notificationsEnabled == enabled) return;

    setState(() => _notificationsEnabled = enabled);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsPreferenceKey, enabled);

    if (enabled) {
      final granted =
          await DailyMacroNotificationService.requestPermissionIfNeeded();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                'Activa el permiso de notificaciones del sistema para recibir el resumen diario.',
                'Enable system notification permission to receive your daily summary.',
              ),
            ),
          ),
        );
      }
    }

    await _syncDailyMacroNotification();
  }

  Future<void> _syncDailyMacroNotification() async {
    if (!_notificationsEnabled) {
      await DailyMacroNotificationService.cancelEndOfDaySummary();
      return;
    }

    await DailyMacroNotificationService.scheduleEndOfDaySummary(
      isSpanish: _isSpanish,
      totals: _todayTotals,
      profile: _profile,
    );
  }

  ({Map<int, String> byId, Map<String, String> byName}) _buildEmojiIndex(
      List<Food> foods) {
    final byId = <int, String>{};
    final byName = <String, String>{};

    for (final food in foods) {
      final emoji = food.emoji.trim();
      if (emoji.isNotEmpty) {
        if (food.id != null) byId[food.id!] = emoji;
        byName[food.name.trim().toLowerCase()] = emoji;
      }
    }

    return (byId: byId, byName: byName);
  }

  String? _leadingEmoji(String value) {
    final clean = value.trimLeft();
    if (clean.isEmpty) return null;

    final firstRune = clean.runes.first;
    final looksEmoji = (firstRune >= 0x1F000 && firstRune <= 0x1FAFF) ||
        (firstRune >= 0x2600 && firstRune <= 0x27BF);
    if (!looksEmoji) return null;

    return String.fromCharCode(firstRune);
  }

  String _resolveEntryEmoji(FoodLogEntry entry) {
    if (entry.foodId != null) {
      final byId = _emojiByFoodId[entry.foodId!];
      if (byId != null && byId.isNotEmpty) return byId;
    }

    final byName = _emojiByFoodName[entry.foodName.trim().toLowerCase()];
    if (byName != null && byName.isNotEmpty) return byName;

    return _leadingEmoji(entry.foodName) ?? '🍽️';
  }

  Future<void> _openFoodLogger() async {
    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFF8FCF8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AddFoodBottomSheet(
        repository: _repo,
        fallbackFoods: _quickFoods.isNotEmpty ? _quickFoods : _webPreviewFoods,
        initialMealTime: _getCurrentMealTime(),
        excludedFoodIds: _undesiredFoodIds,
      ),
    );

    if (didSave != true || !mounted) return;

    await _loadData();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _t(
            'Comida guardada en tus registros de hoy.',
            'Meal saved in your records for today.',
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _addQuickFood(Food food) async {
    try {
      final entry = FoodLogEntry.fromFood(
        food: food,
        quantity: 100,
        mealTime: _getCurrentMealTime(),
      );

      await _repo.logFood(entry);
      await _loadData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${food.emoji} ${food.name} agregado'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Registro no disponible en este modo de vista previa.',
              'Logging is not available in this preview mode.',
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openMeasurements() async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) => ProfileMeasurementsScreen(repository: _repo),
      ),
    );

    final saved = switch (result) {
      true => true,
      {'saved': true} => true,
      _ => false,
    };

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Medidas guardadas correctamente.',
              'Measurements saved successfully.',
            ),
          ),
        ),
      );
      await _loadData();
    }
  }

  bool _isSameLogEntry(FoodLogEntry a, FoodLogEntry b) {
    if (a.id != null && b.id != null) return a.id == b.id;
    return a.loggedAt == b.loggedAt &&
        a.foodName == b.foodName &&
        a.quantity == b.quantity;
  }

  Future<void> _deleteEntryAfterDismiss({
    required FoodLogEntry entry,
    required List<FoodLogEntry> previousLog,
  }) async {
    final entryId = entry.id;
    if (entryId == null) {
      if (!mounted) return;
      setState(() => _todayLog = previousLog);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'No se pudo eliminar esta comida.',
              'This meal could not be deleted.',
            ),
          ),
        ),
      );
      return;
    }

    try {
      final deletedRows = await _repo.deleteFoodLog(entryId);
      if (deletedRows == 0) {
        if (!mounted) return;
        setState(() => _todayLog = previousLog);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                'La comida ya no existe en tu registro.',
                'The meal no longer exists in your log.',
              ),
            ),
          ),
        );
        return;
      }

      await _loadData();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('Comida eliminada.', 'Meal deleted.'),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _todayLog = previousLog);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'No se pudo eliminar la comida. Intenta de nuevo.',
              'Could not delete the meal. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _deleteEntryWithOptimisticUi(FoodLogEntry entry) async {
    final previousLog = List<FoodLogEntry>.from(_todayLog);
    setState(() {
      _todayLog.removeWhere((item) => _isSameLogEntry(item, entry));
    });

    await _deleteEntryAfterDismiss(entry: entry, previousLog: previousLog);
  }

  Future<void> _handleMenuAction(_HomeMenuAction action) async {
    switch (action) {
      case _HomeMenuAction.settings:
        await _openDisplaySettings();
        break;
      case _HomeMenuAction.feedback:
        await _openFeedbackProgress();
        break;
      case _HomeMenuAction.measurements:
        await _openMeasurements();
        break;
      case _HomeMenuAction.logout:
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(_t('Cerrar sesión', 'Sign out')),
            content: Text(
              _t(
                'Volverás al login para entrar con otro usuario.',
                'You will return to login to use another account.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(_t('Cancelar', 'Cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(_t('Salir', 'Exit')),
              ),
            ],
          ),
        );

        if (shouldLogout == true && mounted) {
          await DailyMacroNotificationService.cancelEndOfDaySummary();
          if (!mounted) return;
          await widget.onLogoutRequested(context);
        }
        break;
    }
  }

  String _dateKey(DateTime date) => date.toIso8601String().split('T')[0];

  String get _todayKey => _dateKey(DateTime.now());

  double get _calorieGoal => _profile?.calorieTarget ?? 2000;

  double get _waterLiters => _todayWaterCups * 0.25;

  String get _avatarLetter {
    final name = _profile?.name.trim();
    if (name == null || name.isEmpty) return 'V';
    return String.fromCharCode(name.runes.first).toUpperCase();
  }

  String get _prettyDate {
    final weekdays = _isSpanish
        ? const [
            'Lunes',
            'Martes',
            'Miércoles',
            'Jueves',
            'Viernes',
            'Sábado',
            'Domingo',
          ]
        : const [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ];
    final months = _isSpanish
        ? const [
            'enero',
            'febrero',
            'marzo',
            'abril',
            'mayo',
            'junio',
            'julio',
            'agosto',
            'septiembre',
            'octubre',
            'noviembre',
            'diciembre',
          ]
        : const [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December',
          ];
    final now = DateTime.now();
    if (_isSpanish) {
      return '${weekdays[now.weekday - 1]}, ${now.day} de ${months[now.month - 1]}';
    }
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  ({double iron, double fiber, double calcium, double zinc})
      _dailyMicroTargets() {
    final gender = _profile?.gender ?? 'female';
    final age = _profile?.age ?? 30;

    final iron = switch (gender) {
      'female' => age >= 51 ? 8.0 : 18.0,
      'male' => 8.0,
      _ => age >= 51 ? 9.0 : 13.0,
    };

    final fiber = switch (gender) {
      'female' => age > 50 ? 21.0 : 25.0,
      'male' => age > 50 ? 30.0 : 38.0,
      _ => age > 50 ? 26.0 : 31.0,
    };

    final zinc = switch (gender) {
      'female' => 8.0,
      'male' => 11.0,
      _ => 9.5,
    };

    final calcium =
        age >= 71 || (gender == 'female' && age >= 51) ? 1200.0 : 1000.0;

    return (
      iron: iron,
      fiber: fiber,
      calcium: calcium,
      zinc: zinc,
    );
  }

  String _monthLabel(int month) {
    const esMonths = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    const enMonths = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final index = month.clamp(1, 12) - 1;
    return _isSpanish ? esMonths[index] : enMonths[index];
  }

  String _mealLabel(String mealKey) {
    return switch (mealKey) {
      'breakfast' => _t('Desayuno', 'Breakfast'),
      'lunch' => _t('Almuerzo', 'Lunch'),
      'snack' => _t('Merienda', 'Snack'),
      'dinner' => _t('Cena', 'Dinner'),
      _ => _t('Comida', 'Meal'),
    };
  }

  NutritionInfo _computePlanTotals(List<_PlannedMealItem> items) {
    var totals = NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0);
    for (final item in items) {
      totals = totals + item.nutrition;
    }
    return totals;
  }

  double get _targetCalories => _profile?.calorieTarget ?? _calorieGoal;
  double get _targetProtein => _profile?.proteinTarget ?? 120;
  double get _targetCarbs => _profile?.carbsTarget ?? 220;
  double get _targetFat => _profile?.fatTarget ?? 70;

  _PlannerValidationResult _validateDailyPlan(_DailyDietPlan dayPlan) {
    final totals = dayPlan.totals;
    final microTargets = _dailyMicroTargets();
    final suggestions = <String>[];

    bool kcalOk = false;
    if (_targetCalories > 0) {
      final ratio = totals.calories / _targetCalories;
      kcalOk = ratio >= 0.94 && ratio <= 1.08;
      if (!kcalOk) {
        suggestions.add(
          _t(
            ratio < 1
                ? 'Sube porciones de carbohidratos complejos o añade un snack energético.'
                : 'Reduce porciones de alimentos densos en calorías para equilibrar el día.',
            ratio < 1
                ? 'Increase complex carb portions or add an energy snack.'
                : 'Reduce energy-dense portions to rebalance the day.',
          ),
        );
      }
    }

    final proteinOk =
        _targetProtein <= 0 ? true : totals.protein >= _targetProtein * 0.93;
    if (!proteinOk) {
      suggestions.add(_t(
        'Añade una fuente alta en proteína vegetal (tofu, tempeh, legumbres).',
        'Add a high plant-protein source (tofu, tempeh, legumes).',
      ));
    }

    final carbsOk = _targetCarbs <= 0
        ? true
        : totals.carbs >= _targetCarbs * 0.9 &&
            totals.carbs <= _targetCarbs * 1.12;
    if (!carbsOk) {
      suggestions.add(_t(
        totals.carbs < _targetCarbs
            ? 'Completa carbohidratos con avena, quinoa, arroz integral o fruta.'
            : 'Reduce carbohidratos refinados y prioriza porciones moderadas.',
        totals.carbs < _targetCarbs
            ? 'Complete carbs with oats, quinoa, brown rice, or fruit.'
            : 'Reduce refined carbs and keep moderate portions.',
      ));
    }

    final fatOk = _targetFat <= 0
        ? true
        : totals.fat >= _targetFat * 0.9 && totals.fat <= _targetFat * 1.15;
    if (!fatOk) {
      suggestions.add(_t(
        totals.fat < _targetFat
            ? 'Agrega grasas saludables (aguacate, nueces o semillas).'
            : 'Recorta grasas densas y reparte mejor entre comidas.',
        totals.fat < _targetFat
            ? 'Add healthy fats (avocado, nuts, or seeds).'
            : 'Reduce dense fats and spread intake across meals.',
      ));
    }

    final fiberOk = totals.fiber >= microTargets.fiber * 0.9;
    final ironOk = totals.iron >= microTargets.iron * 0.9;
    final calciumOk = totals.calcium >= microTargets.calcium * 0.88;
    final zincOk = totals.zinc >= microTargets.zinc * 0.9;
    final b12Ok = totals.b12 >= 2.2;

    if (!fiberOk) {
      suggestions.add(_t(
        'Falta fibra: añade verduras, legumbres y semillas de chía/linaza.',
        'Fiber is low: add vegetables, legumes, and chia/flax seeds.',
      ));
    }
    if (!ironOk) {
      suggestions.add(_t(
        'Falta hierro: prioriza lentejas, garbanzos y espinaca con vitamina C.',
        'Iron is low: prioritize lentils, chickpeas, and spinach with vitamin C.',
      ));
    }
    if (!calciumOk) {
      suggestions.add(_t(
        'Falta calcio: usa bebidas vegetales fortificadas o tofu alto en calcio.',
        'Calcium is low: use fortified plant milk or calcium-set tofu.',
      ));
    }
    if (!zincOk) {
      suggestions.add(_t(
        'Falta zinc: incluye semillas, frutos secos y legumbres.',
        'Zinc is low: include seeds, nuts, and legumes.',
      ));
    }
    if (!b12Ok) {
      suggestions.add(_t(
        'B12 baja: considera alimentos fortificados o suplementación guiada.',
        'B12 is low: consider fortified foods or guided supplementation.',
      ));
    }

    final isValid = kcalOk &&
        proteinOk &&
        carbsOk &&
        fatOk &&
        fiberOk &&
        ironOk &&
        calciumOk &&
        zincOk &&
        b12Ok;

    return _PlannerValidationResult(isValid: isValid, suggestions: suggestions);
  }

  (bool, Map<int, List<String>>) _evaluateMonthlyPlan(_MonthlyDietPlan plan) {
    var allValid = true;
    final suggestionsByDay = <int, List<String>>{};

    for (final day in plan.days) {
      final validation = _validateDailyPlan(day);
      if (!validation.isValid) {
        allValid = false;
        suggestionsByDay[day.date.day] = validation.suggestions;
      }
    }

    return (allValid, suggestionsByDay);
  }

  Future<Food?> _pickReplacementFoodDialog({
    required List<Food> foods,
    required Food currentFood,
  }) async {
    if (!mounted) return null;

    final orderedFoods = [
      ...foods.where((food) => food.id == currentFood.id),
      ...foods.where((food) => food.id != currentFood.id),
    ];

    return showDialog<Food>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_t('Reemplazar plato', 'Replace dish')),
          content: SizedBox(
            width: 430,
            height: 360,
            child: ListView.separated(
              itemCount: orderedFoods.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final food = orderedFoods[index];
                return ListTile(
                  leading:
                      Text(food.emoji, style: const TextStyle(fontSize: 20)),
                  title: Text(food.name),
                  subtitle: Text(
                    '${food.calories.toStringAsFixed(0)} kcal/100g · '
                    'P ${food.protein.toStringAsFixed(1)} · '
                    'C ${food.carbs.toStringAsFixed(1)} · '
                    'G ${food.fat.toStringAsFixed(1)}',
                  ),
                  trailing: food.id == currentFood.id
                      ? Text(
                          _t('Actual', 'Current'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6A8D76),
                          ),
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(food),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_t('Cancelar', 'Cancel')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openDayCustomization(DateTime selectedDate) async {
    final plan = _monthlyDietPlan;
    if (plan == null) return;

    if (selectedDate.year != plan.year || selectedDate.month != plan.month) {
      return;
    }

    final dayIndex = selectedDate.day - 1;
    if (dayIndex < 0 || dayIndex >= plan.days.length) return;

    final foodsFromDb = await _repo.getAllFoods();
    final foods = foodsFromDb.isNotEmpty
        ? foodsFromDb
        : (_quickFoods.isNotEmpty ? _quickFoods : _webPreviewFoods);

    if (!mounted) return;

    var editedDay = plan.days[dayIndex];

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final validation = _validateDailyPlan(editedDay);
            final mealOrder = ['breakfast', 'lunch', 'snack', 'dinner'];

            return AlertDialog(
              title: Text(
                _t(
                  'Personalizar día ${selectedDate.day}',
                  'Customize day ${selectedDate.day}',
                ),
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: validation.isValid
                              ? const Color(0xFFEAF7EE)
                              : const Color(0xFFFFF4E5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: validation.isValid
                                ? const Color(0xFFB8DABA)
                                : const Color(0xFFFFCC80),
                          ),
                        ),
                        child: Text(
                          validation.isValid
                              ? _t(
                                  'Día válido. Puedes guardar cambios.',
                                  'Day is valid. You can save changes.',
                                )
                              : _t(
                                  'Día no válido. Cambia platos y el sistema ajustará porciones automáticamente.',
                                  'Day is not valid. Change dishes and the system will auto-adjust portions.',
                                ),
                          style: TextStyle(
                            color: validation.isValid
                                ? const Color(0xFF2E8A5E)
                                : const Color(0xFF8A5C2E),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!validation.isValid &&
                          validation.suggestions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...validation.suggestions.take(4).map(
                              (hint) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '• $hint',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6A8D76),
                                  ),
                                ),
                              ),
                            ),
                      ],
                      const SizedBox(height: 10),
                      ...mealOrder.map((mealKey) {
                        final indexed = editedDay.items
                            .asMap()
                            .entries
                            .where((entry) => entry.value.mealKey == mealKey)
                            .toList();

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FCF9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDDEBDD)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _mealLabel(mealKey),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2A4B38),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () async {
                                    final baseFood = foods.isNotEmpty
                                        ? foods.first
                                        : _webPreviewFoods.first;
                                    final selectedFood =
                                        await _pickReplacementFoodDialog(
                                      foods: foods,
                                      currentFood: baseFood,
                                    );
                                    if (selectedFood == null) return;

                                    final mutableItems =
                                        List<_PlannedMealItem>.from(
                                            editedDay.items)
                                          ..add(
                                            _PlannedMealItem(
                                              mealKey: mealKey,
                                              food: selectedFood,
                                              grams: 120,
                                            ),
                                          );

                                    var candidate = _DailyDietPlan(
                                      date: editedDay.date,
                                      items: mutableItems,
                                      totals: _computePlanTotals(mutableItems),
                                    );

                                    for (var i = 0; i < 2; i++) {
                                      candidate =
                                          _rebalanceDailyPlanForNutrients(
                                        candidate,
                                        foods,
                                      );
                                    }

                                    setDialogState(() {
                                      editedDay = candidate;
                                    });
                                  },
                                  icon: const Icon(Icons.add_rounded),
                                  label: Text(_t('Agregar plato', 'Add dish')),
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (indexed.isEmpty)
                                Text(
                                  _t(
                                    'No hay platos en esta comida. Usa "Agregar plato".',
                                    'No dishes in this meal yet. Use "Add dish".',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6A8D76),
                                  ),
                                ),
                              ...indexed.map((entry) {
                                final itemIndex = entry.key;
                                final item = entry.value;

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      Text(item.food.emoji,
                                          style: const TextStyle(fontSize: 18)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${item.food.name} · ${item.grams.toStringAsFixed(0)}g',
                                          style: const TextStyle(
                                            color: Color(0xFF325441),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          final replacement =
                                              await _pickReplacementFoodDialog(
                                            foods: foods,
                                            currentFood: item.food,
                                          );
                                          if (replacement == null) return;

                                          final mutableItems =
                                              List<_PlannedMealItem>.from(
                                            editedDay.items,
                                          );
                                          mutableItems[itemIndex] =
                                              _PlannedMealItem(
                                            mealKey: item.mealKey,
                                            food: replacement,
                                            grams: item.grams,
                                          );

                                          var candidate = _DailyDietPlan(
                                            date: editedDay.date,
                                            items: mutableItems,
                                            totals: _computePlanTotals(
                                                mutableItems),
                                          );

                                          for (var i = 0; i < 2; i++) {
                                            candidate =
                                                _rebalanceDailyPlanForNutrients(
                                              candidate,
                                              foods,
                                            );
                                          }

                                          setDialogState(() {
                                            editedDay = candidate;
                                          });
                                        },
                                        child: Text(_t('Cambiar', 'Swap')),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          final mutableItems =
                                              List<_PlannedMealItem>.from(
                                            editedDay.items,
                                          )..removeAt(itemIndex);

                                          final candidate = _DailyDietPlan(
                                            date: editedDay.date,
                                            items: mutableItems,
                                            totals: _computePlanTotals(
                                                mutableItems),
                                          );

                                          setDialogState(() {
                                            editedDay = candidate;
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Color(0xFFB84D65),
                                        ),
                                        tooltip:
                                            _t('Quitar plato', 'Remove dish'),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(_t('Cancelar', 'Cancel')),
                ),
                FilledButton(
                  onPressed: validation.isValid
                      ? () async {
                          final current = _monthlyDietPlan;
                          if (current == null) return;

                          final updatedDays =
                              List<_DailyDietPlan>.from(current.days);
                          updatedDays[dayIndex] = editedDay;
                          final updatedPlan = _MonthlyDietPlan(
                            year: current.year,
                            month: current.month,
                            targetCalories: current.targetCalories,
                            targetProtein: current.targetProtein,
                            targetCarbs: current.targetCarbs,
                            targetFat: current.targetFat,
                            days: updatedDays,
                          );

                          final evaluation = _evaluateMonthlyPlan(updatedPlan);

                          if (!mounted) return;
                          setState(() {
                            _monthlyDietPlan = updatedPlan;
                            _monthlyPlanIsValid = evaluation.$1;
                            _planSuggestionsByDay = evaluation.$2;
                          });

                          await _saveMonthlyPlanToStorage(updatedPlan);

                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _t(
                                  'Día guardado y rebalanceado correctamente.',
                                  'Day saved and rebalanced successfully.',
                                ),
                              ),
                            ),
                          );
                        }
                      : null,
                  child: Text(_t('Guardar día', 'Save day')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Food _pickHighestNutrientFood(
    List<Food> foods,
    double Function(Food food) nutrient,
    Food fallback,
  ) {
    if (foods.isEmpty) return fallback;
    final ranked = List<Food>.from(foods)
      ..sort((a, b) => nutrient(b).compareTo(nutrient(a)));
    return ranked.first;
  }

  _DailyDietPlan _rebalanceDailyPlanForNutrients(
    _DailyDietPlan dayPlan,
    List<Food> foods,
  ) {
    final microTargets = _dailyMicroTargets();
    var items = List<_PlannedMealItem>.from(dayPlan.items);
    var totals = _computePlanTotals(items);

    final sourceFoods = foods.where((food) => food.calories > 0).toList();
    if (sourceFoods.isEmpty) return dayPlan;

    final fiberFood = _pickHighestNutrientFood(
      sourceFoods.where((food) => food.fiber > 0).toList(),
      (food) => food.fiber,
      sourceFoods.first,
    );
    final ironFood = _pickHighestNutrientFood(
      sourceFoods.where((food) => food.iron > 0).toList(),
      (food) => food.iron,
      sourceFoods.first,
    );
    final calciumFood = _pickHighestNutrientFood(
      sourceFoods.where((food) => food.calcium > 0).toList(),
      (food) => food.calcium,
      sourceFoods.first,
    );
    final b12Food = _pickHighestNutrientFood(
      sourceFoods.where((food) => food.b12 > 0).toList(),
      (food) => food.b12,
      sourceFoods.first,
    );
    final zincFood = _pickHighestNutrientFood(
      sourceFoods.where((food) => food.zinc > 0).toList(),
      (food) => food.zinc,
      sourceFoods.first,
    );

    void addItemForDeficit(
      double deficit,
      double macroPer100,
      Food food,
      String mealKey,
    ) {
      if (deficit <= 0 || macroPer100 <= 0) return;
      final grams = _clampGrams((deficit / macroPer100) * 100 * 1.05);
      items.add(_PlannedMealItem(mealKey: mealKey, food: food, grams: grams));
      totals = _computePlanTotals(items);
    }

    addItemForDeficit(
        microTargets.fiber - totals.fiber, fiberFood.fiber, fiberFood, 'lunch');
    addItemForDeficit(
        microTargets.iron - totals.iron, ironFood.iron, ironFood, 'dinner');
    addItemForDeficit(
      microTargets.calcium - totals.calcium,
      calciumFood.calcium,
      calciumFood,
      'snack',
    );
    addItemForDeficit(2.4 - totals.b12, b12Food.b12, b12Food, 'breakfast');
    addItemForDeficit(
        microTargets.zinc - totals.zinc, zincFood.zinc, zincFood, 'dinner');

    final kcalRatio =
        (_targetCalories / math.max(1, totals.calories)).clamp(0.9, 1.08);
    items = items
        .map(
          (item) => _PlannedMealItem(
            mealKey: item.mealKey,
            food: item.food,
            grams: _clampGrams(item.grams * kcalRatio),
          ),
        )
        .toList();

    totals = _computePlanTotals(items);
    return _DailyDietPlan(date: dayPlan.date, items: items, totals: totals);
  }

  double _macroDeficit(double target, double current) {
    return math.max(0, target - current);
  }

  double _safeMacroPer100(double value) {
    if (value <= 0) return 0.1;
    return value;
  }

  double _clampGrams(double grams) => grams.clamp(20.0, 420.0).toDouble();

  Food _pickFood(List<Food> foods, int seed, {Food? fallback}) {
    if (foods.isNotEmpty) {
      return foods[seed % foods.length];
    }
    if (fallback != null) return fallback;
    return _webPreviewFoods.first;
  }

  Food _pickFoodAvoidingRecent(
    List<Food> foods,
    int seed, {
    Food? fallback,
    Set<int> recentIds = const {},
    Food? avoid,
  }) {
    if (foods.isEmpty) {
      if (fallback != null) return fallback;
      return _webPreviewFoods.first;
    }

    final length = foods.length;
    for (var i = 0; i < length; i++) {
      final candidate = foods[(seed + i) % length];
      if (candidate.id != avoid?.id && !recentIds.contains(candidate.id)) {
        return candidate;
      }
    }

    for (var i = 0; i < length; i++) {
      final candidate = foods[(seed + i) % length];
      if (candidate.id != avoid?.id) {
        return candidate;
      }
    }

    return fallback ?? foods[seed % length];
  }

  List<Food> _sortByMacroDensity(
    List<Food> foods,
    double Function(Food food) macro,
  ) {
    final result = List<Food>.from(foods);
    result.sort((a, b) {
      final densityA = macro(a) / (a.calories <= 0 ? 1.0 : a.calories);
      final densityB = macro(b) / (b.calories <= 0 ? 1.0 : b.calories);
      return densityB.compareTo(densityA);
    });
    return result;
  }

  _DailyDietPlan _generateDailyPlan({
    required int day,
    required int month,
    required int year,
    required List<Food> foods,
    required double calorieTarget,
    required double proteinTarget,
    required double carbsTarget,
    required double fatTarget,
  }) {
    final validFoods = foods.where((food) => food.calories > 0).toList();
    final sourceFoods = validFoods.isNotEmpty ? validFoods : _webPreviewFoods;

    final proteinFoods = _sortByMacroDensity(
      sourceFoods.where((f) => f.protein >= 6).toList(),
      (f) => f.protein,
    );
    final carbFoods = _sortByMacroDensity(
      sourceFoods.where((f) => f.carbs >= 10).toList(),
      (f) => f.carbs,
    );
    final fatFoods = _sortByMacroDensity(
      sourceFoods.where((f) => f.fat >= 7).toList(),
      (f) => f.fat,
    );
    final fiberFoods = _sortByMacroDensity(
      sourceFoods.where((f) => f.fiber >= 2).toList(),
      (f) => f.fiber,
    );

    final seed = (year * 1000) + (month * 40) + day;
    final proteinMain = _pickFood(proteinFoods, seed);
    final proteinSecondary =
        _pickFood(proteinFoods, seed + 7, fallback: proteinMain);
    final carbsMain = _pickFood(carbFoods, seed + 3, fallback: proteinMain);
    final carbsSecondary = _pickFood(carbFoods, seed + 11, fallback: carbsMain);
    final fatMain = _pickFood(fatFoods, seed + 5, fallback: proteinMain);
    final veggieMain = _pickFood(fiberFoods, seed + 13, fallback: carbsMain);

    final dayFactor = 0.92 + ((seed % 17) / 100);
    final items = <_PlannedMealItem>[
      _PlannedMealItem(
        mealKey: 'breakfast',
        food: carbsMain,
        grams: _clampGrams(150 * dayFactor),
      ),
      _PlannedMealItem(
        mealKey: 'breakfast',
        food: proteinMain,
        grams: _clampGrams(130 * dayFactor),
      ),
      _PlannedMealItem(
        mealKey: 'lunch',
        food: proteinSecondary,
        grams: _clampGrams(190 * dayFactor),
      ),
      _PlannedMealItem(
        mealKey: 'lunch',
        food: carbsSecondary,
        grams: _clampGrams(180 * dayFactor),
      ),
      _PlannedMealItem(
        mealKey: 'snack',
        food: fatMain,
        grams: _clampGrams(38 * dayFactor),
      ),
      _PlannedMealItem(
        mealKey: 'dinner',
        food: proteinMain,
        grams: _clampGrams(170 * dayFactor),
      ),
      _PlannedMealItem(
        mealKey: 'dinner',
        food: veggieMain,
        grams: _clampGrams(200 * dayFactor),
      ),
    ];

    var mutableItems = items;
    var totals = _computePlanTotals(mutableItems);

    final proteinDeficit = _macroDeficit(proteinTarget, totals.protein);
    final carbsDeficit = _macroDeficit(carbsTarget, totals.carbs);
    final fatDeficit = _macroDeficit(fatTarget, totals.fat);

    if (proteinDeficit > 0.1) {
      final extraProteinGrams =
          (proteinDeficit / _safeMacroPer100(proteinMain.protein)) * 100;
      mutableItems = mutableItems
          .map(
            (item) => item.food.id == proteinMain.id
                ? _PlannedMealItem(
                    mealKey: item.mealKey,
                    food: item.food,
                    grams: _clampGrams(item.grams + (extraProteinGrams * 0.35)),
                  )
                : item,
          )
          .toList();
      totals = _computePlanTotals(mutableItems);
    }

    if (carbsDeficit > 0.1) {
      final extraCarbGrams =
          (carbsDeficit / _safeMacroPer100(carbsMain.carbs)) * 100;
      mutableItems = mutableItems
          .map(
            (item) => item.food.id == carbsMain.id
                ? _PlannedMealItem(
                    mealKey: item.mealKey,
                    food: item.food,
                    grams: _clampGrams(item.grams + (extraCarbGrams * 0.45)),
                  )
                : item,
          )
          .toList();
      totals = _computePlanTotals(mutableItems);
    }

    if (fatDeficit > 0.1) {
      final extraFatGrams = (fatDeficit / _safeMacroPer100(fatMain.fat)) * 100;
      mutableItems = mutableItems
          .map(
            (item) => item.food.id == fatMain.id
                ? _PlannedMealItem(
                    mealKey: item.mealKey,
                    food: item.food,
                    grams: _clampGrams(item.grams + (extraFatGrams * 0.7)),
                  )
                : item,
          )
          .toList();
      totals = _computePlanTotals(mutableItems);
    }

    final calorieRatio = calorieTarget > 0
        ? (calorieTarget / math.max(1.0, totals.calories)).clamp(0.85, 1.18)
        : 1.0;

    mutableItems = mutableItems
        .map(
          (item) => _PlannedMealItem(
            mealKey: item.mealKey,
            food: item.food,
            grams: _clampGrams(item.grams * calorieRatio),
          ),
        )
        .toList();

    totals = _computePlanTotals(mutableItems);

    return _DailyDietPlan(
      date: DateTime(year, month, day),
      items: mutableItems,
      totals: totals,
    );
  }

  _MonthlyDietPlan _generateMonthlyDietPlan({
    required int year,
    required int month,
    required List<Food> foods,
    required double calorieTarget,
    required double proteinTarget,
    required double carbsTarget,
    required double fatTarget,
  }) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final plans = <_DailyDietPlan>[];

    for (var day = 1; day <= daysInMonth; day++) {
      var dayPlan = _generateDailyPlan(
        day: day,
        month: month,
        year: year,
        foods: foods,
        calorieTarget: calorieTarget,
        proteinTarget: proteinTarget,
        carbsTarget: carbsTarget,
        fatTarget: fatTarget,
      );

      for (var attempt = 0; attempt < 3; attempt++) {
        final validation = _validateDailyPlan(dayPlan);
        if (validation.isValid) break;
        dayPlan = _rebalanceDailyPlanForNutrients(dayPlan, foods);
      }

      plans.add(dayPlan);
    }

    return _MonthlyDietPlan(
      year: year,
      month: month,
      targetCalories: calorieTarget,
      targetProtein: proteinTarget,
      targetCarbs: carbsTarget,
      targetFat: fatTarget,
      days: plans,
    );
  }

  _MonthlyDietPlan _generateManualMonthlyPlan({
    required int year,
    required int month,
    required List<Food> foods,
    required double calorieTarget,
    required double proteinTarget,
    required double carbsTarget,
    required double fatTarget,
  }) {
    final validFoods = foods.where((food) => food.calories > 0).toList();
    final sourceFoods = validFoods.isNotEmpty ? validFoods : _webPreviewFoods;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final plans = <_DailyDietPlan>[];
    final recentLunchIds = <int>[];

    for (var day = 1; day <= daysInMonth; day++) {
      final seed = (year * 1300) + (month * 50) + day;
      final breakfast = _pickFood(sourceFoods, seed);
      final lunch = _pickFoodAvoidingRecent(
        sourceFoods,
        seed + 7,
        fallback: breakfast,
        recentIds: recentLunchIds.toSet(),
        avoid: breakfast,
      );
      final snack = _pickFood(sourceFoods, seed + 13, fallback: lunch);
      final dinner = _pickFood(sourceFoods, seed + 19, fallback: breakfast);

      final items = <_PlannedMealItem>[
        _PlannedMealItem(mealKey: 'breakfast', food: breakfast, grams: 140),
        _PlannedMealItem(mealKey: 'lunch', food: lunch, grams: 180),
        _PlannedMealItem(mealKey: 'snack', food: snack, grams: 80),
        _PlannedMealItem(mealKey: 'dinner', food: dinner, grams: 180),
      ];

      final totals = _computePlanTotals(items);
      plans.add(
        _DailyDietPlan(
          date: DateTime(year, month, day),
          items: items,
          totals: totals,
        ),
      );

      if (lunch.id != null) {
        recentLunchIds.add(lunch.id!);
        if (recentLunchIds.length > 7) {
          recentLunchIds.removeAt(0);
        }
      }
    }

    return _MonthlyDietPlan(
      year: year,
      month: month,
      targetCalories: calorieTarget,
      targetProtein: proteinTarget,
      targetCarbs: carbsTarget,
      targetFat: fatTarget,
      days: plans,
    );
  }

  _DailyDietPlan? _getDailyPlanForDate(DateTime date) {
    final plan = _monthlyDietPlan;
    if (plan == null) return null;
    if (date.year != plan.year || date.month != plan.month) return null;

    final dayIndex = date.day - 1;
    if (dayIndex < 0 || dayIndex >= plan.days.length) return null;
    return plan.days[dayIndex];
  }

  Future<void> _openPlannedRecipesForDay() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RecipeTodayScreen(),
      ),
    );
  }

  Future<void> _openDietPlanner() async {
    if (!mounted) return;
    final now = DateTime.now();
    var selectedYear = now.year;
    var selectedMonth = now.month;
    var prioritizeQuickFoods = true;
    var manualMode = false;

    final request = await showDialog<_PlannerRequest>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(_t('Planificador mensual', 'Monthly planner')),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t(
                          'Configura mes y enfoque del plan.',
                          'Set month and planning preferences.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: selectedMonth,
                              decoration: InputDecoration(
                                labelText: _t('Mes', 'Month'),
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: List.generate(
                                12,
                                (index) => DropdownMenuItem<int>(
                                  value: index + 1,
                                  child: Text(_monthLabel(index + 1)),
                                ),
                              ),
                              onChanged: (value) {
                                if (value == null) return;
                                setDialogState(() => selectedMonth = value);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: selectedYear,
                              decoration: InputDecoration(
                                labelText: _t('Año', 'Year'),
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: [
                                now.year - 1,
                                now.year,
                                now.year + 1,
                              ]
                                  .map(
                                    (year) => DropdownMenuItem<int>(
                                      value: year,
                                      child: Text('$year'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setDialogState(() => selectedYear = value);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5FAF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDDEBDD)),
                        ),
                        child: Text(
                          _t(
                            'Las calorías, macros y micronutrientes se calculan automáticamente desde tu perfil. No necesitas ingresar números.',
                            'Calories, macros, and micronutrients are calculated automatically from your profile. No manual numbers required.',
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF466D54),
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: prioritizeQuickFoods,
                        onChanged: (value) {
                          setDialogState(() => prioritizeQuickFoods = value);
                        },
                        title: Text(
                          _t(
                            'Priorizar comidas rápidas',
                            'Prioritize quick meals',
                          ),
                        ),
                        subtitle: Text(
                          _t(
                            'Útil para planes más prácticos entre semana.',
                            'Useful for practical weekday plans.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SwitchListTile.adaptive(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: manualMode,
                        onChanged: (value) {
                          setDialogState(() => manualMode = value);
                        },
                        title: Text(
                          _t('Modo manual asistido', 'Assisted manual mode'),
                        ),
                        subtitle: Text(
                          _t(
                            'Genera un borrador editable para personalizar plato por plato.',
                            'Generates an editable draft so you can customize dish by dish.',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(_t('Cancelar', 'Cancel')),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      _PlannerRequest(
                        year: selectedYear,
                        month: selectedMonth,
                        prioritizeQuickFoods: prioritizeQuickFoods,
                        manualMode: manualMode,
                      ),
                    );
                  },
                  child: Text(_t('Generar', 'Generate')),
                ),
              ],
            );
          },
        );
      },
    );

    if (request == null) return;

    final foodsFromDb = await _repo.getAllFoods();
    final prioritizedFoods = request.prioritizeQuickFoods
        ? [
            ...foodsFromDb.where((food) => food.isQuickFood),
            ...foodsFromDb.where((food) => !food.isQuickFood),
          ]
        : foodsFromDb;

    final sourceFoods = prioritizedFoods.isNotEmpty
        ? prioritizedFoods
        : (_quickFoods.isNotEmpty ? _quickFoods : _webPreviewFoods);

    final plan = request.manualMode
        ? _generateManualMonthlyPlan(
            year: request.year,
            month: request.month,
            foods: sourceFoods,
            calorieTarget: _targetCalories,
            proteinTarget: _targetProtein,
            carbsTarget: _targetCarbs,
            fatTarget: _targetFat,
          )
        : _generateMonthlyDietPlan(
            year: request.year,
            month: request.month,
            foods: sourceFoods,
            calorieTarget: _targetCalories,
            proteinTarget: _targetProtein,
            carbsTarget: _targetCarbs,
            fatTarget: _targetFat,
          );

    final evaluation = _evaluateMonthlyPlan(plan);
    final planIsValid = evaluation.$1;
    final suggestionsByDay = evaluation.$2;

    if (!mounted) return;
    setState(() {
      _monthlyDietPlan = plan;
      _monthlyPlanIsValid = planIsValid;
      _planSuggestionsByDay = suggestionsByDay;
    });

    await _saveMonthlyPlanToStorage(plan);

    if (!planIsValid) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(_t('Plan generado con ajustes',
                'Plan generated with adjustments')),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _t(
                        request.manualMode
                            ? 'Se generó tu borrador manual. Personaliza platos por día y guarda solo cuando cada día cumpla objetivos.'
                            : 'Se generó el plan mensual automáticamente. Algunos días tienen recomendaciones para mejorar el balance nutricional.',
                        request.manualMode
                            ? 'Your manual draft was generated. Customize dishes by day and save only when each day meets targets.'
                            : 'Your monthly plan was generated automatically. Some days include recommendations to improve nutritional balance.',
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...suggestionsByDay.entries.take(6).map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _t(
                                'Día ${entry.key}: ${entry.value.first}',
                                'Day ${entry.key}: ${entry.value.first}',
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF5A3A2B),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(_t('Continuar', 'Continue')),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Plan mensual generado para ${_monthLabel(plan.month)} ${plan.year}.',
              'Monthly plan generated for ${_monthLabel(plan.month)} ${plan.year}.',
            ),
          ),
        ),
      );
    }

    if (request.manualMode) {
      await _openPlannedRecipesForDay();
      return;
    }

    _showMonthlyPlanDetails();
  }

  void _showMonthlyPlanDetails() {
    final plan = _monthlyDietPlan;
    if (plan == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.86,
          decoration: const BoxDecoration(
            color: Color(0xFFF8FFF8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFBED8C5),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _t(
                          'Dieta de ${_monthLabel(plan.month)} ${plan.year}',
                          'Diet for ${_monthLabel(plan.month)} ${plan.year}',
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF244B35),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: plan.days.length,
                  itemBuilder: (context, index) {
                    final dayPlan = plan.days[index];
                    return Container(
                      margin: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFDCEBDD)),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            14,
                            0,
                            14,
                            14,
                          ),
                          title: Text(
                            _t(
                              'Día ${dayPlan.date.day}',
                              'Day ${dayPlan.date.day}',
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2A4B38),
                            ),
                          ),
                          subtitle: Text(
                            '${dayPlan.totals.calories.toStringAsFixed(0)} kcal · '
                            'P ${dayPlan.totals.protein.toStringAsFixed(0)}g · '
                            'C ${dayPlan.totals.carbs.toStringAsFixed(0)}g · '
                            'G ${dayPlan.totals.fat.toStringAsFixed(0)}g',
                            style: const TextStyle(
                              color: Color(0xFF6A8D76),
                              fontSize: 12,
                            ),
                          ),
                          children: dayPlan.items
                              .map(
                                (item) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Text(
                                        item.food.emoji,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${_mealLabel(item.mealKey)} · ${item.food.name}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF325441),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${item.grams.toStringAsFixed(0)}g',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2E8A5E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<
      ({
        String label,
        double current,
        double target,
        Color color,
        String unit,
        bool isMacro,
        bool showOverLine,
      })> get _progressItems {
    final microTargets = _dailyMicroTargets();

    return [
      (
        label: _t('Proteína', 'Protein'),
        current: _todayTotals.protein,
        target: _profile?.proteinTarget ?? 120,
        color: const Color(0xFF2E8A5E),
        unit: 'g',
        isMacro: true,
        showOverLine: true,
      ),
      (
        label: _t('Carbohidratos', 'Carbohydrates'),
        current: _todayTotals.carbs,
        target: _profile?.carbsTarget ?? 220,
        color: const Color(0xFFB8763A),
        unit: 'g',
        isMacro: true,
        showOverLine: true,
      ),
      (
        label: _t('Grasas', 'Fats'),
        current: _todayTotals.fat,
        target: _profile?.fatTarget ?? 70,
        color: const Color(0xFF7050A8),
        unit: 'g',
        isMacro: true,
        showOverLine: true,
      ),
      (
        label: _t('Fibra', 'Fiber'),
        current: _todayTotals.fiber,
        target: microTargets.fiber,
        color: const Color(0xFF4F8E50),
        unit: 'g',
        isMacro: false,
        showOverLine: true,
      ),
      (
        label: _t('Hierro', 'Iron'),
        current: _todayTotals.iron,
        target: microTargets.iron,
        color: const Color(0xFF9B6A3A),
        unit: 'mg',
        isMacro: false,
        showOverLine: true,
      ),
      (
        label: _t('Calcio', 'Calcium'),
        current: _todayTotals.calcium,
        target: microTargets.calcium,
        color: const Color(0xFF4E9A8A),
        unit: 'mg',
        isMacro: false,
        showOverLine: true,
      ),
      (
        label: _t('Vitamina B12', 'Vitamin B12'),
        current: _todayTotals.b12,
        target: 2.4,
        color: const Color(0xFF5E7AC8),
        unit: 'mcg',
        isMacro: false,
        showOverLine: true,
      ),
      (
        label: _t('Zinc', 'Zinc'),
        current: _todayTotals.zinc,
        target: microTargets.zinc,
        color: const Color(0xFF6B5CB9),
        unit: 'mg',
        isMacro: false,
        showOverLine: true,
      ),
    ];
  }

  Future<void> _setWaterCups(int cups) async {
    final nextValue = cups.clamp(0, 24).toInt();
    final updateVersion = ++_waterUpdateVersion;

    setState(() {
      _todayWaterCups = nextValue;
      if (_weeklyWater.isNotEmpty) {
        final nextWeekly = List<int>.from(_weeklyWater);
        nextWeekly[nextWeekly.length - 1] = nextValue;
        _weeklyWater = nextWeekly;
      }
    });

    if (kIsWeb) return;

    try {
      await _repo.saveWaterIntake(nextValue, _todayKey);
      await _refreshWeeklyWaterSeries(
        expectedTodayCups: nextValue,
        updateVersion: updateVersion,
      );
    } catch (_) {
      if (!mounted || updateVersion != _waterUpdateVersion) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el agua de hoy.')),
      );
    }
  }

  Future<void> _refreshWeeklyWaterSeries({
    required int expectedTodayCups,
    required int updateVersion,
  }) async {
    final now = DateTime.now();
    final weeklyWater = <int>[];

    for (int i = 6; i >= 0; i--) {
      final dateKey = _dateKey(now.subtract(Duration(days: i)));
      weeklyWater.add(await _repo.getWaterIntake(dateKey));
    }

    if (!mounted || updateVersion != _waterUpdateVersion) return;

    if (weeklyWater.isNotEmpty) {
      weeklyWater[weeklyWater.length - 1] = expectedTodayCups;
    }

    setState(() {
      _weeklyWater = weeklyWater;
      _todayWaterCups = expectedTodayCups;
    });
  }

  Future<void> _openDisplaySettings() async {
    String selectedLanguage = _currentLocale.languageCode;
    bool darkMode = _currentThemeMode == ThemeMode.dark;
    bool notificationsEnabled = _notificationsEnabled;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDarkSheet = Theme.of(context).brightness == Brightness.dark;
            const switchActiveTrack = Color(0xFF2E8A5E);
            final switchInactiveTrack =
                isDarkSheet ? const Color(0xFF6F7A74) : const Color(0xFFB9C4BE);
            final sheetTitle =
                selectedLanguage == 'es' ? 'Configuracion' : 'Settings';
            final languageLabel =
                selectedLanguage == 'es' ? 'Idioma' : 'Language';
            final themeLabel =
                selectedLanguage == 'es' ? 'Tema oscuro' : 'Dark mode';
            final notificationsLabel =
                selectedLanguage == 'es' ? 'Notificaciones' : 'Notifications';
            const feedbackTitle = 'Feedback';
            final feedbackDescription = selectedLanguage == 'es'
                ? 'Sigue tu progreso de usuario'
                : 'Track your user progress';
            final optionTextStyle =
                Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    );

            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    20 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sheetTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedLanguage,
                        isDense: true,
                        style: optionTextStyle,
                        decoration: InputDecoration(
                          labelText: languageLabel,
                          prefixIcon: const Icon(Icons.language_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'es',
                            child: Text('Español'),
                          ),
                          DropdownMenuItem(
                            value: 'en',
                            child: Text('English'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setModalState(() => selectedLanguage = value);
                          final nextLocale = value == 'es'
                              ? const Locale('es', 'ES')
                              : const Locale('en', 'US');

                          setState(() => _currentLocale = nextLocale);
                          widget.onLanguageChanged(nextLocale);
                        },
                      ),
                      const SizedBox(height: 6),
                      SwitchListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.white,
                        activeTrackColor: switchActiveTrack,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: switchInactiveTrack,
                        secondary: Icon(
                          notificationsEnabled
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_rounded,
                        ),
                        title: Text(
                          notificationsLabel,
                          style: optionTextStyle,
                        ),
                        value: notificationsEnabled,
                        onChanged: (value) {
                          setModalState(() => notificationsEnabled = value);
                          unawaited(_setNotificationsEnabled(value));
                        },
                      ),
                      const SizedBox(height: 4),
                      SwitchListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.white,
                        activeTrackColor: switchActiveTrack,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: switchInactiveTrack,
                        title: Row(
                          children: [
                            Text(
                              darkMode ? '🌙' : '☀️',
                              style: const TextStyle(
                                fontSize: 18,
                                fontFamilyFallback: [
                                  'Noto Color Emoji',
                                  'Segoe UI Emoji',
                                  'Apple Color Emoji',
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              themeLabel,
                              style: optionTextStyle,
                            ),
                          ],
                        ),
                        value: darkMode,
                        onChanged: (value) {
                          setModalState(() => darkMode = value);
                          final nextMode =
                              value ? ThemeMode.dark : ThemeMode.light;

                          setState(() => _currentThemeMode = nextMode);
                          widget.onThemeModeChanged(nextMode);
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        feedbackTitle,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 6),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.trending_up_rounded),
                        title: Text(feedbackDescription),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _openFeedbackProgress,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openFeedbackProgress() async {
    final baselineRecord = await _repo.getBaselineProfileRecord();
    final latestRecord = await _repo.getLatestProfileRecord();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Feedback',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  _t('Antes y despues de tus medidas',
                      'Before and after your measurements'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                if (latestRecord == null || baselineRecord == null)
                  Text(
                    _t(
                      'Guarda tus medidas en "Mediciones" para ver el progreso.',
                      'Save your measurements in "Measurements" to see progress.',
                    ),
                  )
                else if (latestRecord.id == baselineRecord.id)
                  Text(
                    _t(
                      'Guarda tus medidas otra vez para comparar el antes y despues.',
                      'Save your measurements again to compare before and after.',
                    ),
                  )
                else
                  _buildMeasurementsComparison(
                    before: baselineRecord,
                    after: latestRecord,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMeasurementsComparison({
    required ProfileRecord before,
    required ProfileRecord after,
  }) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Column(
      children: [
        Row(
          children: [
            const Expanded(flex: 2, child: SizedBox()),
            Expanded(
              child: Text(
                _t('Antes', 'Before'),
                textAlign: TextAlign.end,
                style: textStyle?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _t('Despues', 'After'),
                textAlign: TextAlign.end,
                style: textStyle?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildMeasureRow(
          label: _t('Peso (kg)', 'Weight (kg)'),
          before: before.weight,
          after: after.weight,
        ),
        _buildMeasureRow(
          label: _t('Cintura (cm)', 'Waist (cm)'),
          before: before.waist,
          after: after.waist,
        ),
        _buildMeasureRow(
          label: _t('Cuello (cm)', 'Neck (cm)'),
          before: before.neck,
          after: after.neck,
        ),
        _buildMeasureRow(
          label: _t('Cadera (cm)', 'Hip (cm)'),
          before: before.hip,
          after: after.hip,
        ),
        _buildMeasureRow(
          label: _t('Muslo (cm)', 'Thigh (cm)'),
          before: before.thigh,
          after: after.thigh,
        ),
        _buildMeasureRow(
          label: _t('Brazo (cm)', 'Arm (cm)'),
          before: before.arm,
          after: after.arm,
        ),
        _buildMeasureRow(
          label: _t('Pantorrilla (cm)', 'Calf (cm)'),
          before: before.calf,
          after: after.calf,
        ),
      ],
    );
  }

  Widget _buildMeasureRow({
    required String label,
    required double? before,
    required double? after,
  }) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: textStyle),
          ),
          Expanded(
            child: Text(
              _formatMeasure(before),
              textAlign: TextAlign.end,
              style: textStyle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _formatMeasure(after),
              textAlign: TextAlign.end,
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMeasure(double? value) {
    if (value == null) return '-';
    return value.toStringAsFixed(1);
  }

  void _showComingSoon(String name) {
    final normalized = name.toLowerCase();

    if (normalized.contains('planificador') || normalized.contains('planner')) {
      unawaited(_openDietPlanner());
      return;
    }

    if (normalized.contains('recetas') || normalized.contains('recipes')) {
      unawaited(_openPlannedRecipesForDay());
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _t('$name estará disponible pronto.',
              '$name will be available soon.'),
        ),
      ),
    );
  }

  List<Food> get _webPreviewFoods => [
        Food(
          id: 1,
          name: 'Tofu firme',
          emoji: '🧊',
          calories: 80,
          protein: 8.5,
          carbs: 1.9,
          fat: 4.8,
        ),
        Food(
          id: 2,
          name: 'Lentejas cocidas',
          emoji: '🫘',
          calories: 116,
          protein: 9,
          carbs: 20,
          fat: 0.4,
        ),
        Food(
          id: 3,
          name: 'Garbanzos',
          emoji: '🫙',
          calories: 164,
          protein: 8.9,
          carbs: 27,
          fat: 2.6,
        ),
        Food(
          id: 4,
          name: 'Quinoa cocida',
          emoji: '🌾',
          calories: 120,
          protein: 4.4,
          carbs: 21.3,
          fat: 1.9,
        ),
        Food(
          id: 5,
          name: 'Espinaca',
          emoji: '🥬',
          calories: 23,
          protein: 2.9,
          carbs: 3.6,
          fat: 0.4,
        ),
        Food(
          id: 6,
          name: 'Aguacate',
          emoji: '🥑',
          calories: 160,
          protein: 2,
          carbs: 9,
          fat: 14.7,
        ),
        Food(
          id: 7,
          name: 'Plátano',
          emoji: '🍌',
          calories: 89,
          protein: 1.1,
          carbs: 23,
          fat: 0.3,
        ),
        Food(
          id: 8,
          name: 'Leche de soja',
          emoji: '🥛',
          calories: 54,
          protein: 3.3,
          carbs: 6.3,
          fat: 1.8,
        ),
        Food(
          id: 9,
          name: 'Nueces',
          emoji: '🥜',
          calories: 654,
          protein: 15,
          carbs: 14,
          fat: 65,
        ),
        Food(
          id: 10,
          name: 'Brócoli',
          emoji: '🥦',
          calories: 34,
          protein: 2.8,
          carbs: 7,
          fat: 0.4,
        ),
        Food(
          id: 11,
          name: 'Arroz integral',
          emoji: '🍚',
          calories: 216,
          protein: 5,
          carbs: 45,
          fat: 1.8,
        ),
        Food(
          id: 12,
          name: 'Tempeh',
          emoji: '🟫',
          calories: 195,
          protein: 20,
          carbs: 7.6,
          fat: 11,
        ),
        Food(
          id: 13,
          name: 'Avena',
          emoji: '🥣',
          calories: 389,
          protein: 17,
          carbs: 66,
          fat: 7,
        ),
        Food(
          id: 14,
          name: 'Frijoles negros',
          emoji: '🫘',
          calories: 132,
          protein: 8.9,
          carbs: 24,
          fat: 0.5,
        ),
        Food(
          id: 15,
          name: 'Edamame',
          emoji: '💚',
          calories: 121,
          protein: 11.9,
          carbs: 8.9,
          fat: 5.2,
        ),
        Food(
          id: 16,
          name: 'Almendras',
          emoji: '🌰',
          calories: 579,
          protein: 21,
          carbs: 22,
          fat: 49,
        ),
        Food(
          id: 17,
          name: 'Manzana',
          emoji: '🍎',
          calories: 52,
          protein: 0.3,
          carbs: 14,
          fat: 0.2,
        ),
        Food(
          id: 18,
          name: 'Naranja',
          emoji: '🍊',
          calories: 47,
          protein: 0.9,
          carbs: 12,
          fat: 0.1,
        ),
        Food(
          id: 19,
          name: 'Zanahoria',
          emoji: '🥕',
          calories: 41,
          protein: 0.9,
          carbs: 10,
          fat: 0.2,
        ),
        Food(
          id: 20,
          name: 'Tomate',
          emoji: '🍅',
          calories: 18,
          protein: 0.9,
          carbs: 3.9,
          fat: 0.2,
        ),
        Food(
          id: 21,
          name: 'Lechuga',
          emoji: '🥗',
          calories: 15,
          protein: 1.4,
          carbs: 2.9,
          fat: 0.2,
        ),
        Food(
          id: 22,
          name: 'Pepino',
          emoji: '🥒',
          calories: 16,
          protein: 0.7,
          carbs: 3.6,
          fat: 0.1,
        ),
        Food(
          id: 23,
          name: 'Papa',
          emoji: '🥔',
          calories: 77,
          protein: 2,
          carbs: 17,
          fat: 0.1,
        ),
        Food(
          id: 24,
          name: 'Camote',
          emoji: '🍠',
          calories: 86,
          protein: 1.6,
          carbs: 20,
          fat: 0.1,
        ),
        Food(
          id: 25,
          name: 'Apio',
          emoji: '🥬',
          calories: 16,
          protein: 0.7,
          carbs: 3,
          fat: 0.2,
        ),
        Food(
          id: 26,
          name: 'Col rizada',
          emoji: '🥬',
          calories: 49,
          protein: 4.3,
          carbs: 8.8,
          fat: 0.9,
        ),
        Food(
          id: 27,
          name: 'Repollo',
          emoji: '🥬',
          calories: 25,
          protein: 1.3,
          carbs: 6,
          fat: 0.1,
        ),
        Food(
          id: 28,
          name: 'Berenjena',
          emoji: '🍆',
          calories: 25,
          protein: 1,
          carbs: 6,
          fat: 0.2,
        ),
        Food(
          id: 29,
          name: 'Pimientos',
          emoji: '🫑',
          calories: 31,
          protein: 1,
          carbs: 6,
          fat: 0.3,
        ),
        Food(
          id: 30,
          name: 'Champiñones',
          emoji: '🍄',
          calories: 22,
          protein: 3.1,
          carbs: 3.3,
          fat: 0.3,
        ),
        Food(
          id: 31,
          name: 'Maíz',
          emoji: '🌽',
          calories: 96,
          protein: 3.4,
          carbs: 21,
          fat: 1.5,
        ),
        Food(
          id: 32,
          name: 'Arvejas',
          emoji: '🫛',
          calories: 81,
          protein: 5.4,
          carbs: 14,
          fat: 0.4,
        ),
        Food(
          id: 33,
          name: 'Fresa',
          emoji: '🍓',
          calories: 32,
          protein: 0.7,
          carbs: 7.7,
          fat: 0.3,
        ),
        Food(
          id: 34,
          name: 'Mango',
          emoji: '🥭',
          calories: 60,
          protein: 0.8,
          carbs: 15,
          fat: 0.4,
        ),
        Food(
          id: 35,
          name: 'Piña',
          emoji: '🍍',
          calories: 50,
          protein: 0.5,
          carbs: 13,
          fat: 0.1,
        ),
      ];

  String _getCurrentMealTime() {
    final hour = DateTime.now().hour;
    if (hour < 11) return _t('Desayuno', 'Breakfast');
    if (hour < 16) return _t('Almuerzo', 'Lunch');
    if (hour < 21) return _t('Cena', 'Dinner');
    return _t('Merienda', 'Snack');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final calorieProgress = _calorieGoal <= 0
        ? 0.0
        : (_todayTotals.calories / _calorieGoal).clamp(0.0, 1.0).toDouble();
    final calorieRemaining =
        math.max(0.0, _calorieGoal - _todayTotals.calories);
    final isHome = _activeSection == 0;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F1713)
          : (isHome ? const Color(0xFFF8F6EF) : const Color(0xFFF7FBF7)),
      body: Stack(
        children: [
          if (!isHome)
            Positioned(
              top: -100,
              left: -80,
              child: _buildBlurBubble(const Color(0x4439C38A), 260),
            ),
          if (!isHome)
            Positioned(
              top: 220,
              right: -110,
              child: _buildBlurBubble(const Color(0x3338BDF8), 260),
            ),
          if (!isHome)
            Positioned(
              bottom: -120,
              left: 40,
              child: _buildBlurBubble(const Color(0x3339C38A), 300),
            ),
          SafeArea(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2E8A5E)),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: _activeSection == 0
                        ? _buildInicioContent()
                        : (_activeSection == 1
                            ? _buildRegistroContent(
                                calorieProgress: calorieProgress,
                                calorieRemaining: calorieRemaining,
                              )
                            : (_activeSection == 2
                                ? _buildChartsContent()
                                : _buildProfileContent())),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openFoodLogger,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          _activeSection == 0 ? _t('Registrar', 'Log') : _t('Agregar', 'Add'),
        ),
        backgroundColor: const Color(0xFF2E8A5E),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildMainBottomNav(),
    );
  }

  Widget _buildProfileContent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openMeasurements();
    });
    return Container();
  }

  Widget _buildInicioContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sourceFoods = _allFoods.isNotEmpty
        ? _allFoods
        : (_quickFoods.isNotEmpty ? _quickFoods : _webPreviewFoods);
    final popularFoods = sourceFoods
        .where(
          (food) => food.id == null || !_undesiredFoodIds.contains(food.id!),
        )
        .toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHomeTopBar(),
                const SizedBox(height: 16),
                Text(
                  _t('¡Hola!', 'Hello!'),
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF4B2D20),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _t('Come saludable y vive vegano', 'Eat Healthy & Go Vegan'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : const Color(0xFF5A3A2B),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2B3A30)
                        : const Color(0xFFEAF5D8),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF4E6759)
                          : const Color(0xFFBFD6A6),
                    ),
                  ),
                  child: Text(
                    'Build $_buildStamp',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF4F6B2E),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildSearchCard(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildHomeActionCard(
                        icon: Icons.menu_book_rounded,
                        label: _t('Recetas', 'Recipes'),
                        background: const Color(0xFFF3AF2C),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RecipeTodayScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildHomeActionCard(
                        icon: Icons.calendar_month_rounded,
                        label: _t('Planificador', 'Planner'),
                        background: const Color(0xFFE96C79),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PlanificarHomeScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildHomeActionCard(
                        icon: Icons.storefront_rounded,
                        label: _t('Tienda', 'Store'),
                        background: const Color(0xFF6CBF72),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ShopScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildDietPlannerSummaryCard(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      _t('Recetas populares', 'Popular Recipes'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF513327),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _showComingSoon('Lista completa'),
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (popularFoods.isEmpty)
                  _buildEmptyStateCard(
                    _t(
                      'No hay recetas disponibles todavía.',
                      'No recipes are available yet.',
                    ),
                  )
                else
                  SizedBox(
                    height: 210,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: popularFoods.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 170,
                          child: _buildQuickFoodCard(popularFoods[index]),
                        );
                      },
                    ),
                  ),
                if (_loadError != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3A2F25)
                          : const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF8D6E4A)
                            : const Color(0xFFFFCC80),
                      ),
                    ),
                    child: Text(
                      _loadError!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : const Color(0xFF5D4037),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistroContent({
    required double calorieProgress,
    required double calorieRemaining,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                const SizedBox(height: 16),
                Text(
                  _t('Registro de comida', 'Food log'),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF244B35),
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _prettyDate,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : const Color(0xFF6A8D76),
                  ),
                ),
                if (_profile == null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3B3328)
                          : const Color(0xFFFEF8ED),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF8B7757)
                            : const Color(0xFFF1D6A8),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.straighten_rounded,
                          color: Color(0xFFB8763A),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _t(
                              'Completa tus medidas para personalizar metas y progreso.',
                              'Complete your measurements to personalize goals and progress.',
                            ),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _openMeasurements,
                          child: Text(_t('Abrir', 'Open')),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_loadError != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3A2F25)
                          : const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF8D6E4A)
                            : const Color(0xFFFFCC80),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF8D6E63),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _loadError!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                _buildCalorieCard(
                  progress: calorieProgress,
                  remaining: calorieRemaining,
                ),
                const SizedBox(height: 14),
                _buildProgressCard(),
                const SizedBox(height: 18),
                _buildSectionHeader(
                  title: _t('Comidas de hoy', 'Today meals'),
                  actionLabel: _t('+ Agregar', '+ Add'),
                  onAction: _openFoodLogger,
                ),
                const SizedBox(height: 6),
                Text(
                  _t(
                    'Desliza una comida a los lados o mantenla presionada para eliminarla.',
                    'Swipe a meal sideways or long-press to delete it.',
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : const Color(0xFF6A8D76),
                  ),
                ),
                const SizedBox(height: 12),
                if (_todayLog.isEmpty)
                  _buildEmptyStateCard(
                    _t(
                      'Todavía no has registrado alimentos hoy.',
                      'You have not logged foods today yet.',
                    ),
                  )
                else
                  Column(
                    children: _todayLog
                        .map((entry) => _buildLogEntry(entry))
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartsContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                const SizedBox(height: 16),
                Text(
                  _t('Gráficas diarias', 'Daily Charts'),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF244B35),
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 20),
                _buildCalorieChartCard(),
                const SizedBox(height: 20),
                _buildWaterChartCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalorieChartCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double maxCal = 0;
    for (final c in _weeklyCalories) {
      if (c > maxCal) maxCal = c;
    }
    if (maxCal < _calorieGoal) maxCal = _calorieGoal;
    if (maxCal == 0) maxCal = 2000;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2922) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.24 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('Gráfica de calorías diarias', 'Daily calories chart'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF223F31),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCal * 1.2,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _weeklyLabels.length)
                          return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(_weeklyLabels[idx],
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.white70 : Colors.grey,
                              )),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: _calorieGoal,
                      color: (isDark
                              ? const Color(0xFFFFAAB3)
                              : const Color(0xFFE96C79))
                          .withOpacity(0.55),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                    ),
                  ],
                ),
                barGroups: List.generate(_weeklyCalories.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _weeklyCalories[i],
                        color: const Color(0xFF2E8A5E),
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterChartCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double maxWater = 8;
    for (final water in _weeklyWater) {
      if (water > maxWater) maxWater = water.toDouble();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2922) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.24 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('Gráfica de agua diaria', 'Daily water chart'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF223F31),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: math.max(10, maxWater * 1.2),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _weeklyLabels.length)
                          return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(_weeklyLabels[idx],
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.white70 : Colors.grey,
                              )),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 8,
                      color: (isDark
                              ? const Color(0xFF8DDEFF)
                              : const Color(0xFF38BDF8))
                          .withOpacity(0.6),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                    ),
                  ],
                ),
                barGroups: List.generate(_weeklyWater.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _weeklyWater[i].toDouble(),
                        color: const Color(0xFF38BDF8),
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainBottomNav() {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x142E8A5E),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildBottomNavItem(
                icon: Icons.home_rounded,
                label: _t('Inicio', 'Home'),
                active: _activeSection == 0,
                onTap: () => setState(() => _activeSection = 0),
              ),
            ),
            Expanded(
              child: _buildBottomNavItem(
                icon: Icons.receipt_long_rounded,
                label: _t('Registro', 'Log'),
                active: _activeSection == 1,
                onTap: () => setState(() => _activeSection = 1),
              ),
            ),
            Expanded(
              child: _buildBottomNavItem(
                icon: Icons.bar_chart_rounded,
                label: _t('Gráficas', 'Charts'),
                active: _activeSection == 2,
                onTap: () => setState(() => _activeSection = 2),
              ),
            ),
            Expanded(
              child: _buildBottomNavItem(
                icon: Icons.person_rounded,
                label: _t('Perfil', 'Profile'),
                active: _activeSection == 3,
                onTap: () => setState(() => _activeSection = 3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    bool active = false,
    required VoidCallback onTap,
  }) {
    final color = active ? const Color(0xFF2E8A5E) : const Color(0xFF8AA294);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTopBar() {
    return Row(
      children: [
        Image.asset(
          'assets/images/VerdeMeta - Iconografia.png',
          height: 22,
          fit: BoxFit.fitHeight,
          alignment: Alignment.centerLeft,
        ),
        const Spacer(),
        _buildUserMenu(
          backgroundColor: const Color(0xFFE9F7DD),
          foregroundColor: const Color(0xFF5E9F5F),
        ),
      ],
    );
  }

  Widget _buildSearchCard() {
    return InkWell(
      onTap: _openFoodLogger,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded,
                color: Color(0xFF6C4A39), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _t('Buscar', 'Search'),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFFB3ACA7),
                ),
              ),
            ),
            const Icon(Icons.notifications_rounded,
                color: Color(0xFF6C4A39), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeActionCard({
    required IconData icon,
    required String label,
    required Color background,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: background.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietPlannerSummaryCard() {
    final plan = _monthlyDietPlan;
    final avg = plan?.averageTotals;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5D7D0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFE96C79),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _t(
                    'Planificador de dieta mensual',
                    'Monthly diet planner',
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4F362C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            plan == null
                ? _t(
                    'Modo híbrido: el sistema genera el mes automáticamente y luego puedes personalizar platos por día sin tocar números.',
                    'Hybrid mode: the system auto-generates the month and you can personalize dishes by day without touching numbers.',
                  )
                : _t(
                    _monthlyPlanIsValid
                        ? 'Plan activo y validado: ${_monthLabel(plan.month)} ${plan.year} (${plan.dayCount} días).'
                        : 'Plan activo con ajustes pendientes: ${_monthLabel(plan.month)} ${plan.year}. Los días no válidos no se guardan al editar.',
                    _monthlyPlanIsValid
                        ? 'Active and validated plan: ${_monthLabel(plan.month)} ${plan.year} (${plan.dayCount} days).'
                        : 'Active plan with pending adjustments: ${_monthLabel(plan.month)} ${plan.year}. Invalid days cannot be saved while editing.',
                  ),
            style: const TextStyle(
              color: Color(0xFF7C6355),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          if (plan != null &&
              !_monthlyPlanIsValid &&
              _planSuggestionsByDay.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7EB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF5D7A3)),
              ),
              child: Text(
                _t(
                  'Días con sugerencias: ${_planSuggestionsByDay.keys.take(5).join(', ')}',
                  'Days with suggestions: ${_planSuggestionsByDay.keys.take(5).join(', ')}',
                ),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7A5A2E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (plan != null && avg != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMiniMacroTag(
                  'kcal',
                  '${avg.calories.toStringAsFixed(0)} / ${plan.targetCalories.toStringAsFixed(0)}',
                ),
                _buildMiniMacroTag(
                  _t('Prot', 'Prot'),
                  '${avg.protein.toStringAsFixed(0)} / ${plan.targetProtein.toStringAsFixed(0)}g',
                ),
                _buildMiniMacroTag(
                  _t('Carb', 'Carb'),
                  '${avg.carbs.toStringAsFixed(0)} / ${plan.targetCarbs.toStringAsFixed(0)}g',
                ),
                _buildMiniMacroTag(
                  _t('Grasa', 'Fat'),
                  '${avg.fat.toStringAsFixed(0)} / ${plan.targetFat.toStringAsFixed(0)}g',
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _openDietPlanner,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0x1AE96C79),
                    foregroundColor: const Color(0xFFC64B62),
                  ),
                  child: Text(_t('Generar plan', 'Generate plan')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: plan == null ? null : _showMonthlyPlanDetails,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E8A5E),
                  ),
                  child: Text(_t('Ver mes completo', 'View full month')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMacroTag(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FCF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDEBDD)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF466D54),
        ),
      ),
    );
  }

  Widget _buildBlurBubble(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.45,
            spreadRadius: size * 0.08,
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Image.asset(
          'assets/images/VerdeMeta - Iconografia.png',
          height: 50,
          width: 50,
          fit: BoxFit.fitHeight,
          alignment: Alignment.centerLeft,
        ),
        const Spacer(),
        _buildUserMenu(
          backgroundColor: const Color(0xFF2E8A5E),
          foregroundColor: Colors.white,
          boxShadow: [
            const BoxShadow(
              color: Color(0x1F2E8A5E),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserMenu({
    required Color backgroundColor,
    required Color foregroundColor,
    List<BoxShadow>? boxShadow,
  }) {
    return PopupMenuButton<_HomeMenuAction>(
      onSelected: _handleMenuAction,
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E2A23)
          : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _HomeMenuAction.settings,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.tune_rounded),
            title: Text(_t('Configuracion', 'Settings')),
          ),
        ),
        PopupMenuItem(
          value: _HomeMenuAction.feedback,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.trending_up_rounded),
            title: const Text('Feedback'),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _HomeMenuAction.measurements,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.straighten_rounded),
            title: Text(_t('Mediciones', 'Measurements')),
          ),
        ),
        PopupMenuItem(
          value: _HomeMenuAction.logout,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout_rounded),
            title: Text(_t('Cerrar sesión', 'Sign out')),
          ),
        ),
      ],
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: boxShadow,
        ),
        child: Center(
          child: Text(
            _avatarLetter,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalorieCard({
    required double progress,
    required double remaining,
  }) {
    final consumedCalories = _todayTotals.calories;
    final goalCalories = _calorieGoal;
    final consumedKcal = consumedCalories.toInt();
    final goalKcal = goalCalories.toInt();
    final overCalories = math.max(0.0, consumedCalories - goalCalories);
    final overCaloriesInt = overCalories.ceil();
    final hasOverconsumed = overCalories >= 1.0;
    final overProgress = goalCalories <= 0
        ? 0.0
        : (overCalories / goalCalories).clamp(0.0, 1.0).toDouble();
    final redLineProgress =
        hasOverconsumed ? math.max(overProgress, 0.06) : 0.0;
    final visualProgress = hasOverconsumed ? 1.0 : progress;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE1ECE3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x122E8A5E),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _t('Resumen de calorías', 'Calorie summary'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: Color(0xFF5E8570),
                ),
              ),
              const Spacer(),
              if (_profile != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x142E8A5E),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    _profile!.goal,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E8A5E),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 168,
            height: 168,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 16,
                    color: Color(0xFFE4EFE7),
                  ),
                ),
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: visualProgress,
                    strokeWidth: 16,
                    strokeCap: StrokeCap.round,
                    color: const Color(0xFF2E8A5E),
                    backgroundColor: Colors.transparent,
                  ),
                ),
                if (hasOverconsumed)
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: redLineProgress,
                      strokeWidth: 16,
                      strokeCap: StrokeCap.round,
                      color: const Color(0xFFFF2D2D),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      consumedKcal.toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: hasOverconsumed
                            ? const Color(0xFFFF2D2D)
                            : const Color(0xFF2E7D52),
                      ),
                    ),
                    const Text(
                      'KCAL',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: Color(0xFF7A9685),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatBlock(
                  _t('Meta', 'Goal'),
                  '$goalKcal kcal',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBlock(
                  hasOverconsumed
                      ? _t('Exceso', 'Over target')
                      : _t('Restante', 'Remaining'),
                  hasOverconsumed
                      ? '+$overCaloriesInt kcal'
                      : '${remaining.toStringAsFixed(0)} kcal',
                  valueColor: hasOverconsumed
                      ? const Color(0xFFFF2D2D)
                      : const Color(0xFF2E8A5E),
                ),
              ),
            ],
          ),
          if (hasOverconsumed) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF2D2D),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _t(
                      'Línea roja: superaste tu meta diaria de calorías.',
                      'Red line: you exceeded your daily calorie target.',
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF2D2D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBlock(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FAF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1ECE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Color(0xFF769080),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: valueColor ?? const Color(0xFF345646),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final progressItems = _progressItems;
    final hasNutrientOverage = progressItems.any(
      (item) =>
          item.showOverLine && item.target > 0 && item.current > item.target,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE1ECE3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x122E8A5E),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('MACRONUTRIENTES DEL DÍA', 'DAILY MACRONUTRIENTS'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: Color(0xFF5E8570),
            ),
          ),
          const SizedBox(height: 16),
          ...progressItems.map(_buildProgressBarItem),
          if (hasNutrientOverage) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF2D2D),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _t(
                      'Tramo rojo: aparece cuando ese nutriente supera su meta.',
                      'Red segment: appears when that nutrient exceeds its target.',
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF2D2D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ] else
            const SizedBox(height: 18),
          _buildWaterTrackerCard(),
        ],
      ),
    );
  }

  Widget _buildProgressBarItem(
      ({
        String label,
        double current,
        double target,
        Color color,
        String unit,
        bool isMacro,
        bool showOverLine,
      }) item) {
    final ratio = item.target <= 0 ? 0.0 : item.current / item.target;
    final progress = ratio.clamp(0.0, 1.0).toDouble();
    final overRatio = math.max(0.0, ratio - 1.0).clamp(0.0, 1.0).toDouble();
    final isOverTarget = item.target > 0 && item.current > item.target;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: item.color,
                  ),
                ),
              ),
              Text(
                '${_formatAmount(item.current, item.unit)}/${_formatAmount(item.target, item.unit)}',
                style: TextStyle(
                  fontSize: 13,
                  color: isOverTarget
                      ? const Color(0xFFFF2D2D)
                      : const Color(0xFF6A8D76),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              width: double.infinity,
              height: 8,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final fillWidth = progress <= 0
                      ? 0.0
                      : math.max(2.0, constraints.maxWidth * progress);
                  final markerWidth = isOverTarget
                      ? math.max(2.0, constraints.maxWidth * overRatio)
                      : 0.0;

                  return Stack(
                    children: [
                      const Positioned.fill(
                        child: ColoredBox(
                          color: Color(0xFFE3F0E4),
                        ),
                      ),
                      if (fillWidth > 0)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: fillWidth,
                            color: item.color,
                          ),
                        ),
                      if (isOverTarget && item.showOverLine)
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: markerWidth.clamp(0.0, constraints.maxWidth),
                            color: const Color(0xFFFF2D2D),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double value, String unit) {
    final needsDecimal =
        unit == 'mcg' || (value < 10 && (value - value.round()).abs() > 0.01);
    final formatted = value.toStringAsFixed(needsDecimal ? 1 : 0);
    return '$formatted$unit';
  }

  Widget _buildWaterTrackerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFEFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDEBDD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _t(
                    '💧 AGUA — $_todayWaterCups / 8 VASOS (${_waterLiters.toStringAsFixed(1)} L)',
                    '💧 WATER — $_todayWaterCups / 8 CUPS (${_waterLiters.toStringAsFixed(1)} L)',
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: Color(0xFF4C89B9),
                  ),
                ),
              ),
              GestureDetector(
                onLongPress: () {
                  if (_todayWaterCups > 0) {
                    _setWaterCups(_todayWaterCups - 1);
                    Feedback.forLongPress(context);
                  }
                },
                child: IconButton(
                  onPressed: () => _setWaterCups(_todayWaterCups + 1),
                  icon: const Icon(Icons.add_circle_outline_rounded,
                      color: Color(0xFF4C89B9)),
                  tooltip: _t('Añadir agua (Mantén presionado para restar)',
                      'Add water (Hold to subtract)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(8, (index) {
              final filled = index < _todayWaterCups;
              final nextValue = index < _todayWaterCups ? index : index + 1;

              return InkWell(
                onTap: () => _setWaterCups(nextValue),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: filled
                        ? const Color(0xFFDAF1FF)
                        : const Color(0xFFF3FBF2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: filled
                          ? const Color(0xFF7EC4F3)
                          : const Color(0xFFD5E7D8),
                    ),
                  ),
                  child: Icon(
                    filled ? Icons.water_drop_rounded : Icons.circle_outlined,
                    size: 18,
                    color: filled
                        ? const Color(0xFF4C89B9)
                        : const Color(0xFF7EA78A),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF244B35),
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              backgroundColor: const Color(0x1A2E8A5E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(
                color: Color(0xFF2E8A5E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyStateCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1ECE3)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF6A8D76),
          height: 1.4,
        ),
      ),
    );
  }

  String _normalizeRecipeKey(String value) {
    const accents = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };

    return value
        .toLowerCase()
        .split('')
        .map((char) => accents[char] ?? char)
        .join();
  }

  _RecipeDetail _recipeDetailFor(Food food) {
    final key = _normalizeRecipeKey(food.name);

    final loadedDetail = _recipeDetailsByKey[key];
    if (loadedDetail != null) {
      return loadedDetail;
    }

    if (key.contains('smoothie bowl de acai') ||
        key.contains('bowl de acai tropical')) {
      return _RecipeDetail(
        subtitle: _t(
          'Bowl espeso de açaí con granola y frutas frescas.',
          'Thick acai bowl with granola and fresh fruit.',
        ),
        ingredients: const [
          '2 paquetes de açaí congelado',
          '1 banana congelada',
          '1/2 taza de leche de coco',
          '30 g de granola',
          '50 g de frutas frescas',
        ],
        steps: [
          _t('Licúa el açaí con banana y leche.', 'Blend acai with banana and milk.'),
          _t('Sirve espeso en un bowl.', 'Serve thick in a bowl.'),
          _t('Decora con granola y frutas.', 'Top with granola and fruit.'),
        ],
      );
    }

    if (key.contains('bowl de avena')) {
      return _RecipeDetail(
        subtitle: _t(
          'Avena cremosa con frutos rojos y semillas.',
          'Creamy oats with berries and seeds.',
        ),
        ingredients: const [
          '60 g de avena en hojuelas',
          '250 ml de bebida vegetal',
          '80 g de frutos del bosque',
          '10 g de semillas de chía',
        ],
        steps: [
          _t('Cocina la avena con la bebida vegetal.', 'Cook oats with plant milk.'),
          _t('Sirve y agrega frutos del bosque.', 'Serve and add berries.'),
          _t('Termina con semillas de chía.', 'Finish with chia seeds.'),
        ],
      );
    }

    if (key.contains('tofu revuelto')) {
      return _RecipeDetail(
        subtitle: _t(
          'Tofu salteado con verduras para un desayuno proteico.',
          'Sauteed tofu with veggies for a high-protein breakfast.',
        ),
        ingredients: const [
          '150 g de tofu firme',
          '60 g de espinaca',
          '40 g de cebolla',
          '1 cda de levadura nutricional',
        ],
        steps: [
          _t('Desmenuza el tofu.', 'Crumble the tofu.'),
          _t('Saltea con cebolla y espinaca.', 'Saute with onion and spinach.'),
          _t('Añade levadura nutricional al final.', 'Add nutritional yeast at the end.'),
        ],
      );
    }

    if (key.contains('burrito bowl')) {
      return _RecipeDetail(
        subtitle: _t(
          'Bowl completo con frijoles, arroz y vegetales.',
          'Complete bowl with beans, rice and veggies.',
        ),
        ingredients: const [
          '120 g de frijoles cocidos',
          '120 g de arroz integral cocido',
          '70 g de maíz y pimiento',
          '40 g de guacamole',
        ],
        steps: [
          _t('Sirve arroz y frijoles como base.', 'Place rice and beans as base.'),
          _t('Agrega vegetales por encima.', 'Add veggies on top.'),
          _t('Termina con guacamole.', 'Finish with guacamole.'),
        ],
      );
    }

    return _RecipeDetail(
      subtitle: _t(
        'Preparación detallada no disponible todavía.',
        'Detailed preparation is not available yet.',
      ),
      ingredients: const [
        'Recarga la pantalla para cargar la receta completa',
      ],
      steps: [
        _t(
          'La receta detallada aún se está cargando o no está disponible en el catálogo.',
          'The detailed recipe is still loading or is unavailable in the catalog.',
        ),
      ],
    );
  }

  Future<void> _showRecipeDetailModal(Food food) async {
    final detail = _recipeDetailFor(food);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          maxChildSize: 0.92,
          minChildSize: 0.55,
          expand: false,
          builder: (context, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD5DBD6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(food.emoji, style: const TextStyle(fontSize: 34)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          food.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F3B2D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    detail.subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5D7668),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildMacroChip('${food.calories.toInt()}', _t('Kcal', 'Kcal')),
                      _buildMacroChip('${food.protein.toStringAsFixed(0)}g', _t('Proteína', 'Protein')),
                      _buildMacroChip('${food.carbs.toStringAsFixed(0)}g', _t('Carbos', 'Carbs')),
                      _buildMacroChip('${food.fat.toStringAsFixed(0)}g', _t('Grasas', 'Fat')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _t('Ingredientes', 'Ingredients'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF587164),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...detail.ingredients.map(
                    (ingredient) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF1EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.fiber_manual_record_rounded,
                            size: 8,
                            color: Color(0xFF3C6E51),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ingredient,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2F4D3C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _t('Preparación', 'Preparation'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF587164),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...detail.steps.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE4ECE6),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF3C6E51),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2F4D3C),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _addQuickFood(food);
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: Text(_t('Agregar al registro', 'Add to log')),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E8A5E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMacroChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1EB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6E2D9)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2E8A5E),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF5D7668),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFoodCard(Food food) {
    return InkWell(
      onTap: () => _showRecipeDetailModal(food),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6DED8)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 116,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF5D8),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Center(
                child: Text(
                  food.emoji,
                  style: const TextStyle(fontSize: 54),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                food.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4F362C),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7A614E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${food.calories.toInt()} kcal',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF806854),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogEntry(FoodLogEntry entry) {
    final emoji = _resolveEntryEmoji(entry);
    final dismissKey = entry.id != null
        ? 'log_${entry.id}'
        : 'log_${entry.loggedAt}_${entry.foodName}_${entry.quantity}';

    return Dismissible(
      key: ValueKey(dismissKey),
      direction: DismissDirection.horizontal,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.16,
        DismissDirection.endToStart: 0.16,
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: const Color(0xFFB84D65),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              _t('Eliminar', 'Delete'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFB84D65),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              _t('Eliminar', 'Delete'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        _deleteEntryWithOptimisticUi(entry);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => _deleteEntryWithOptimisticUi(entry),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE1ECE3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x102E8A5E),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0x142E8A5E),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.foodName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF2A4B38),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.mealTime} • ${entry.quantity.toInt()}g',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6A8D76),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3FBF2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${entry.calories.toInt()} kcal',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E8A5E),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
