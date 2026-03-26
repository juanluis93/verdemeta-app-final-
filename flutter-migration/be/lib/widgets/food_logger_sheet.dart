import 'dart:async';

import 'package:flutter/material.dart';

import '../models/food_models.dart';
import '../repositories/food_repository.dart';

class AddFoodBottomSheet extends StatefulWidget {
  final FoodRepository repository;
  final List<Food> fallbackFoods;
  final String initialMealTime;

  const AddFoodBottomSheet({
    super.key,
    required this.repository,
    required this.fallbackFoods,
    required this.initialMealTime,
  });

  @override
  State<AddFoodBottomSheet> createState() => _AddFoodBottomSheetState();
}

class _AddFoodBottomSheetState extends State<AddFoodBottomSheet> {
  static const _mealOptions = ['Desayuno', 'Almuerzo', 'Cena', 'Merienda'];

  final _searchCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '100');
  final _searchFocus = FocusNode();

  List<Food> _results = [];
  Food? _selectedFood;
  bool _searching = false;
  bool _saving = false;
  String _mealTime = 'Desayuno';
  int _searchRequestId = 0;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _mealTime = _mealOptions.contains(widget.initialMealTime)
        ? widget.initialMealTime
        : 'Desayuno';
    _results = widget.fallbackFoods.take(12).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _quantityCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _handleSearchChange(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 220),
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
        _results = widget.fallbackFoods.take(12).toList();
      });
      return;
    }

    setState(() => _searching = true);

    try {
      final foods = await widget.repository.searchFoods(query);
      if (!mounted || requestId != _searchRequestId) return;

      setState(() {
        _searching = false;
        _results = foods;
      });
    } catch (_) {
      final local = widget.fallbackFoods.where((food) {
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

  Future<void> _saveFood() async {
    if (_saving) return;

    final selected = _selectedFood;
    final quantity = _parseQuantity();

    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecciona un alimento para registrarlo.')),
      );
      return;
    }

    if (quantity == null || quantity <= 0 || quantity > 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ingresa una cantidad valida en gramos/ml.')),
      );
      return;
    }

    setState(() => _saving = true);

    final entry = FoodLogEntry.fromFood(
      food: selected,
      quantity: quantity,
      mealTime: _mealTime,
    );

    try {
      await widget.repository.logFood(entry);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo guardar en este modo. En movil/app nativa si se guarda.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quantity = _parseQuantity() ?? 100;
    final selectedNutrition = _selectedFood?.calculateForQuantity(quantity);
    final mediaQuery = MediaQuery.of(context);

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Registrar comida de hoy',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF234734),
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            onChanged: _handleSearchChange,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Buscar alimento',
              hintText: 'Ejemplo: lentejas, tofu, aguacate...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFDCEBDD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFDCEBDD)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _mealTime,
                  decoration: InputDecoration(
                    labelText: 'Momento',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFDCEBDD)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFDCEBDD)),
                    ),
                  ),
                  items: _mealOptions
                      .map(
                        (meal) => DropdownMenuItem(
                          value: meal,
                          child: Text(meal),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _mealTime = value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _quantityCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Cantidad',
                    hintText: '100',
                    suffixText: 'g/ml',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFDCEBDD)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFDCEBDD)),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          if (_selectedFood != null && selectedNutrition != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCEBDD)),
              ),
              child: Row(
                children: [
                  Text(
                    _selectedFood!.emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFood!.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF254836),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${selectedNutrition.calories.toStringAsFixed(0)} kcal • P ${selectedNutrition.protein.toStringAsFixed(1)}g • C ${selectedNutrition.carbs.toStringAsFixed(1)}g • G ${selectedNutrition.fat.toStringAsFixed(1)}g',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6A8D76),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Resultados',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Color(0xFF5E8570),
            ),
          ),
          const SizedBox(height: 8),
          if (_searching)
            const Center(child: CircularProgressIndicator())
          else if (_results.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDCEBDD)),
              ),
              child: const Text(
                'No se encontraron alimentos. Prueba otro nombre.',
                style: TextStyle(
                  color: Color(0xFF6A8D76),
                  fontSize: 13,
                ),
              ),
            )
          else
            Column(
              children: List.generate(_results.length, (index) {
                final food = _results[index];
                final selected =
                    _selectedFood?.id == food.id && _selectedFood?.name == food.name;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == _results.length - 1 ? 0 : 8,
                  ),
                  child: InkWell(
                    onTap: () => setState(() => _selectedFood = food),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFEAF8EF)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF86C8A0)
                              : const Color(0xFFDCEBDD),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            food.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  food.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2A4B38),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${food.calories.toInt()} kcal/100g • P ${food.protein.toStringAsFixed(1)} • C ${food.carbs.toStringAsFixed(1)} • G ${food.fat.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF6A8D76),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF2E8A5E),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _saveFood,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bookmark_add_rounded),
              label: Text(
                _saving ? 'Guardando...' : 'Guardar en registros de hoy',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8A5E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
