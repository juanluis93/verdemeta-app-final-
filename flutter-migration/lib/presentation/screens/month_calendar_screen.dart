import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/planner_types.dart';
import '../providers/planner_providers.dart';
import 'day_plan_editor_screen.dart';

class MonthCalendarScreen extends ConsumerWidget {
  const MonthCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monthPlanProvider);
    final plan = state.valueOrNull?.monthPlan;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendario mensual')),
      body: plan == null
          ? const Center(child: Text('No hay plan para mostrar'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: plan.dayPlans.length,
              itemBuilder: (context, index) {
                final day = plan.dayPlans[index];
                final color = switch (day.validationStatus) {
                  ValidationStatus.valid => const Color(0xFFEAF7EE),
                  ValidationStatus.invalid => const Color(0xFFFFF4E5),
                  ValidationStatus.pending => const Color(0xFFE8F0FE),
                };

                return Card(
                  color: color,
                  child: ListTile(
                    title: Text('Día ${day.date.day}'),
                    subtitle: Text('Platos: ${day.items.length}'),
                    trailing: const Icon(Icons.edit_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DayPlanEditorScreen(date: day.date),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
