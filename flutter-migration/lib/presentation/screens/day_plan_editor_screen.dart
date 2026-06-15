import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/iterable_extensions.dart';
import '../../domain/models/food_item.dart';
import '../../domain/models/planner_types.dart';
import '../providers/planner_providers.dart';
import '../../services/food_name_translator.dart';

class _FoodPickerResult {
  final int foodItemId;
  final MealType? mealType;

  const _FoodPickerResult({required this.foodItemId, this.mealType});
}

Future<_FoodPickerResult?> _showFoodPicker(
  BuildContext context,
  List<FoodItem> foods, {
  required String title,
    required FoodNameTranslationService translationService,
  MealType? initialMealType,
  bool includeMealType = false,
}) async {
  final searchCtrl = TextEditingController();
  MealType selectedMealType = initialMealType ?? MealType.snack;
  List<FoodItem> filtered = List<FoodItem>.from(foods);

  String normalize(String value) => value
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

  final result = await showModalBottomSheet<_FoodPickerResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: searchCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Buscar alimento',
                    prefixIcon: Icon(Icons.search_rounded),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final query = normalize(value);
                    setModalState(() {
                      if (query.isEmpty) {
                        filtered = List<FoodItem>.from(foods);
                        return;
                      }

                      filtered = foods.where((food) {
                        return normalize(food.name).contains(query);
                      }).toList();
                    });
                  },
                ),
                if (includeMealType) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<MealType>(
                    value: selectedMealType,
                    decoration: const InputDecoration(
                      labelText: 'Momento',
                      border: OutlineInputBorder(),
                    ),
                    items: MealType.values
                        .map(
                          (meal) => DropdownMenuItem(
                            value: meal,
                            child: Text(meal.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() => selectedMealType = value);
                    },
                  ),
                ],
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 340),
                  child: filtered.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No hay resultados.'),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final food = filtered[index];
                              final displayName = translationService.translate(
                              food.name,
                              Localizations.localeOf(context),
                            );
                            return ListTile(
                              title: Text(displayName),
                              subtitle: Text(
                                '${food.per100.calories.toStringAsFixed(0)} kcal/100g',
                              ),
                              onTap: () {
                                Navigator.pop(
                                  context,
                                  _FoodPickerResult(
                                    foodItemId: food.id,
                                    mealType:
                                        includeMealType ? selectedMealType : null,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  searchCtrl.dispose();
  return result;
}

class DayPlanEditorScreen extends ConsumerWidget {
    const DayPlanEditorScreen({
      super.key,
      required this.date,
      this.translationService = const DefaultFoodNameTranslationService(),
    });

  final DateTime date;
    final FoodNameTranslationService translationService;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(dayEditorProvider(date));
    final foods = ref.watch(foodCatalogProvider).valueOrNull ?? const [];
    final workingDay = editor.workingDay;
    final locale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(title: Text('Editar día ${date.day}/${date.month}')),
      body: workingDay == null
          ? const Center(child: Text('No hay datos de este día'))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (editor.validation != null && !editor.validation!.isValid)
                  Card(
                    color: const Color(0xFFFFF4E5),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: editor.validation!.errors
                            .map((e) => Text('• $e'))
                            .toList(),
                      ),
                    ),
                  ),
                ...workingDay.items.map((item) {
                  final food =
                      foods.where((f) => f.id == item.foodItemId).firstOrNull;
                  final displayName = food == null
                      ? 'Food ${item.foodItemId}'
                      : translationService.translate(food.name, locale);
                  return Card(
                    child: ListTile(
                      title: Text(displayName),
                      subtitle: Text(
                          '${item.mealType.name} · ${item.grams.toStringAsFixed(0)}g'),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            onPressed: () async {
                              if (foods.isEmpty) return;
                              final selection = await _showFoodPicker(
                                context,
                                foods,
                                title: 'Seleccionar alimento',
                                  translationService: translationService,
                              );
                              if (selection == null) return;
                              ref
                                  .read(dayEditorProvider(date).notifier)
                                  .editMealItem(
                                    mealItemId: item.id,
                                    newFoodItemId: selection.foodItemId,
                                  );
                            },
                            icon: const Icon(Icons.swap_horiz_rounded),
                          ),
                          IconButton(
                            onPressed: () {
                              ref
                                  .read(dayEditorProvider(date).notifier)
                                  .removeMealItem(
                                    mealItemId: item.id,
                                  );
                            },
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: foods.isEmpty
                      ? null
                      : () async {
                          final selection = await _showFoodPicker(
                            context,
                            foods,
                            title: 'Agregar alimento',
                            includeMealType: true,
                            initialMealType: MealType.snack,
                              translationService: translationService,
                          );
                          if (selection == null) return;
                          ref
                              .read(dayEditorProvider(date).notifier)
                              .addMealItem(
                                mealType: selection.mealType ?? MealType.snack,
                                foodItemId: selection.foodItemId,
                              );
                        },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Agregar alimento'),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () =>
                      ref.read(dayEditorProvider(date).notifier).rebalanceDay(),
                  child: const Text('Rebalancear día'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () =>
                      ref.read(dayEditorProvider(date).notifier).validateDay(),
                  child: const Text('Validar día'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () async {
                    final saved = await ref
                        .read(dayEditorProvider(date).notifier)
                        .saveDay();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(saved
                            ? 'Día guardado'
                            : 'Día bloqueado por validación'),
                      ),
                    );
                  },
                  child: const Text('Guardar día'),
                ),
              ],
            ),
    );
  }
}
