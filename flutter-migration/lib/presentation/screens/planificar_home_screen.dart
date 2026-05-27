import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/food_item.dart';
import '../../domain/models/planner_types.dart';
import '../providers/planner_providers.dart';
import '../../services/food_name_translator.dart';
import 'day_plan_editor_screen.dart';
import 'month_calendar_screen.dart';
import 'recipe_today_screen.dart';

class PlanificarHomeScreen extends ConsumerStatefulWidget {
  const PlanificarHomeScreen({super.key});

  @override
  ConsumerState<PlanificarHomeScreen> createState() =>
      _PlanificarHomeScreenState();
}

class _PlanificarHomeScreenState extends ConsumerState<PlanificarHomeScreen> {
  DateTime target = DateTime.now();
  static const String plannerBuild = 'PLANNER-MANUAL-20260405-C';

  String _goalLabel(GoalType goalType) {
    return switch (goalType) {
      GoalType.deficit => 'Deficit',
      GoalType.maintain => 'Mantener',
      GoalType.gain => 'Ganar',
      GoalType.health => 'Salud',
    };
  }

  Future<void> _openProfileFiltersSheet() async {
    final profile = await ref.read(userProfileProvider.future);
    final catalog = await ref.read(foodCatalogProvider.future);

    if (!mounted) return;

    var workingGoal = profile.goalType;
    final selectedFoodIds = Set<int>.from(profile.undesiredFoodIds);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setLocalState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Perfil y filtros del plan',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Objetivo',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: GoalType.values
                          .map(
                            (goalType) => ChoiceChip(
                              label: Text(_goalLabel(goalType)),
                              selected: workingGoal == goalType,
                              onSelected: (_) => setLocalState(
                                () => workingGoal = goalType,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Alimentos no deseados',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'No se incluiran al generar un nuevo plan mensual.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 260,
                      child: _UndesiredFoodsSelector(
                        foods: catalog,
                        selectedFoodIds: selectedFoodIds,
                        onToggle: (foodId) {
                          setLocalState(() {
                            if (selectedFoodIds.contains(foodId)) {
                              selectedFoodIds.remove(foodId);
                            } else {
                              selectedFoodIds.add(foodId);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final updatedProfile = profile.copyWith(
                            goalType: workingGoal,
                            undesiredFoodIds: selectedFoodIds,
                          );
                          await ref
                              .read(userProfileRepositoryProvider)
                              .saveCurrentProfile(updatedProfile);
                          ref.invalidate(userProfileProvider);
                          ref.invalidate(nutritionalGoalsProvider);
                          ref.invalidate(monthPlanProvider);

                          if (!mounted) return;
                          Navigator.of(sheetContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Perfil actualizado. Los nuevos planes respetaran los alimentos no deseados.',
                              ),
                            ),
                          );
                        },
                        child: const Text('Guardar configuracion'),
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

  @override
  Widget build(BuildContext context) {
    final monthState = ref.watch(monthPlanProvider);
    final profileState = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planificar'),
        actions: [
          IconButton(
            onPressed: profileState.isLoading ? null : _openProfileFiltersSheet,
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Perfil y filtros',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color(0xFFEFF8F1),
            child: ListTile(
              leading: const Icon(Icons.block_rounded),
              title: const Text('Alimentos no deseados'),
              subtitle: const Text(
                'Toca aqui para elegir que alimentos no incluir en nuevos planes.',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _openProfileFiltersSheet,
            ),
          ),
          const SizedBox(height: 12),
          if (profileState.hasValue) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: const Text('Configuracion de perfil'),
                subtitle: Text(
                  'Objetivo: ${_goalLabel(profileState.requireValue.goalType)}  ·  No deseados: ${profileState.requireValue.undesiredFoodIds.length}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _openProfileFiltersSheet,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mes objetivo: ${target.month}/${target.year}'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7EE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFB8DABA)),
                    ),
                    child: const Text(
                      'Modo manual activo por defecto. Al crear el plan se abre directo el editor del día.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2E8A5E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    plannerBuild,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6A8D76),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FilledButton(
                    onPressed: monthState.isLoading
                        ? null
                        : () async {
                            await ref
                                .read(monthPlanProvider.notifier)
                                .createMonthlyPlan(
                                    year: target.year, month: target.month);
                            if (!mounted) return;

                            final created = ref
                                .read(monthPlanProvider)
                                .valueOrNull
                                ?.monthPlan;
                            if (created == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('No se pudo crear el plan mensual.'),
                                ),
                              );
                              return;
                            }

                            final now = DateTime.now();
                            final selectedDate = (created.year == now.year &&
                                    created.month == now.month)
                                ? DateTime(now.year, now.month, now.day)
                                : DateTime(created.year, created.month, 1);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DayPlanEditorScreen(
                                  date: selectedDate,
                                ),
                              ),
                            );
                          },
                    child: const Text('Crear plan y editar manualmente'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (monthState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (monthState.valueOrNull?.monthPlan == null)
            const Text('Estado vacío: no hay plan mensual generado')
          else
            Card(
              child: ListTile(
                title: const Text('Plan generado'),
                subtitle: Text(
                  '${monthState.valueOrNull!.monthPlan!.month}/${monthState.valueOrNull!.monthPlan!.year}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MonthCalendarScreen()),
                  );
                },
              ),
            ),
          if (monthState.valueOrNull?.monthPlan != null) ...[
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () {
                final plan = monthState.valueOrNull!.monthPlan!;
                final now = DateTime.now();
                final selectedDate =
                    (plan.year == now.year && plan.month == now.month)
                        ? DateTime(now.year, now.month, now.day)
                        : DateTime(plan.year, plan.month, 1);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DayPlanEditorScreen(date: selectedDate),
                  ),
                );
              },
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Editar manualmente hoy'),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecipeTodayScreen()),
              );
            },
            icon: const Icon(Icons.restaurant_menu_rounded),
            label: const Text('Ir a Recetas de Hoy'),
          ),
        ],
      ),
    );
  }
}

class _UndesiredFoodsSelector extends StatelessWidget {
  final List<FoodItem> foods;
  final Set<int> selectedFoodIds;
  final ValueChanged<int> onToggle;

  const _UndesiredFoodsSelector({
    required this.foods,
    required this.selectedFoodIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final sortedFoods = [...foods]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return ListView.builder(
      itemCount: sortedFoods.length,
      itemBuilder: (context, index) {
        final food = sortedFoods[index];
        final displayName = FoodNameTranslator.translate(
          food.name,
          Localizations.localeOf(context),
        );
        return CheckboxListTile(
          dense: true,
          value: selectedFoodIds.contains(food.id),
          title: Text('${food.emoji} $displayName'),
          onChanged: (_) => onToggle(food.id),
        );
      },
    );
  }
}
