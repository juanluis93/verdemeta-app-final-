import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/food_models.dart';
import '../repositories/food_repository.dart';
import '../widgets/food_logger_sheet.dart';
import 'profile_measurements_screen.dart';

enum _HomeMenuAction { settings, feedback, measurements, logout }

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
  late final FoodRepository _repo;
  late Locale _currentLocale;
  late ThemeMode _currentThemeMode;

  List<Food> _quickFoods = [];
  List<FoodLogEntry> _todayLog = [];
  Map<int, String> _emojiByFoodId = {};
  Map<String, String> _emojiByFoodName = {};
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
    _startDayChangeWatcher();
    _loadData();
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

  Future<void> _loadData() async {
    final todayKey = _todayKey;

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

      if (!mounted) return;
      setState(() {
        _quickFoods = quickFoods;
        _todayLog = todayLog;
        _todayTotals = totals;
        _todayWaterCups = waterCups;
        _profile = profile;
        _emojiByFoodId = emojiIndex.byId;
        _emojiByFoodName = emojiIndex.byName;
        _lastLoadedDayKey = todayKey;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      final fallbackFoods = kIsWeb ? _webPreviewFoods : <Food>[];
      final fallbackEmojiIndex = _buildEmojiIndex(fallbackFoods);

      setState(() {
        _quickFoods = fallbackFoods;
        _todayLog = [];
        _todayTotals = NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0);
        _todayWaterCups = 0;
        _profile = null;
        _emojiByFoodId = fallbackEmojiIndex.byId;
        _emojiByFoodName = fallbackEmojiIndex.byName;
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
    }
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
          await widget.onLogoutRequested(context);
        }
        break;
    }
  }

  String get _todayKey => DateTime.now().toIso8601String().split('T')[0];

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
    final nextValue = cups.clamp(0, 8);

    setState(() => _todayWaterCups = nextValue);

    if (kIsWeb) return;

    try {
      await _repo.saveWaterIntake(nextValue, _todayKey);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el agua de hoy.')),
      );
    }
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
            final sheetTitle =
                selectedLanguage == 'es' ? 'Configuracion' : 'Settings';
            final languageLabel =
                selectedLanguage == 'es' ? 'Idioma' : 'Language';
            final themeLabel =
                selectedLanguage == 'es' ? 'Tema oscuro' : 'Dark mode';
            final notificationsLabel =
                selectedLanguage == 'es' ? 'Notificaciones' : 'Notifications';
            final feedbackTitle = 'Feedback';
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
                      SwitchListTile.adaptive(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
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
                          setState(() => _notificationsEnabled = value);
                        },
                      ),
                      const SizedBox(height: 4),
                      SwitchListTile.adaptive(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
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
                        : _buildRegistroContent(
                            calorieProgress: calorieProgress,
                            calorieRemaining: calorieRemaining,
                          ),
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

  Widget _buildInicioContent() {
    final popularFoods =
        (_quickFoods.isNotEmpty ? _quickFoods : _webPreviewFoods)
            .take(8)
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
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4B2D20),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _t('Come saludable y vive vegano', 'Eat Healthy & Go Vegan'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5A3A2B),
                    height: 1.1,
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
                        onTap: () => _showComingSoon(_t('Recetas', 'Recipes')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildHomeActionCard(
                        icon: Icons.calendar_month_rounded,
                        label: _t('Planificador', 'Planner'),
                        background: const Color(0xFFE96C79),
                        onTap: () =>
                            _showComingSoon(_t('Planificador', 'Planner')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildHomeActionCard(
                        icon: Icons.storefront_rounded,
                        label: _t('Tienda', 'Store'),
                        background: const Color(0xFF6CBF72),
                        onTap: () => _showComingSoon(
                            _t('Buscador de tiendas', 'Store Finder')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      _t('Recetas populares', 'Popular Recipes'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF513327),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _showComingSoon('Lista completa'),
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF8D7558),
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
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFFCC80)),
                    ),
                    child: Text(
                      _loadError!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5D4037),
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
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF244B35),
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _prettyDate,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6A8D76),
                  ),
                ),
                if (_profile == null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF8ED),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF1D6A8)),
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
                              color: Color(0xFF7C623B),
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
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFFCC80)),
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
                              color: Color(0xFF5D4037),
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6A8D76),
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
                onTap: () => _showComingSoon(_t('Gráficas', 'Charts')),
              ),
            ),
            Expanded(
              child: _buildBottomNavItem(
                icon: Icons.person_rounded,
                label: _t('Perfil', 'Profile'),
                onTap: _openMeasurements,
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
        SizedBox(
          width: 14,
          height: 14,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Transform.scale(
              scale: 1.6,
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/images/logo.jpeg',
                fit: BoxFit.cover,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
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
        SizedBox(
          width: 29,
          height: 20,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Transform.scale(
              scale: 1.6,
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/images/logo.jpeg',
                fit: BoxFit.cover,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
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
          Text(
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

  Widget _buildQuickFoodCard(Food food) {
    return InkWell(
      onTap: () => _addQuickFood(food),
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
