import 'dart:async';

import 'package:flutter/material.dart';

import '../models/food_models.dart';
import '../repositories/food_repository.dart';

class AddFoodBottomSheet extends StatefulWidget {
  final FoodRepository repository;
  final List<Food> fallbackFoods;
  final String initialMealTime;

  const AddFoodBottomSheet({
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
  final List<({Food food, double quantity})> _selectedFoods = [];
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
                    'Registrar comida de hoy',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF234734),
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
              decoration: InputDecoration(
                labelText: 'Buscar alimento',
                hintText: 'Ejemplo: lentejas, tofu, aguacate...',
                prefixIcon: Icon(Icons.search_rounded),
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
                    decoration: InputDecoration(
                      labelText: 'Momento',
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
                SizedBox(width: 10),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _quantityCtrl,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Cantidad',
                      hintText: '100',
                      suffixText: 'g/ml',
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
            if (_selectedFoods.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                'Seleccionados (${_selectedFoods.length})',
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
                                item.food.name,
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
              'Resultados',
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
                            'No se encontraron alimentos. Prueba otro nombre.',
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
                                            food.name,
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
                      ? 'Guardando...'
                      : (_selectedFoods.isEmpty
                          ? 'Selecciona alimentos'
                          : 'Guardar ${_selectedFoods.length} items en hoy'),
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
