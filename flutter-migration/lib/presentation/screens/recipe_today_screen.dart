import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/food_item.dart';
import '../../services/food_name_translator.dart';
import '../providers/planner_providers.dart';

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

class RecipeTodayScreen extends ConsumerStatefulWidget {
  const RecipeTodayScreen({
    super.key,
    this.translationService = const DefaultFoodNameTranslationService(),
  });

  final FoodNameTranslationService translationService;

  @override
  ConsumerState<RecipeTodayScreen> createState() =>
      _RecipeTodayScreenState();
}

class _RecipeTodayScreenState extends ConsumerState<RecipeTodayScreen> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, _RecipeDetail> _recipeDetailsByKey = {};
  bool _loadingDetails = true;

  bool get _isSpanish =>
      Localizations.localeOf(context).languageCode == 'es';

  String _t(String es, String en) => _isSpanish ? es : en;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadRecipeDetails();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipeDetails() async {
    try {
      final jsonText =
          await rootBundle.loadString('assets/data/recipe_catalog.json');
      final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
      final details = <String, _RecipeDetail>{};

      for (final entry in decoded.entries) {
        final value = Map<String, dynamic>.from(entry.value as Map);
        details[entry.key] = _RecipeDetail(
          subtitle: value['subtitle'] as String? ?? '',
          ingredients:
              List<String>.from(value['ingredients'] as List<dynamic>? ?? const []),
          steps: List<String>.from(value['steps'] as List<dynamic>? ?? const []),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _recipeDetailsByKey = details;
        _loadingDetails = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingDetails = false;
      });
    }
  }

  String _normalizeRecipeKey(String value) {
    const accents = {
      'a': 'a',
      'e': 'e',
      'i': 'i',
      'o': 'o',
      'u': 'u',
      'n': 'n',
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

  _RecipeDetail _recipeDetailFor(FoodItem food) {
    final key = _normalizeRecipeKey(food.name);
    final loadedDetail = _recipeDetailsByKey[key];
    if (loadedDetail != null) {
      return loadedDetail;
    }

    return _RecipeDetail(
      subtitle: _t(
        'Preparacion detallada no disponible todavia.',
        'Detailed preparation is not available yet.',
      ),
      ingredients: [
        _t(
          'Recarga la pantalla para cargar la receta completa.',
          'Reload the screen to load the full recipe.',
        ),
      ],
      steps: [
        _t(
          'La receta detallada aun se esta cargando o no esta disponible en el catalogo.',
          'The detailed recipe is still loading or is unavailable in the catalog.',
        ),
      ],
    );
  }

  Future<void> _showRecipeDetailModal(FoodItem food) async {
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
                          widget.translationService
                              .translate(food.name, Localizations.localeOf(context)),
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
                    _t('Preparacion', 'Preparation'),
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
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final foodCatalog = ref.watch(foodCatalogProvider).valueOrNull ?? const [];
    final locale = Localizations.localeOf(context);
    final query = _searchController.text.trim().toLowerCase();

    final filteredFoods = foodCatalog.where((food) {
      if (query.isEmpty) {
        return true;
      }

      final translated =
          widget.translationService.translate(food.name, locale).toLowerCase();
      return translated.contains(query) || food.name.toLowerCase().contains(query);
    }).toList();

    filteredFoods.sort(
      (a, b) => widget.translationService
          .translate(a.name, locale)
          .compareTo(widget.translationService.translate(b.name, locale)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(_t('Recetas', 'Recipes'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _t('Buscar alimento...', 'Search food...'),
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFFF5F7F4),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_loadingDetails)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          Expanded(
            child: filteredFoods.isEmpty
                ? Center(
                    child: Text(
                      _t(
                        'No hay recetas para este filtro.',
                        'No recipes found for this filter.',
                      ),
                      style: const TextStyle(color: Color(0xFF6A8D76)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                    itemCount: filteredFoods.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final food = filteredFoods[index];
                      final detail = _recipeDetailFor(food);

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          onTap: () => _showRecipeDetailModal(food),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFEAF1EB),
                            child: Text(food.emoji),
                          ),
                          title: Text(
                            widget.translationService
                                .translate(food.name, locale),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            detail.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF2E8A5E),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
