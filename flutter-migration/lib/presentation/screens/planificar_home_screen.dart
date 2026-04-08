import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/planner_providers.dart';
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

  @override
  Widget build(BuildContext context) {
    final monthState = ref.watch(monthPlanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Planificar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
