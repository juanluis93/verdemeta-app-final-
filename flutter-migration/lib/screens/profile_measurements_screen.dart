import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/food_models.dart';
import '../repositories/food_repository.dart';
import '../services/food_name_translator.dart';

class _BodyCompEstimate {
  final double bmi;
  final String bmiCategory;
  final double bodyFatPct;
  final double bodyFatKg;
  final double musclePct;
  final double smi;
  final double leanBodyMass;
  final double muscleMass;
  final double boneMass;
  final double bonePct;
  final String boneCategory;
  final double waterMass;
  final double waterPct;
  final double waterIC;
  final double waterEC;
  final String waterStatus;
  final String bodyCategory;
  final String muscleCategory;
  final String precisionLabel;
  final String precisionError;
  final String precisionHint;

  const _BodyCompEstimate({
    required this.bmi,
    required this.bmiCategory,
    required this.bodyFatPct,
    required this.bodyFatKg,
    required this.musclePct,
    required this.smi,
    required this.leanBodyMass,
    required this.muscleMass,
    required this.boneMass,
    required this.bonePct,
    required this.boneCategory,
    required this.waterMass,
    required this.waterPct,
    required this.waterIC,
    required this.waterEC,
    required this.waterStatus,
    required this.bodyCategory,
    required this.muscleCategory,
    required this.precisionLabel,
    required this.precisionError,
    required this.precisionHint,
  });
}

class ProfileMeasurementsScreen extends StatefulWidget {
  final FoodRepository repository;
  final Locale locale;

  const ProfileMeasurementsScreen({
    super.key,
    required this.repository,
    required this.locale,
  });

  @override
  State<ProfileMeasurementsScreen> createState() =>
      _ProfileMeasurementsScreenState();
}

class _ProfileMeasurementsScreenState extends State<ProfileMeasurementsScreen> {
  static const _undesiredFoodsKey = 'planner_undesired_food_ids';
  static const List<String> _genderOptions = ['female', 'male', 'other'];
  static const List<String> _goalOptions = [
    'deficit',
    'maintain',
    'gain',
    'health',
  ];
  static const List<double> _activityOptions = [1.2, 1.375, 1.55, 1.725, 1.9];

  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  final _waistCtrl = TextEditingController();
  final _neckCtrl = TextEditingController();
  final _hipCtrl = TextEditingController();
  final _thighCtrl = TextEditingController();
  final _armCtrl = TextEditingController();
  final _calfCtrl = TextEditingController();

  late Locale _currentLocale;
  String _gender = 'female';
  String _goal = 'health';
  double _activity = 1.55;
  bool _saving = false;
  List<HealthCondition> _availableConditions = const [];
  Set<int> _selectedConditionIds = <int>{};
  List<Food> _availableFoods = const [];
  Set<int> _selectedUndesiredFoodIds = <int>{};

    bool get _isSpanish => _currentLocale.languageCode == 'es';

    bool get _isDark => Theme.of(context).brightness == Brightness.dark;

    Color get _accent =>
      _isDark ? const Color(0xFF7AD9A5) : const Color(0xFF2e7d52);

    Color get _accentStrong =>
      _isDark ? const Color(0xFF6CCF97) : const Color(0xFF2F7F53);

    Color get _labelColor =>
      _isDark ? const Color(0xFFB5C7BC) : const Color(0xFF5C846D);

    Color get _textPrimary =>
      _isDark ? const Color(0xFFE6F3EA) : const Color(0xFF345646);

    Color get _textSecondary =>
      _isDark ? const Color(0xFF9DB2A6) : const Color(0xFF5E8570);

    Color get _hintColor =>
      _isDark ? const Color(0xFF7E9387) : const Color(0xFFA5B9AB);

    Color get _inputFill =>
      _isDark ? const Color(0xFF1B2A22) : const Color(0xFFF2F8F0);

    Color get _inputBorder =>
      _isDark ? const Color(0xFF2E4036) : const Color(0xFFCFE1D3);

    Color get _inputFocused =>
      _isDark ? const Color(0xFF7AD9A5) : const Color(0xFF8DB69A);

    Color get _surface =>
      _isDark ? const Color(0xFF1B2A22) : const Color(0xFFFEFFFD);

    Color get _surfaceBorder =>
      _isDark ? const Color(0xFF2B3C31) : const Color(0xFFDDEBDD);

    Color get _chipBackground =>
      _isDark ? const Color(0xFF223229) : const Color(0x142E7D52);

    Color get _chipBorder =>
      _isDark ? const Color(0xFF2F4538) : const Color(0x332e7d52);

    Color get _sheetBackground =>
      _isDark ? const Color(0xFF1B2A22) : const Color(0xFFF9FCF8);

  String _t(String es, String en) => _isSpanish ? es : en;

  String _foodName(String name) {
    return FoodNameTranslator.translate(name, _currentLocale);
  }

  String _safeGender(String value) {
    return _genderOptions.contains(value) ? value : 'female';
  }

  String _safeGoal(String value) {
    return _goalOptions.contains(value) ? value : 'health';
  }

  double _safeActivity(double value) {
    if (_activityOptions.contains(value)) return value;

    double nearest = _activityOptions.first;
    for (final option in _activityOptions.skip(1)) {
      if ((option - value).abs() < (nearest - value).abs()) {
        nearest = option;
      }
    }
    return nearest;
  }

  @override
  void initState() {
    super.initState();
    _currentLocale = widget.locale;
    _loadProfile();
    _loadUndesiredFoods();
  }

  @override
  void didUpdateWidget(covariant ProfileMeasurementsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locale != widget.locale) {
      setState(() => _currentLocale = widget.locale);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _waistCtrl.dispose();
    _neckCtrl.dispose();
    _hipCtrl.dispose();
    _thighCtrl.dispose();
    _armCtrl.dispose();
    _calfCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final conditions = await widget.repository.getHealthConditions();
      if (mounted) {
        setState(() {
          _availableConditions = conditions;
        });
      }
    } catch (_) {
      // Keep the form usable even if conditions fail to load.
    }

    try {
      final profile = await widget.repository.getUserProfile();
      if (!mounted || profile == null) return;

      setState(() {
        _nameCtrl.text = profile.name;
        _ageCtrl.text = profile.age.toString();
        _weightCtrl.text = profile.weight.toString();
        _heightCtrl.text = profile.height.toString();
        _waistCtrl.text = profile.waist?.toString() ?? '';
        _neckCtrl.text = profile.neck?.toString() ?? '';
        _hipCtrl.text = profile.hip?.toString() ?? '';
        _thighCtrl.text = profile.thigh?.toString() ?? '';
        _armCtrl.text = profile.arm?.toString() ?? '';
        _calfCtrl.text = profile.calf?.toString() ?? '';
        _gender = _safeGender(profile.gender);
        _goal = _safeGoal(profile.goal);
        _activity = _safeActivity(profile.activityLevel);
        _selectedConditionIds = profile.diseaseIds.toSet();
      });
    } catch (_) {
      // If profile fails to load (for example on web preview), the form remains editable.
    }
  }

  Future<void> _loadUndesiredFoods() async {
    try {
      final foods = await widget.repository.getAllFoods();
      final prefs = await SharedPreferences.getInstance();
      final rawIds = prefs.getStringList(_undesiredFoodsKey) ?? const [];
      final parsedIds = rawIds
          .map((id) => int.tryParse(id))
          .whereType<int>()
          .toSet();

      if (!mounted) return;
      setState(() {
        _availableFoods = foods;
        _selectedUndesiredFoodIds = parsedIds;
      });
    } catch (_) {
      // Keep the form usable even if foods fail to load.
    }
  }

  Future<void> _pickConditions() async {
    if (_availableConditions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'No hay enfermedades disponibles en la base de datos.',
              'No health conditions are available in the database.',
            ),
          ),
        ),
      );
      return;
    }

    final tempSelection = Set<int>.from(_selectedConditionIds);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _sheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setLocalState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Selecciona enfermedades', 'Select conditions'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _accentStrong,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _availableConditions.length,
                        itemBuilder: (context, index) {
                          final condition = _availableConditions[index];
                          final selected = tempSelection.contains(condition.id);
                          return CheckboxListTile(
                            dense: true,
                            value: selected,
                            activeColor: _accent,
                            title: Text(condition.nombre),
                            subtitle: Text(
                              condition.descripcion,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onChanged: (value) {
                              setLocalState(() {
                                if (value == true) {
                                  tempSelection.add(condition.id);
                                } else {
                                  tempSelection.remove(condition.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedConditionIds = tempSelection;
                          });
                          Navigator.of(sheetContext).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _t('Aplicar selección', 'Apply selection'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _pickUndesiredFoods() async {
    if (_availableFoods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'No hay alimentos disponibles en la base de datos.',
              'No foods are available in the database.',
            ),
          ),
        ),
      );
      return;
    }

    final tempSelection = Set<int>.from(_selectedUndesiredFoodIds);
    final sortedFoods = [..._availableFoods]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _sheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setLocalState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Alimentos no deseados', 'Undesired foods'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _accentStrong,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: sortedFoods.length,
                        itemBuilder: (context, index) {
                          final food = sortedFoods[index];
                          final foodId = food.id;
                          if (foodId == null) {
                            return const SizedBox.shrink();
                          }
                          final selected = tempSelection.contains(foodId);
                          return CheckboxListTile(
                            dense: true,
                            value: selected,
                            activeColor: _accent,
                            title: Text('${food.emoji} ${_foodName(food.name)}'),
                            onChanged: (value) {
                              setLocalState(() {
                                if (value == true) {
                                  tempSelection.add(foodId);
                                } else {
                                  tempSelection.remove(foodId);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedUndesiredFoodIds = tempSelection;
                          });
                          Navigator.of(sheetContext).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _t('Aplicar seleccion', 'Apply selection'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  double? _parseOptional(String text) {
    final value = text.trim();
    if (value.isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  double _parseRequired(String text) {
    return double.parse(text.trim().replaceAll(',', '.'));
  }

  int _parseRequiredInt(String text) {
    return int.parse(text.trim());
  }

  int? _tryParseInt(String text) {
    final value = text.trim();
    if (value.isEmpty) return null;
    return int.tryParse(value);
  }

  double _normalizeLengthCm(double value) {
    if (value <= 0) return value;
    // Common input mistake: meters (1.70, 0.85)
    if (value < 3) return value * 100;
    // Optional safety: millimeters (1700)
    if (value >= 300) return value / 10;
    return value;
  }

  double? _normalizeOptionalLength(double? value) {
    if (value == null) return null;
    return _normalizeLengthCm(value);
  }

  double _round1(double value) => double.parse(value.toStringAsFixed(1));

  double _round2(double value) => double.parse(value.toStringAsFixed(2));

  String _bmiCategory(double bmi) {
    if (bmi < 18.5) return _t('Bajo peso', 'Underweight');
    if (bmi < 25.0) return _t('Normopeso', 'Normal weight');
    if (bmi < 30.0) return _t('Sobrepeso', 'Overweight');
    if (bmi < 35.0) return _t('Obesidad grado I', 'Obesity class I');
    if (bmi < 40.0) return _t('Obesidad grado II', 'Obesity class II');
    return _t('Obesidad morbida', 'Severe obesity');
  }

  String _fatCategory(double fatPct, String gender) {
    if (gender == 'female') {
      if (fatPct < 14) return _t('Atleta elite', 'Elite athlete');
      if (fatPct < 21) return _t('Atleta', 'Athlete');
      if (fatPct < 25) return _t('En forma', 'Fit');
      if (fatPct < 32) return _t('Aceptable', 'Acceptable');
      return _t('Sobrepeso graso', 'High body fat');
    }

    if (fatPct < 6) return _t('Atleta elite', 'Elite athlete');
    if (fatPct < 14) return _t('Atleta', 'Athlete');
    if (fatPct < 18) return _t('En forma', 'Fit');
    if (fatPct < 25) return _t('Aceptable', 'Acceptable');
    return _t('Sobrepeso graso', 'High body fat');
  }

  String _resolveBodyCategory({
    required double bmi,
    required String bmiCategory,
    required String fatCategory,
  }) {
    final elite = _t('Atleta elite', 'Elite athlete');
    final athlete = _t('Atleta', 'Athlete');
    final fit = _t('En forma', 'Fit');
    final overweight = _t('Sobrepeso', 'Overweight');
    // Safety guard: obesity by BMI should never be reported as athlete.
    if (bmi >= 30.0) return bmiCategory;

    // Avoid fitness labels when BMI already indicates overweight.
    if (bmi >= 25.0 &&
        (fatCategory == elite || fatCategory == athlete || fatCategory == fit)) {
      return overweight;
    }

    return fatCategory;
  }

  _BodyCompEstimate? _estimateBodyComp({
    required double weight,
    required double height,
    required String gender,
    required int age,
    required double? waist,
    required double? neck,
    required double? hip,
    required double? arm,
    required double? thigh,
    required double? calf,
  }) {
    final heightCm = _normalizeLengthCm(height);
    final waistCm = _normalizeOptionalLength(waist);
    final neckCm = _normalizeOptionalLength(neck);
    final hipCm = _normalizeOptionalLength(hip);
    final armCm = _normalizeOptionalLength(arm);
    final thighCm = _normalizeOptionalLength(thigh);
    final calfCm = _normalizeOptionalLength(calf);

    if (weight <= 0 || heightCm <= 0) return null;
    if (waistCm == null || waistCm <= 0 || neckCm == null || neckCm <= 0) {
      return null;
    }
    if (gender == 'female' && (hipCm == null || hipCm <= 0)) return null;

    // Keep preview visible while typing by clamping noisy/intermediate values.
    final safeHeightCm = heightCm.clamp(110.0, 250.0).toDouble();
    final safeNeckCm = neckCm.clamp(20.0, 70.0).toDouble();
    var safeWaistCm = waistCm.clamp(35.0, 220.0).toDouble();
    final safeHipCm = hipCm?.clamp(45.0, 240.0).toDouble();

    // For male equation, waist must be slightly larger than neck.
    if (gender == 'male' && safeWaistCm <= safeNeckCm + 0.5) {
      safeWaistCm = safeNeckCm + 0.5;
    }

    double toIn(double cm) => cm / 2.54;
    double log10(double x) => math.log(x) / math.ln10;

    final safeAge = age > 0 ? age.toDouble() : 25.0;
    final hM = safeHeightCm / 100;
    final sex = gender == 'male' ? 1.0 : 0.0;
    final heightIn = toIn(safeHeightCm);

    double navyFatPct;
    if (gender == 'female') {
      final logArg = toIn(safeWaistCm) + toIn(safeHipCm!) - toIn(safeNeckCm);
      if (logArg <= 0 || heightIn <= 0) return null;
      navyFatPct = 163.205 * log10(logArg) - 97.684 * log10(heightIn) - 78.387;
    } else {
      final logArg = toIn(safeWaistCm) - toIn(safeNeckCm);
      if (logArg <= 0 || heightIn <= 0) return null;
      navyFatPct = 86.010 * log10(logArg) - 70.041 * log10(heightIn) + 36.76;
    }

    if (!navyFatPct.isFinite) return null;

    final bmi = weight / (hM * hM);
    final sexIndex = gender == 'male' ? 1.0 : 0.0;
    var bmiFatPct = 1.20 * bmi + 0.23 * safeAge - 10.8 * sexIndex - 5.4;
    bmiFatPct = bmiFatPct.clamp(gender == 'female' ? 10.0 : 5.0, 55.0);

    var rfmFatPct = (gender == 'female' ? 76.0 : 64.0) -
        (20.0 * safeHeightCm / safeWaistCm);
    if (gender == 'female' && safeHipCm != null) {
      rfmFatPct += ((safeHipCm - safeWaistCm) / 18.0).clamp(-2.0, 6.0);
    }
    rfmFatPct = rfmFatPct.clamp(gender == 'female' ? 10.0 : 5.0, 60.0);

    var fatPct = navyFatPct;
    final navyTooLow = gender == 'female' ? navyFatPct < 8.0 : navyFatPct < 4.0;
    final navyTooHigh = navyFatPct > 55.0;

    if (navyTooLow || navyTooHigh) {
      fatPct = (rfmFatPct * 0.60) + (bmiFatPct * 0.40);
    }

    final minFat = gender == 'female' ? 8.0 : 4.0;
    fatPct = _round1(fatPct.clamp(minFat, 60.0).toDouble());

    final fatKg = _round1(weight * fatPct / 100);
    final lbm = _round1(weight - fatKg);

    var smmLee =
        (0.244 * weight + 7.80 * hM + 6.6 * sex - 0.098 * safeAge + 1.2 - 3.3) *
            0.85;
    smmLee = math.max(5.0, smmLee);

    final smmModels = <double>[smmLee];
    final smmWeights = <double>[1.0];

    if (calfCm != null && calfCm >= 20 && calfCm <= 58) {
      final refHcc = gender == 'male' ? 1.75 : 1.63;
      var almCc =
          gender == 'male' ? (0.65 * calfCm - 4.3) : (0.52 * calfCm - 2.1);
      almCc = math.max(5.0, almCc);
      almCc *= math.pow(hM / refHcc, 0.6).toDouble();
      almCc *= math.max(0.78, 1.0 - math.max(0.0, safeAge - 30) * 0.004);
      final smmCc = math.max(5.0, almCc * 1.3);
      smmModels.add(smmCc);
      smmWeights.add(1.8);
    }

    if (armCm != null && armCm >= 18 && armCm <= 55) {
      final refHArm = gender == 'male' ? 1.75 : 1.63;
      final refMac = gender == 'male' ? 32.0 : 27.0;
      final baseAlm = gender == 'male' ? 32.0 * 0.55 : 27.0 * 0.48;
      final deltaAlm = (armCm - refMac) * (gender == 'male' ? 0.55 : 0.48);
      var almArm = math.max(5.0, baseAlm + deltaAlm);
      almArm *= math.pow(hM / refHArm, 0.5).toDouble();
      almArm *= math.max(0.78, 1.0 - math.max(0.0, safeAge - 30) * 0.004);
      final smmArm = math.max(5.0, almArm * 1.3);
      smmModels.add(smmArm);
      smmWeights.add(1.5);
    }

    var thighCorrection = 0.0;
    if (thighCm != null && thighCm >= 30 && thighCm <= 85) {
      final refThigh = gender == 'male' ? 56.0 : 54.0;
      final scale = gender == 'male' ? 0.30 : 0.25;
      thighCorrection = (thighCm - refThigh) * scale * 0.4;
    }

    final totalW = smmWeights.reduce((a, b) => a + b);
    var muscleKg = 0.0;
    for (int i = 0; i < smmModels.length; i++) {
      muscleKg += smmModels[i] * smmWeights[i];
    }
    muscleKg = (muscleKg / totalW) + (thighCorrection * 0.5);

    final minSmm = weight * (gender == 'female' ? 0.20 : 0.25);
    final maxSmm = weight * (gender == 'male' ? 0.55 : 0.48);
    muscleKg = _round1(muscleKg.clamp(minSmm, maxSmm).toDouble());

    final musclePct = _round1((muscleKg / weight) * 100);
    final smi = _round1(muscleKg / (hM * hM));

    final modelCount = smmModels.length;
    final precision = switch (modelCount) {
      1 => (
          label: _t('Estimacion basica', 'Basic estimate'),
          error: '±15%',
          hint: _t(
            'Agrega brazo y pantorrilla para mejorar precision',
            'Add arm and calf to improve precision',
          ),
        ),
      2 => (
          label: _t('Estimacion moderada', 'Moderate estimate'),
          error: '±9%',
          hint: _t(
            'Agrega la otra medida para mejorar precision',
            'Add the other measurement to improve precision',
          ),
        ),
      _ => (
          label: _t('Estimacion avanzada', 'Advanced estimate'),
          error: '±6%',
          hint: _t(
            'Alta confianza con multiples medidas',
            'High confidence with multiple measurements',
          ),
        ),
    };

    final muscleCategory = gender == 'male'
        ? (smi < 7.0
        ? _t('Sarcopenia', 'Sarcopenia')
            : smi < 8.5
          ? _t('Normal', 'Normal')
          : _t('Optimo', 'Optimal'))
        : (smi < 5.7
        ? _t('Sarcopenia', 'Sarcopenia')
            : smi < 6.8
          ? _t('Normal', 'Normal')
          : _t('Optimo', 'Optimal'));

    final refH = gender == 'female' ? 163.0 : 175.0;
    final boneK = gender == 'female' ? 0.038 : 0.045;
    var boneKg = boneK * weight * math.pow(safeHeightCm / refH, 0.3).toDouble();
    if (safeAge > 40) {
      boneKg *= math.max(0.75, 1 - (safeAge - 40) * 0.01);
    }
    boneKg = _round2(boneKg.clamp(1.5, 6.0).toDouble());
    final bonePct = _round1((boneKg / weight) * 100);
    final boneRef = gender == 'female' ? 2.8 : 3.8;
    final boneCategory = boneKg >= boneRef * 1.1
      ? _t('Densidad alta', 'High density')
        : boneKg >= boneRef * 0.9
        ? _t('Densidad normal', 'Normal density')
            : boneKg >= boneRef * 0.75
          ? _t('Densidad baja', 'Low density')
          : _t('Densidad muy baja', 'Very low density');

    var waterMass = gender == 'female'
        ? -2.097 + 0.1069 * safeHeightCm + 0.2466 * weight
        : 2.447 - 0.09516 * safeAge + 0.1074 * safeHeightCm + 0.3362 * weight;
    waterMass = _round1(waterMass.clamp(10.0, 80.0).toDouble());
    final waterPct = _round1((waterMass / weight) * 100);
    final waterIC = _round1(waterMass * 0.67);
    final waterEC = _round1(waterMass * 0.33);
    final normalWaterRange = gender == 'female' ? (45.0, 60.0) : (50.0, 65.0);
    final waterStatus = waterPct < normalWaterRange.$1
      ? _t('Bajo rango', 'Low range')
      : waterPct <= normalWaterRange.$2
        ? _t('Normal', 'Normal')
        : _t('Posible retencion', 'Possible retention');

    final bmiCategory = _bmiCategory(bmi);
    final fatCategory = _fatCategory(fatPct, gender);
    final bodyCategory = _resolveBodyCategory(
      bmi: bmi,
      bmiCategory: bmiCategory,
      fatCategory: fatCategory,
    );

    return _BodyCompEstimate(
      bmi: _round1(bmi),
      bmiCategory: bmiCategory,
      bodyFatPct: fatPct,
      bodyFatKg: fatKg,
      musclePct: musclePct,
      smi: smi,
      leanBodyMass: lbm,
      muscleMass: muscleKg,
      boneMass: boneKg,
      bonePct: bonePct,
      boneCategory: boneCategory,
      waterMass: waterMass,
      waterPct: waterPct,
      waterIC: waterIC,
      waterEC: waterEC,
      waterStatus: waterStatus,
      bodyCategory: bodyCategory,
      muscleCategory: muscleCategory,
      precisionLabel: precision.label,
      precisionError: precision.error,
      precisionHint: precision.hint,
    );
  }

  ({double calorie, double protein, double carbs, double fat}) _calcTargets({
    required double weight,
    required double height,
    required int age,
    required String gender,
    required double activity,
    required String goal,
    double? leanBodyMass,
    List<HealthCondition> conditions = const [],
  }) {
    final safeWeight = weight.clamp(35.0, 300.0).toDouble();
    final safeHeight =
        _normalizeLengthCm(height).clamp(130.0, 230.0).toDouble();
    final safeAge = age.clamp(14, 90);
    final safeActivity = activity.clamp(1.2, 1.9).toDouble();

    final genderConstant = switch (gender) {
      'male' => 5,
      'female' => -161,
      _ => -78,
    };

    final mifflinBmr = (10 * safeWeight) +
        (6.25 * safeHeight) -
        (5 * safeAge) +
        genderConstant;
    final katchBmr = leanBodyMass != null && leanBodyMass > 0
        ? 370 + (21.6 * leanBodyMass)
        : null;

    final bmr =
        katchBmr == null ? mifflinBmr : (mifflinBmr * 0.40) + (katchBmr * 0.60);
    double calorie = bmr * safeActivity;

    final goalFactor = switch (goal) {
      'deficit' => 0.85,
      'gain' => 1.10,
      _ => 1.0,
    };
    calorie *= goalFactor;

    final minCalorie = safeWeight * 22;
    final maxCalorie = safeWeight * 42;
    calorie = calorie.clamp(minCalorie, maxCalorie).toDouble();

    final proteinByWeight = switch (goal) {
      'deficit' => safeWeight * 2.0,
      'gain' => safeWeight * 1.8,
      'maintain' => safeWeight * 1.6,
      _ => safeWeight * 1.4,
    };

    var protein = proteinByWeight;
    if (leanBodyMass != null && leanBodyMass > 0) {
      final proteinByLbm = switch (goal) {
        'deficit' => leanBodyMass * 2.4,
        'gain' => leanBodyMass * 2.1,
        'maintain' => leanBodyMass * 2.0,
        _ => leanBodyMass * 1.8,
      };
      protein = math.max(protein, proteinByLbm);
    }

    protein = protein.clamp(safeWeight * 1.2, safeWeight * 2.4).toDouble();

    final minFatPerKg = switch (gender) {
      'female' => 0.9,
      'male' => 0.7,
      _ => 0.8,
    };
    final fatPct = switch (goal) {
      'deficit' => 0.30,
      'gain' => 0.25,
      _ => 0.28,
    };

    var fat = math.max(safeWeight * minFatPerKg, (calorie * fatPct) / 9);
    fat = fat.clamp(safeWeight * minFatPerKg, safeWeight * 1.3).toDouble();

    var carbs = (calorie - (protein * 4) - (fat * 9)) / 4;
    final minCarbsPerKg = switch (goal) {
      'deficit' => 1.8,
      'gain' => 2.8,
      'maintain' => 2.3,
      _ => 2.0,
    };
    final minCarbs = safeWeight * minCarbsPerKg;
    final maxCarbs = safeWeight * 6;
    carbs = carbs.clamp(minCarbs, maxCarbs).toDouble();

    calorie = (protein * 4) + (fat * 9) + (carbs * 4);

    if (conditions.isNotEmpty) {
      final calorieAdjPct = conditions
          .fold<double>(0, (acc, c) => acc + c.ajusteCalorias)
          .clamp(-35.0, 25.0);
      final proteinAdjPct = conditions
          .fold<double>(0, (acc, c) => acc + c.ajusteProteinas)
          .clamp(-30.0, 30.0);
      final carbsAdjPct = conditions
          .fold<double>(0, (acc, c) => acc + c.ajusteCarbohidratos)
          .clamp(-35.0, 35.0);
      final fatAdjPct = conditions
          .fold<double>(0, (acc, c) => acc + c.ajusteGrasas)
          .clamp(-30.0, 30.0);

      final adjustedCalories =
          (calorie * (1 + (calorieAdjPct / 100))).clamp(minCalorie, maxCalorie);

      final adjustedProtein = protein * (1 + (proteinAdjPct / 100));
      final adjustedCarbs = carbs * (1 + (carbsAdjPct / 100));
      final adjustedFat = fat * (1 + (fatAdjPct / 100));

      final macroKcalProtein = adjustedProtein * 4;
      final macroKcalCarbs = adjustedCarbs * 4;
      final macroKcalFat = adjustedFat * 9;
      final macroKcalTotal = macroKcalProtein + macroKcalCarbs + macroKcalFat;

      if (macroKcalTotal > 0) {
        var proteinPct = (macroKcalProtein / macroKcalTotal).clamp(0.18, 0.45);
        var carbsPct = (macroKcalCarbs / macroKcalTotal).clamp(0.15, 0.60);
        var fatPctAdjusted = (macroKcalFat / macroKcalTotal).clamp(0.20, 0.45);

        final pctSum = proteinPct + carbsPct + fatPctAdjusted;
        proteinPct /= pctSum;
        carbsPct /= pctSum;
        fatPctAdjusted /= pctSum;

        protein = (adjustedCalories * proteinPct) / 4;
        carbs = (adjustedCalories * carbsPct) / 4;
        fat = (adjustedCalories * fatPctAdjusted) / 9;
        calorie = adjustedCalories.toDouble();
      }
    }

    calorie = (protein * 4) + (fat * 9) + (carbs * 4);

    return (
      calorie: _round1(calorie),
      protein: _round1(protein),
      carbs: _round1(carbs),
      fat: _round1(fat),
    );
  }

  Future<void> _save() async {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Completa los campos requeridos: nombre, edad, peso y altura.',
              'Complete the required fields: name, age, weight, and height.',
            ),
          ),
        ),
      );
      return;
    }

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'En web es solo vista previa. Puedes ver estimaciones aqui, pero para guardar medidas usa Android o escritorio.',
              'On web this is preview only. You can see estimates here, but to save measurements use Android or desktop.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    var shouldResetSaving = true;

    try {
      final age = _parseRequiredInt(_ageCtrl.text);
      final weight = _parseRequired(_weightCtrl.text);
      final height = _normalizeLengthCm(_parseRequired(_heightCtrl.text));
      final waist = _normalizeOptionalLength(_parseOptional(_waistCtrl.text));
      final neck = _normalizeOptionalLength(_parseOptional(_neckCtrl.text));
      final hip = _normalizeOptionalLength(_parseOptional(_hipCtrl.text));
      final thigh = _normalizeOptionalLength(_parseOptional(_thighCtrl.text));
      final arm = _normalizeOptionalLength(_parseOptional(_armCtrl.text));
      final calf = _normalizeOptionalLength(_parseOptional(_calfCtrl.text));

      final bodyComp = _estimateBodyComp(
        weight: weight,
        height: height,
        gender: _gender,
        age: age,
        waist: waist,
        neck: neck,
        hip: hip,
        thigh: thigh,
        arm: arm,
        calf: calf,
      );

      final targets = _calcTargets(
        weight: weight,
        height: height,
        age: age,
        gender: _gender,
        activity: _activity,
        goal: _goal,
        leanBodyMass: bodyComp?.leanBodyMass,
        conditions: _availableConditions
            .where((c) => _selectedConditionIds.contains(c.id))
            .toList(),
      );

      final prefs = await SharedPreferences.getInstance();
      final ids = _selectedUndesiredFoodIds.map((id) => id.toString()).toList();
      await prefs.setStringList(_undesiredFoodsKey, ids);

      final profile = UserProfile(
        name: _nameCtrl.text.trim(),
        age: age,
        gender: _gender,
        weight: weight,
        height: height,
        activityLevel: _activity,
        goal: _goal,
        diseaseIds: _selectedConditionIds.toList()..sort(),
        waist: waist,
        neck: neck,
        hip: hip,
        thigh: thigh,
        arm: arm,
        calf: calf,
        calorieTarget: targets.calorie,
        proteinTarget: targets.protein,
        carbsTarget: targets.carbs,
        fatTarget: targets.fat,
        bodyFatPct: bodyComp?.bodyFatPct,
        musclePct: bodyComp?.musclePct,
        leanBodyMass: bodyComp?.leanBodyMass,
        muscleMass: bodyComp?.muscleMass,
        boneMass: bodyComp?.boneMass,
        waterMass: bodyComp?.waterMass,
      );

      await widget.repository.saveUserProfile(profile);

      if (!mounted) return;
      shouldResetSaving = false;
      setState(() => _saving = false);
      Navigator.of(context).pop(true);
      return;
    } catch (e) {
      if (!mounted) return;

      var errorText = _t('No se pudo guardar: $e', 'Could not save: $e');
      final raw = e.toString().toLowerCase();
      if (raw.contains('databasefactory not initialized')) {
        errorText = _t(
          'No se pudo iniciar la base de datos local. Reinicia la app y vuelve a intentar.',
          'Local database failed to initialize. Restart the app and try again.',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorText)),
      );
    } finally {
      if (mounted && shouldResetSaving) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: _labelColor,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            onChanged: onChanged ?? (_) => setState(() {}),
            style: TextStyle(
              fontSize: 16,
              color: _textPrimary,
            ),
            decoration: _mobileInputDecoration(hint: hint),
          ),
        ],
      ),
    );
  }

  InputDecoration _mobileInputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: _inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(
        color: _hintColor,
        fontSize: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _inputFocused, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFB84D65)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFB84D65), width: 1.4),
      ),
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: _labelColor,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: (v) {
              setState(() => onChanged(v));
            },
            decoration: _mobileInputDecoration(),
            style: TextStyle(
              fontSize: 16,
              color: _textPrimary,
            ),
            dropdownColor:
                _isDark ? const Color(0xFF18251F) : const Color(0xFFF8FCF8),
            iconEnabledColor: _labelColor,
          ),
        ],
      ),
    );
  }

  Widget _fieldPair(Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            children: [left, right],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  Widget _infoMetric({
    required String value,
    required String label,
    Color color = const Color(0xFF1F5E3D),
    bool highlighted = false,
  }) {
    final bg = highlighted
        ? _accent.withOpacity(_isDark ? 0.22 : 0.12)
        : (_isDark ? const Color(0xFF1C2C23) : Colors.white);
    final border = highlighted
        ? _accent.withOpacity(_isDark ? 0.35 : 0.25)
        : (_isDark ? const Color(0xFF2E4036) : const Color(0xFFE2E8E4));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: _isDark ? const Color(0xFF9DB2A6) : const Color(0xFF4F6F5E),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String text, {Color bg = const Color(0x142e7d52)}) {
    final bgColor = _isDark ? const Color(0xFF223229) : bg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _chipBorder),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _isDark ? const Color(0xFFBFE7D2) : const Color(0xFF1F5E3D),
        ),
      ),
    );
  }

  Widget _compositionBar(_BodyCompEstimate comp) {
    final muscle = comp.musclePct.clamp(0, 100).toDouble();
    final fat = comp.bodyFatPct.clamp(0, 100).toDouble();
    final water = math.min(20.0, comp.waterPct * 0.4);
    final bone = comp.bonePct.clamp(0, 100).toDouble();
    final rest = math.max(0.0, 100 - muscle - fat - water - bone);

    int toFlex(double pct) => math.max(1, (pct * 10).round());

    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 14,
        child: Row(
          children: [
            if (muscle > 0)
              Expanded(
                flex: toFlex(muscle),
                child: Container(color: const Color(0xFF2e7d52)),
              ),
            if (fat > 0)
              Expanded(
                flex: toFlex(fat),
                child: Container(color: const Color(0xFFb84d65)),
              ),
            if (water > 0)
              Expanded(
                flex: toFlex(water),
                child: Container(color: const Color(0xFF3a82aa)),
              ),
            if (bone > 0)
              Expanded(
                flex: toFlex(bone),
                child: Container(color: const Color(0xFFa05a2a)),
              ),
            Expanded(
              flex: toFlex(rest),
              child: Container(color: const Color(0xFFDFF0DF)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark;
    final selectedGender = _safeGender(_gender);
    final selectedGoal = _safeGoal(_goal);
    final selectedActivity = _safeActivity(_activity);

    final agePreview = _tryParseInt(_ageCtrl.text);
    final weightPreview = _parseOptional(_weightCtrl.text);
    final rawHeightPreview = _parseOptional(_heightCtrl.text);
    final heightPreview =
        rawHeightPreview == null ? null : _normalizeLengthCm(rawHeightPreview);
    final waistPreview =
        _normalizeOptionalLength(_parseOptional(_waistCtrl.text));
    final neckPreview =
        _normalizeOptionalLength(_parseOptional(_neckCtrl.text));
    final hipPreview = _normalizeOptionalLength(_parseOptional(_hipCtrl.text));
    final thighPreview =
        _normalizeOptionalLength(_parseOptional(_thighCtrl.text));
    final armPreview = _normalizeOptionalLength(_parseOptional(_armCtrl.text));
    final calfPreview =
        _normalizeOptionalLength(_parseOptional(_calfCtrl.text));

    final hasRequiredPreviewData = agePreview != null &&
        weightPreview != null &&
        heightPreview != null &&
        weightPreview > 0 &&
        heightPreview > 0;

    final previewBodyComp = hasRequiredPreviewData
        ? _estimateBodyComp(
            weight: weightPreview,
            height: heightPreview,
            gender: _gender,
            age: agePreview,
            waist: waistPreview,
            neck: neckPreview,
            hip: hipPreview,
            thigh: thighPreview,
            arm: armPreview,
            calf: calfPreview,
          )
        : null;

    final previewTargets = hasRequiredPreviewData
        ? _calcTargets(
            weight: weightPreview,
            height: heightPreview,
            age: agePreview,
            gender: _gender,
            activity: _activity,
            goal: _goal,
            leanBodyMass: previewBodyComp?.leanBodyMass,
            conditions: _availableConditions
                .where((c) => _selectedConditionIds.contains(c.id))
                .toList(),
          )
        : null;

    final selectedConditions = _availableConditions
        .where((c) => _selectedConditionIds.contains(c.id))
        .toList();

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F1914) : const Color(0xFFF7FBF7),
        appBar: AppBar(
          leading: IconButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(_t('Mis medidas', 'My measurements')),
          backgroundColor: Colors.transparent,
          foregroundColor: _accent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [
                      Color(0xFF0F1914),
                      Color(0xFF11241A),
                      Color(0xFF14291D),
                    ]
                  : const [
                      Color(0xFFF9FCF8),
                      Color(0xFFF2FAF4),
                      Color(0xFFE8F8F1),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _surfaceBorder),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? const Color(0x1A000000)
                                  : const Color(0x142e7d52),
                              blurRadius: 28,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _t('¡Hola! Cuéntame sobre ti', 'Hi! Tell me about you'),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _accentStrong,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _t(
                                'Estos datos me permiten calcular tus macros y composición corporal',
                                'These details help me calculate your macros and body composition',
                              ),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: _textSecondary,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 22),
                            _field(
                              _t('Tu nombre', 'Your name'),
                              _nameCtrl,
                              hint: _t('Ej: Juan', 'E.g. Alex'),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? _t('Requerido', 'Required')
                                  : null,
                            ),
                            _fieldPair(
                              _field(
                                _t('Edad', 'Age'),
                                _ageCtrl,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return _t('Requerido', 'Required');
                                  }
                                  final n = int.tryParse(v.trim());
                                  if (n == null || n < 10 || n > 100) {
                                    return _t('Edad invalida', 'Invalid age');
                                  }
                                  return null;
                                },
                              ),
                              _dropdownField<String>(
                                label: _t('Género', 'Gender'),
                                value: selectedGender,
                                items: [
                                  DropdownMenuItem(
                                    value: 'female',
                                    child: Text(_t('Mujer', 'Female')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'male',
                                    child: Text(_t('Hombre', 'Male')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'other',
                                    child: Text(_t('Otro', 'Other')),
                                  ),
                                ],
                                onChanged: (v) =>
                                    _gender = _safeGender(v ?? 'female'),
                              ),
                            ),
                            Text(
                              _t(
                                'Uso sexo biologico para ecuaciones fisiologicas (BMR, % grasa y objetivos de micronutrientes), por eso los resultados cambian entre mujer y hombre.',
                                'I use biological sex for physiological equations (BMR, body fat %, and micronutrient targets), so results differ between women and men.',
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: _textSecondary,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _fieldPair(
                              _field(
                                _t('Peso (kg)', 'Weight (kg)'),
                                _weightCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return _t('Requerido', 'Required');
                                  }
                                  final n =
                                      double.tryParse(v.replaceAll(',', '.'));
                                  if (n == null || n <= 0) {
                                    return _t('Valor invalido', 'Invalid value');
                                  }
                                  return null;
                                },
                              ),
                              _field(
                                _t('Altura (cm)', 'Height (cm)'),
                                _heightCtrl,
                                hint: _t('Ej: 170 o 1.70', 'E.g. 170 or 1.70'),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return _t('Requerido', 'Required');
                                  }
                                  final n =
                                      double.tryParse(v.replaceAll(',', '.'));
                                  if (n == null || n <= 0) {
                                    return _t('Valor invalido', 'Invalid value');
                                  }
                                  return null;
                                },
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1D2B23)
                                    : const Color(0xFFF3FBF2),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF2F4538)
                                      : const Color(0xFFD3E6D6),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _t(
                                      '📏 MEDIDAS PARA COMPOSICIÓN CORPORAL',
                                      '📏 BODY COMPOSITION MEASUREMENTS',
                                    ),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: .8,
                                      color: _accentStrong,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _t(
                                      'Mide en la parte más estrecha (cintura), más ancha (cadera/muslo) y a nivel de la nuez de Adán (cuello).',
                                      'Measure at the narrowest point (waist), widest point (hip/thigh), and at the Adam\'s apple level (neck).',
                                    ),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: _textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _fieldPair(
                                    _field(
                                      _t('Cintura (cm)', 'Waist (cm)'),
                                      _waistCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                    ),
                                    _field(
                                      _t('Cuello (cm)', 'Neck (cm)'),
                                      _neckCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                    ),
                                  ),
                                  _fieldPair(
                                    Opacity(
                                      opacity: _gender == 'male' ? 0.65 : 1,
                                      child: _field(
                                        _t('Cadera (cm)', 'Hip (cm)'),
                                        _hipCtrl,
                                        hint: _t('cm', 'cm'),
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                      ),
                                    ),
                                    _field(
                                      _t('Muslo (cm) (opcional)', 'Thigh (cm) (optional)'),
                                      _thighCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                    ),
                                  ),
                                  _fieldPair(
                                    _field(
                                      _t('Brazo (cm) 💪 mejora precision', 'Arm (cm) 💪 improves precision'),
                                      _armCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                    ),
                                    _field(
                                      _t('Pantorrilla (cm) 🦵 mejora precision', 'Calf (cm) 🦵 improves precision'),
                                      _calfCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _t(
                                      '📐 Brazo: mide en el punto más ancho del bíceps relajado. Pantorrilla: mide en el punto más ancho de la pantorrilla de pie.',
                                      '📐 Arm: measure at the widest point of a relaxed biceps. Calf: measure at the widest point while standing.',
                                    ),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: _textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            _dropdownField<String>(
                              label: _t('Objetivo', 'Goal'),
                              value: selectedGoal,
                              items: [
                                DropdownMenuItem(
                                  value: 'deficit',
                                  child: Text(_t('Perder peso', 'Lose weight')),
                                ),
                                DropdownMenuItem(
                                  value: 'maintain',
                                  child: Text(_t('Mantener', 'Maintain')),
                                ),
                                DropdownMenuItem(
                                  value: 'gain',
                                  child: Text(_t('Ganar musculo', 'Gain muscle')),
                                ),
                                DropdownMenuItem(
                                  value: 'health',
                                  child: Text(_t('Salud', 'Health')),
                                ),
                              ],
                              onChanged: (v) =>
                                  _goal = _safeGoal(v ?? 'health'),
                            ),
                            _dropdownField<double>(
                              label: _t('Actividad', 'Activity'),
                              value: selectedActivity,
                              items: [
                                DropdownMenuItem(
                                  value: 1.2,
                                  child: Text(_t('Sedentario', 'Sedentary')),
                                ),
                                DropdownMenuItem(
                                  value: 1.375,
                                  child: Text(_t('Ligero', 'Light')),
                                ),
                                DropdownMenuItem(
                                  value: 1.55,
                                  child: Text(_t('Moderado', 'Moderate')),
                                ),
                                DropdownMenuItem(
                                  value: 1.725,
                                  child: Text(_t('Activo', 'Active')),
                                ),
                                DropdownMenuItem(
                                  value: 1.9,
                                  child: Text(_t('Muy activo', 'Very active')),
                                ),
                              ],
                              onChanged: (v) =>
                                  _activity = _safeActivity(v ?? 1.55),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _t('ALIMENTOS NO DESEADOS', 'UNDESIRED FOODS'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                      color: _labelColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: _pickUndesiredFoods,
                                    borderRadius: BorderRadius.circular(14),
                                    child: InputDecorator(
                                      decoration: _mobileInputDecoration(),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _selectedUndesiredFoodIds.isEmpty
                                                  ? _t('Seleccionar alimentos', 'Select foods')
                                                  : _t(
                                                      '${_selectedUndesiredFoodIds.length} seleccionados',
                                                      '${_selectedUndesiredFoodIds.length} selected',
                                                    ),
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: _textPrimary,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.keyboard_arrow_down,
                                            color: _labelColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_selectedUndesiredFoodIds.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _availableFoods
                                          .where((food) =>
                                              food.id != null &&
                                              _selectedUndesiredFoodIds.contains(
                                                  food.id))
                                          .map(
                                            (food) => Chip(
                                              label: Text(_foodName(food.name)),
                                              backgroundColor: _chipBackground,
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Text(
                                    _t('ENFERMEDADES', 'CONDITIONS'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                      color: _labelColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: _pickConditions,
                                    borderRadius: BorderRadius.circular(14),
                                    child: InputDecorator(
                                      decoration: _mobileInputDecoration(),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              selectedConditions.isEmpty
                                                  ? _t('Seleccionar enfermedades', 'Select conditions')
                                                  : _t(
                                                      '${selectedConditions.length} seleccionada(s)',
                                                      '${selectedConditions.length} selected',
                                                    ),
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: _textPrimary,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.keyboard_arrow_down,
                                            color: _labelColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (selectedConditions.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: selectedConditions
                                          .map(
                                            (c) => Chip(
                                              label: Text(c.nombre),
                                              backgroundColor: _chipBackground,
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (previewTargets != null ||
                                previewBodyComp != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [
                                            _accent.withOpacity(0.18),
                                            const Color(0x141C3B2D),
                                          ]
                                        : const [
                                            Color(0x192E7D52),
                                            Color(0x143A9988),
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: _accent.withOpacity(0.35)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _t(
                                        '🧬 COMPOSICIÓN CORPORAL ESTIMADA',
                                        '🧬 ESTIMATED BODY COMPOSITION',
                                      ),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: .8,
                                        color: _accentStrong,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0x1A6C4B1D)
                                            : const Color(0x19F59E0B),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: isDark
                                                ? const Color(0x667C5A2A)
                                                : const Color(0x66E38B05)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.warning_amber_rounded,
                                            size: 16,
                                            color: Color(0xFFB25A00),
                                          ),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _t(
                                                'Advertencia: no es un numero exacto, es un estimado.',
                                                'Warning: this is not an exact number, it is an estimate.',
                                              ),
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: isDark
                                                    ? const Color(0xFFE2C08A)
                                                    : const Color(0xFF8A4A06),
                                                height: 1.3,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (previewTargets != null)
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: _isDark
                                              ? const Color(0xFF1C2C23)
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _isDark
                                                ? const Color(0xFF2E4036)
                                                : const Color(0xFFE2E8E4),
                                          ),
                                        ),
                                        child: Text(
                                          _t(
                                            'Metas: ${previewTargets.calorie.toStringAsFixed(0)} kcal | P ${previewTargets.protein.toStringAsFixed(0)} g | C ${previewTargets.carbs.toStringAsFixed(0)} g | G ${previewTargets.fat.toStringAsFixed(0)} g',
                                            'Targets: ${previewTargets.calorie.toStringAsFixed(0)} kcal | P ${previewTargets.protein.toStringAsFixed(0)} g | C ${previewTargets.carbs.toStringAsFixed(0)} g | F ${previewTargets.fat.toStringAsFixed(0)} g',
                                          ),
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: _textPrimary,
                                          ),
                                        ),
                                      ),
                                    if (previewBodyComp != null) ...[
                                      const SizedBox(height: 8),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final sarcopenia =
                                            _t('Sarcopenia', 'Sarcopenia');
                                          final normalLabel =
                                            _t('Normal', 'Normal');
                                          final metricTiles = <Widget>[
                                            _infoMetric(
                                              value:
                                                  '${previewBodyComp.bodyFatPct.toStringAsFixed(1)}%',
                                              label: _t('% grasa', '% fat'),
                                              color: const Color(0xFFb84d65),
                                            ),
                                            _infoMetric(
                                              value:
                                                  '${previewBodyComp.musclePct.toStringAsFixed(1)}%',
                                              label: _t('% musculo', '% muscle'),
                                              color: const Color(0xFF2e7d52),
                                            ),
                                            _infoMetric(
                                              value:
                                                  '${previewBodyComp.leanBodyMass.toStringAsFixed(1)} kg',
                                              label: _t('masa magra', 'lean mass'),
                                              color: const Color(0xFF3a82aa),
                                            ),
                                            _infoMetric(
                                              value:
                                                  '${previewBodyComp.muscleMass.toStringAsFixed(1)} kg',
                                              label: _t('masa muscular', 'muscle mass'),
                                              color: const Color(0xFF2e7d52),
                                              highlighted: true,
                                            ),
                                            _infoMetric(
                                              value:
                                                  '${previewBodyComp.boneMass.toStringAsFixed(2)} kg',
                                              label: _t('masa osea', 'bone mass'),
                                              color: const Color(0xFFa05a2a),
                                            ),
                                            _infoMetric(
                                              value:
                                                  '${previewBodyComp.waterMass.toStringAsFixed(1)} L',
                                              label: _t('agua corporal', 'body water'),
                                              color: const Color(0xFF3a82aa),
                                            ),
                                            _infoMetric(
                                              value:
                                                  '${previewBodyComp.waterPct.toStringAsFixed(1)}%',
                                              label: _t('% agua', '% water'),
                                              color: const Color(0xFF3a82aa),
                                            ),
                                            _infoMetric(
                                              value: previewBodyComp.bmi
                                                  .toStringAsFixed(1),
                                              label: _t('IMC', 'BMI'),
                                              color: previewBodyComp.bmi >= 40
                                                  ? const Color(0xFFb84d65)
                                                  : previewBodyComp.bmi >= 30
                                                      ? const Color(0xFF9B3E54)
                                                      : previewBodyComp.bmi >=
                                                              25
                                                          ? const Color(
                                                              0xFFb8763a)
                                                          : const Color(
                                                              0xFF2e7d52),
                                            ),
                                            _infoMetric(
                                              value: previewBodyComp.smi
                                                  .toStringAsFixed(1),
                                              label: _t('SMI', 'SMI'),
                                              color: const Color(0xFF7050a8),
                                            ),
                                            _infoMetric(
                                              value: previewBodyComp
                                                  .muscleCategory,
                                              label: _t(
                                                'estado muscular',
                                                'muscle status',
                                              ),
                                              color: previewBodyComp
                                                          .muscleCategory ==
                                                      sarcopenia
                                                  ? const Color(0xFFb84d65)
                                                  : previewBodyComp
                                                              .muscleCategory ==
                                                          normalLabel
                                                      ? const Color(0xFFb8763a)
                                                      : const Color(0xFF2e7d52),
                                            ),
                                          ];

                                          final isCompact =
                                              constraints.maxWidth < 420;

                                          return GridView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: metricTiles.length,
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: isCompact ? 2 : 3,
                                              crossAxisSpacing: 8,
                                              mainAxisSpacing: 8,
                                              mainAxisExtent:
                                                  isCompact ? 88 : 78,
                                            ),
                                            itemBuilder: (context, index) =>
                                                metricTiles[index],
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      _compositionBar(previewBodyComp),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _statusPill(
                                            '${previewBodyComp.precisionLabel} ${previewBodyComp.precisionError}',
                                          ),
                                          _statusPill(
                                            _t(
                                              'Estado: ${_bmiCategory(previewBodyComp.bmi)}',
                                              'Status: ${_bmiCategory(previewBodyComp.bmi)}',
                                            ),
                                          ),
                                          if (previewBodyComp.bmi < 25)
                                            _statusPill(
                                              _t(
                                                'Perfil graso: ${previewBodyComp.bodyCategory}',
                                                'Fat profile: ${previewBodyComp.bodyCategory}',
                                              ),
                                            ),
                                          _statusPill(
                                            _t(
                                              'Hidratacion: ${previewBodyComp.waterStatus}',
                                              'Hydration: ${previewBodyComp.waterStatus}',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0x1A3A2B1E)
                                                    : const Color(0x12a05a2a),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: isDark
                                                      ? const Color(0x334B3A2B)
                                                      : const Color(0x33a05a2a),
                                                ),
                                              ),
                                              child: Text(
                                                _t(
                                                  'Hueso: ${previewBodyComp.boneMass.toStringAsFixed(2)} kg (${previewBodyComp.bonePct.toStringAsFixed(1)}%)\n${previewBodyComp.boneCategory}',
                                                  'Bone: ${previewBodyComp.boneMass.toStringAsFixed(2)} kg (${previewBodyComp.bonePct.toStringAsFixed(1)}%)\n${previewBodyComp.boneCategory}',
                                                ),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? const Color(0xFFD6B18F)
                                                      : const Color(0xFF7a4321),
                                                  height: 1.35,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0x1A1B3A4E)
                                                    : const Color(0x123a82aa),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: isDark
                                                      ? const Color(0x33446666)
                                                      : const Color(0x333a82aa),
                                                ),
                                              ),
                                              child: Text(
                                                _t(
                                                  'Agua: ${previewBodyComp.waterMass.toStringAsFixed(1)} L (${previewBodyComp.waterPct.toStringAsFixed(1)}%)\nIC ${previewBodyComp.waterIC.toStringAsFixed(1)}L · EC ${previewBodyComp.waterEC.toStringAsFixed(1)}L',
                                                  'Water: ${previewBodyComp.waterMass.toStringAsFixed(1)} L (${previewBodyComp.waterPct.toStringAsFixed(1)}%)\nIC ${previewBodyComp.waterIC.toStringAsFixed(1)}L · EC ${previewBodyComp.waterEC.toStringAsFixed(1)}L',
                                                ),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? const Color(0xFF9DC7E2)
                                                      : const Color(0xFF2c607a),
                                                  height: 1.35,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        previewBodyComp.precisionHint,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _isDark
                                              ? const Color(0xFF9DB2A6)
                                              : const Color(0xFF4F6F5E),
                                        ),
                                      ),
                                    ] else
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          _gender == 'female'
                                              ? _t(
                                                  'Agrega cintura, cuello y cadera para mostrar composicion corporal.',
                                                  'Add waist, neck, and hip to show body composition.',
                                                )
                                              : _t(
                                                  'Agrega cintura y cuello para mostrar composicion corporal.',
                                                  'Add waist and neck to show body composition.',
                                                ),
                                                style: TextStyle(
                                            fontSize: 12,
                                                  color: _isDark
                                                      ? const Color(0xFF9DB2A6)
                                                      : const Color(0xFF4F6F5E),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _saving ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _saving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(_t('Guardar medidas', 'Save measurements')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
