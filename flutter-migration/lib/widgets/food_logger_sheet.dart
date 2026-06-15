import 'dart:async';

import 'package:flutter/material.dart';

import '../models/food_models.dart';
import '../repositories/food_repository.dart';
import '../services/food_name_translator.dart';

class AddFoodBottomSheet extends StatefulWidget {
  final UserSessionRepository repository;
  final List<Food> fallbackFoods;
  final String initialMealTime;
  final Set<int> excludedFoodIds;
  final Locale locale;
  final FoodNameTranslationService translationService;

  const AddFoodBottomSheet({
    required this.repository,
    required this.fallbackFoods,
    required this.excludedFoodIds,
    required this.initialMealTime,
    required this.locale,
    this.translationService = const DefaultFoodNameTranslationService(),
  });

  @override
  State<AddFoodBottomSheet> createState() => _AddFoodBottomSheetState();
}

class _AddFoodBottomSheetState extends State<AddFoodBottomSheet> {
  static const _mealOptions = ['Desayuno', 'Almuerzo', 'Cena', 'Merienda'];

  final _searchCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '100');
  final _searchFocus = FocusNode();

  final _manualNameCtrl = TextEditingController();
  final _manualEmojiCtrl = TextEditingController();
  final _manualCaloriesCtrl = TextEditingController();
  final _manualProteinCtrl = TextEditingController();
  final _manualCarbsCtrl = TextEditingController();
  final _manualFatCtrl = TextEditingController();
  final _manualFiberCtrl = TextEditingController();
  final _manualIronCtrl = TextEditingController();
  final _manualCalciumCtrl = TextEditingController();
  final _manualB12Ctrl = TextEditingController();
  final _manualZincCtrl = TextEditingController();

  List<Food> _results = [];
  final List<({Food food, double quantity})> _selectedFoods = [];
  bool _searching = false;
  bool _saving = false;
  String _mealTime = 'Desayuno';
  int _searchRequestId = 0;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _mealTime = _mealTimeKey(widget.initialMealTime);
    _results = _applyExcludedFoods(widget.fallbackFoods).take(12).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocus.requestFocus();
      }
    });
  }

  bool get _isSpanish => widget.locale.languageCode == 'es';

  String _t(String es, String en) => _isSpanish ? es : en;

  String _foodName(String name) {
    return widget.translationService.translate(name, widget.locale);
  }

  String _mealTimeKey(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'desayuno' || normalized == 'breakfast') return 'Desayuno';
    if (normalized == 'almuerzo' || normalized == 'lunch') return 'Almuerzo';
    if (normalized == 'cena' || normalized == 'dinner') return 'Cena';
    if (normalized == 'merienda' || normalized == 'snack') return 'Merienda';
    return 'Desayuno';
  }

  String _mealLabel(String mealTime) {
    final normalized = mealTime.trim().toLowerCase();
    if (normalized == 'desayuno' || normalized == 'breakfast') {
      return _t('Desayuno', 'Breakfast');
    }
    if (normalized == 'almuerzo' || normalized == 'lunch') {
      return _t('Almuerzo', 'Lunch');
    }
    if (normalized == 'cena' || normalized == 'dinner') {
      return _t('Cena', 'Dinner');
    }
    if (normalized == 'merienda' || normalized == 'snack') {
      return _t('Merienda', 'Snack');
    }
    return mealTime;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _quantityCtrl.dispose();
    _searchFocus.dispose();
    _manualNameCtrl.dispose();
    _manualEmojiCtrl.dispose();
    _manualCaloriesCtrl.dispose();
    _manualProteinCtrl.dispose();
    _manualCarbsCtrl.dispose();
    _manualFatCtrl.dispose();
    _manualFiberCtrl.dispose();
    _manualIronCtrl.dispose();
    _manualCalciumCtrl.dispose();
    _manualB12Ctrl.dispose();
    _manualZincCtrl.dispose();
    super.dispose();
  }

  void _handleSearchChange(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      Duration(milliseconds: 220),
      () => _searchFoods(value),
    );
  }

  Future<void> _searchFoods(String rawQuery) async {
    final query = rawQuery.trim();
    final requestId = ++_searchRequestId;
    final normalizedQuery = _normalizeSearchText(query);

    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _results = _applyExcludedFoods(widget.fallbackFoods).take(12).toList();
      });
      return;
    }

    setState(() => _searching = true);

    try {
      final foods = await widget.repository.searchFoods(query);
      if (!mounted || requestId != _searchRequestId) return;

      setState(() {
        _searching = false;
        _results = _applyExcludedFoods(foods);
      });
    } catch (_) {
      final local = _applyExcludedFoods(widget.fallbackFoods).where((food) {
        final normalizedName = _normalizeSearchText(food.name);
        return normalizedName.contains(normalizedQuery);
      }).toList()
        ..sort((a, b) {
          final aStarts =
              _normalizeSearchText(a.name).startsWith(normalizedQuery);
          final bStarts =
              _normalizeSearchText(b.name).startsWith(normalizedQuery);
          if (aStarts == bStarts) return a.name.compareTo(b.name);
          return aStarts ? -1 : 1;
        });

      if (!mounted || requestId != _searchRequestId) return;

      setState(() {
        _searching = false;
        _results = local;
      });
    }
  }

  List<Food> _applyExcludedFoods(List<Food> foods) {
    if (widget.excludedFoodIds.isEmpty) return foods;
    return foods
        .where((food) =>
            food.id == null || !widget.excludedFoodIds.contains(food.id))
        .toList();
  }

  String _normalizeSearchText(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ñ', 'n');
  }

  double? _parseQuantity() {
    final clean = _quantityCtrl.text.trim().replaceAll(',', '.');
    if (clean.isEmpty) return null;
    return double.tryParse(clean);
  }

  double? _parseManualDouble(String value, {bool required = false}) {
    final clean = value.trim().replaceAll(',', '.');
    if (clean.isEmpty) return required ? null : 0;
    return double.tryParse(clean);
  }

  void _resetManualForm() {
    _manualNameCtrl.clear();
    _manualEmojiCtrl.clear();
    _manualCaloriesCtrl.clear();
    _manualProteinCtrl.clear();
    _manualCarbsCtrl.clear();
    _manualFatCtrl.clear();
    _manualFiberCtrl.clear();
    _manualIronCtrl.clear();
    _manualCalciumCtrl.clear();
    _manualB12Ctrl.clear();
    _manualZincCtrl.clear();
  }

  Future<void> _openManualFoodDialog() async {
    if (_saving) return;
    _resetManualForm();

    final created = await showDialog<Food>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final dialogBackground = isDark ? Color(0xFF1F4C36) : null;
        final dialogTextColor = isDark ? Colors.black : null;
        var error = '';
        var saving = false;

        Future<void> handleSave(StateSetter setDialogState) async {
          final name = _manualNameCtrl.text.trim();
          final emoji = _manualEmojiCtrl.text.trim();
          final calories =
              _parseManualDouble(_manualCaloriesCtrl.text, required: true);
          final protein =
              _parseManualDouble(_manualProteinCtrl.text, required: true);
          final carbs =
              _parseManualDouble(_manualCarbsCtrl.text, required: true);
          final fat =
              _parseManualDouble(_manualFatCtrl.text, required: true);
          final fiber = _parseManualDouble(_manualFiberCtrl.text) ?? 0;
          final iron = _parseManualDouble(_manualIronCtrl.text) ?? 0;
          final calcium = _parseManualDouble(_manualCalciumCtrl.text) ?? 0;
          final b12 = _parseManualDouble(_manualB12Ctrl.text) ?? 0;
          final zinc = _parseManualDouble(_manualZincCtrl.text) ?? 0;

          if (name.isEmpty ||
              calories == null ||
              protein == null ||
              carbs == null ||
              fat == null) {
            setDialogState(() {
              error = _t(
                'Completa nombre, calorias, proteina, carbohidratos y grasa.',
                'Fill in name, calories, protein, carbs, and fat.',
              );
            });
            return;
          }

          if ([calories, protein, carbs, fat, fiber, iron, calcium, b12, zinc]
              .any((value) => value < 0)) {
            setDialogState(() {
              error = _t(
                'Los valores no pueden ser negativos.',
                'Values cannot be negative.',
              );
            });
            return;
          }

          setDialogState(() {
            saving = true;
            error = '';
          });

          try {
            final newFood = Food(
              name: name,
              emoji: emoji.isEmpty ? '🍽️' : emoji,
              calories: calories,
              protein: protein,
              carbs: carbs,
              fat: fat,
              fiber: fiber,
              sugar: 0,
              iron: iron,
              calcium: calcium,
              b12: b12,
              zinc: zinc,
              isQuickFood: false,
            );

            final id = await widget.repository.addCustomFood(newFood);
            if (!mounted) return;

            Navigator.of(context).pop(
              Food(
                id: id,
                name: newFood.name,
                emoji: newFood.emoji,
                calories: newFood.calories,
                protein: newFood.protein,
                carbs: newFood.carbs,
                fat: newFood.fat,
                fiber: newFood.fiber,
                sugar: newFood.sugar,
                iron: newFood.iron,
                calcium: newFood.calcium,
                b12: newFood.b12,
                zinc: newFood.zinc,
                isQuickFood: newFood.isQuickFood,
                createdAt: newFood.createdAt,
              ),
            );
          } catch (_) {
            if (!mounted) return;
            setDialogState(() {
              saving = false;
              error = _t(
                'No se pudo guardar. Verifica si el nombre ya existe.',
                'Could not save. Check if the name already exists.',
              );
            });
          }
        }

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: dialogBackground,
            titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: dialogTextColor,
                ),
            contentTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: dialogTextColor,
                ),
            title: Text(
              _t('Agregar alimento manual', 'Add manual food'),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _manualNameCtrl,
                    style: TextStyle(color: dialogTextColor),
                    decoration: InputDecoration(
                      labelText: _t('Nombre', 'Name'),
                      labelStyle: TextStyle(color: dialogTextColor),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _manualEmojiCtrl,
                    style: TextStyle(color: dialogTextColor),
                    decoration: InputDecoration(
                      labelText: _t('Emoji (opcional)', 'Emoji (optional)'),
                      labelStyle: TextStyle(color: dialogTextColor),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _manualCaloriesCtrl,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: dialogTextColor),
                    decoration: InputDecoration(
                      labelText: _t('Calorias (kcal/100g)',
                          'Calories (kcal/100g)'),
                      labelStyle: TextStyle(color: dialogTextColor),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _manualProteinCtrl,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: dialogTextColor),
                    decoration: InputDecoration(
                      labelText:
                          _t('Proteina (g/100g)', 'Protein (g/100g)'),
                      labelStyle: TextStyle(color: dialogTextColor),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _manualCarbsCtrl,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: dialogTextColor),
                    decoration: InputDecoration(
                      labelText:
                          _t('Carbohidratos (g/100g)', 'Carbs (g/100g)'),
                      labelStyle: TextStyle(color: dialogTextColor),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _manualFatCtrl,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: dialogTextColor),
                    decoration: InputDecoration(
                      labelText:
                          _t('Grasas (g/100g)', 'Fat (g/100g)'),
                      labelStyle: TextStyle(color: dialogTextColor),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _manualFiberCtrl,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: dialogTextColor),
                    decoration: InputDecoration(
                      labelText:
                          _t('Fibras (g/100g)', 'Fiber (g/100g)'),
                      labelStyle: TextStyle(color: dialogTextColor),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _manualIronCtrl,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: dialogTextColor),
                    decoration: InputDecoration(
                      labelText: _t('Hierro (mg/100g)', 'Iron (mg/100g)'),
                      labelStyle: TextStyle(color: dialogTextColor),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _manualCalciumCtrl,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: dialogTextColor),
                    decoration: InputDecoration(
                      labelText:
                          _t('Calcio (mg/100g)', 'Calcium (mg/100g)'),
                      labelStyle: TextStyle(color: dialogTextColor),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _manualB12Ctrl,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: dialogTextColor),
                    decoration: InputDecoration(
                      labelText:
                          _t('Vitamina B12 (mcg/100g)', 'B12 (mcg/100g)'),
                      labelStyle: TextStyle(color: dialogTextColor),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _manualZincCtrl,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: dialogTextColor),
                    decoration: InputDecoration(
                      labelText: _t('Zinc (mg/100g)', 'Zinc (mg/100g)'),
                      labelStyle: TextStyle(color: dialogTextColor),
                    ),
                  ),
                  if (error.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Text(
                      error,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    saving ? null : () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: dialogTextColor,
                ),
                child: Text(_t('Cancelar', 'Cancel')),
              ),
              ElevatedButton(
                onPressed: saving ? null : () => handleSave(setDialogState),
                style: ElevatedButton.styleFrom(
                  foregroundColor: dialogTextColor,
                ),
                child: saving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_t('Guardar', 'Save')),
              ),
            ],
          ),
        );
      },
    );

    if (created == null || !mounted) return;

    final qty = _parseQuantity() ?? 100;
    setState(() {
      _results = [created, ..._results.where((food) => food.id != created.id)];
      if (qty > 0) {
        _selectedFoods.add((food: created, quantity: qty));
      }
    });
  }

  Future<void> _saveFood() async {
    if (_saving || _selectedFoods.isEmpty) return;

    setState(() => _saving = true);

    try {
      for (final item in _selectedFoods) {
        final entry = FoodLogEntry.fromFood(
          food: item.food,
          quantity: item.quantity,
          mealTime: _mealTime,
        );
        await widget.repository.logFood(entry);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final fieldTextColor = isDark ? Colors.black : scheme.onSurface;
    final fieldLabelColor = isDark ? Colors.black54 : scheme.onSurface;
    final dropdownTextStyle = theme.textTheme.bodyMedium?.copyWith(
      color: fieldTextColor,
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          14 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Color(0xFFD2E4D7),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _t('Registrar comida de hoy', "Log today's meal"),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.black : Color(0xFF234734),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: Icon(Icons.close_rounded),
                ),
              ],
            ),
            SizedBox(height: 8),
            TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              onChanged: _handleSearchChange,
              textInputAction: TextInputAction.search,
              style: TextStyle(color: fieldTextColor),
              decoration: InputDecoration(
                labelText: _t('Buscar alimento', 'Search food'),
                labelStyle: TextStyle(color: fieldLabelColor),
                hintText: _t(
                  'Ejemplo: lentejas, tofu, aguacate...',
                  'Example: lentils, tofu, avocado...',
                ),
                hintStyle: TextStyle(color: fieldLabelColor),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: fieldLabelColor,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Color(0xFFDCEBDD)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Color(0xFFDCEBDD)),
                ),
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _mealTime,
                    dropdownColor: scheme.surface,
                    style: dropdownTextStyle,
                    decoration: InputDecoration(
                      labelText: _t('Momento', 'Meal time'),
                      labelStyle: TextStyle(color: fieldLabelColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Color(0xFFDCEBDD)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Color(0xFFDCEBDD)),
                      ),
                    ),
                    items: _mealOptions
                        .map(
                          (meal) => DropdownMenuItem(
                            value: meal,
                            child: Text(
                              _mealLabel(meal),
                              style: dropdownTextStyle,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _mealTime = value);
                    },
                  ),
                ),
                SizedBox(width: 10),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _quantityCtrl,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: fieldTextColor),
                    decoration: InputDecoration(
                      labelText: _t('Cantidad', 'Amount'),
                      labelStyle: TextStyle(color: fieldLabelColor),
                      hintText: '100',
                      suffixText: _t('g/ml', 'g/ml'),
                      hintStyle: TextStyle(color: fieldLabelColor),
                      suffixStyle: TextStyle(color: fieldLabelColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Color(0xFFDCEBDD)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Color(0xFFDCEBDD)),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _openManualFoodDialog,
                icon: Icon(Icons.add_circle_outline_rounded),
                label: Text(
                  _t('Agregar alimento manual', 'Add manual food'),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFF2E8A5E),
                ),
              ),
            ),
            if (_selectedFoods.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                _t(
                  'Seleccionados (${_selectedFoods.length})',
                  'Selected (${_selectedFoods.length})',
                ),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: Color(0xFF5E8570),
                ),
              ),
              SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 120),
                child: ListView.separated(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedFoods.length,
                  separatorBuilder: (_, __) => SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = _selectedFoods[index];
                    return Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFFEAF8EF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFF86C8A0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item.food.emoji, style: TextStyle(fontSize: 18)),
                          SizedBox(width: 6),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _foodName(item.food.name),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Color(0xFF254836),
                                ),
                              ),
                              Text(
                                '${item.quantity.toInt()}g',
                                style: TextStyle(
                                    fontSize: 10, color: Color(0xFF6A8D76)),
                              ),
                            ],
                          ),
                          SizedBox(width: 4),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            icon: Icon(Icons.close_rounded,
                                size: 16, color: Color(0xFF2E8A5E)),
                            onPressed: () =>
                                setState(() => _selectedFoods.removeAt(index)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            SizedBox(height: 12),
            Text(
              _t('Resultados', 'Results'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Color(0xFF5E8570),
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 210,
              child: _searching
                  ? Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Color(0xFFDCEBDD)),
                          ),
                          child: Text(
                            _t(
                              'No se encontraron alimentos. Prueba otro nombre.',
                              'No foods found. Try another name.',
                            ),
                            style: TextStyle(
                              color: Color(0xFF6A8D76),
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final food = _results[index];
                            return InkWell(
                              onTap: () {
                                final qty = _parseQuantity() ?? 100;
                                if (qty <= 0) return;
                                setState(() {
                                  _selectedFoods
                                      .add((food: food, quantity: qty));
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Color(0xFFDCEBDD),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(food.emoji,
                                        style: TextStyle(fontSize: 24)),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _foodName(food.name),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF2A4B38),
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            '${food.calories.toInt()} kcal/100g • P ${food.protein.toStringAsFixed(1)} • C ${food.carbs.toStringAsFixed(1)} • G ${food.fat.toStringAsFixed(1)}',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFF6A8D76),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: Color(0xFF2E8A5E),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveFood,
                icon: _saving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.bookmark_add_rounded),
                label: Text(
                  _saving
                        ? _t('Guardando...', 'Saving...')
                        : (_selectedFoods.isEmpty
                          ? _t('Selecciona alimentos', 'Select foods')
                          : _t(
                            'Guardar ${_selectedFoods.length} items en hoy',
                            'Save ${_selectedFoods.length} items for today',
                          )),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2E8A5E),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
