import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/planner_providers.dart';
import '../../services/food_name_translator.dart';
import 'day_plan_editor_screen.dart';

class RecipeTodayScreen extends ConsumerWidget {
  const RecipeTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayPlanProvider);
    final foodCatalog = ref.watch(foodCatalogProvider).valueOrNull ?? const [];
    final locale = Localizations.localeOf(context);
    final foodNameById = {
      for (final food in foodCatalog)
        food.id: FoodNameTranslator.translate(food.name, locale),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Recetas de hoy')),
      body: today == null
          ? const Center(child: Text('No hay dieta para el día actual'))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text(
                    'Fecha: ${today.date.day}/${today.date.month}/${today.date.year}'),
                const SizedBox(height: 8),
                ...today.items.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(item.mealType.name),
                      subtitle: Text(
                        '${foodNameById[item.foodItemId] ?? 'Alimento no encontrado'} · ${item.grams.toStringAsFixed(0)}g',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DayPlanEditorScreen(date: today.date),
                      ),
                    );
                  },
                  child: const Text('Personalizar día actual'),
                ),
              ],
            ),
    );
  }
}
