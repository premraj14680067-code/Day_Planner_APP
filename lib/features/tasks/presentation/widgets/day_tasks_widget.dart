// lib/features/tasks/presentation/widgets/day_tasks_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypilot/core/providers/providers.dart';
import 'package:daypilot/core/theme/app_theme.dart';
import 'package:daypilot/features/tasks/presentation/widgets/task_item.dart';
import 'package:daypilot/features/tasks/presentation/widgets/add_task_sheet.dart';

class DayTasksWidget extends ConsumerWidget {
  final String dateKey;
  const DayTasksWidget({super.key, required this.dateKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(taskRefreshProvider);
    final tasks = ref.read(taskRepositoryProvider).getTasksForDate(dateKey);
    final theme = Theme.of(context);

    return Scaffold(
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_box_outline_blank_rounded,
                      size: 48, color: Colors.grey.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  Text('No tasks for this day',
                      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _addTask(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Task'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final task = tasks[i];
                return TaskItem(
                  task: task,
                  onToggle: () => ref.read(taskNotifierProvider.notifier).toggleComplete(task.id),
                  onEdit: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddTaskSheet(existingTask: task),
                  ),
                  onDelete: () => ref.read(taskNotifierProvider.notifier).deleteTask(task.id),
                );
              },
            ),
      floatingActionButton: tasks.isNotEmpty
          ? FloatingActionButton(
              mini: true,
              onPressed: () => _addTask(context, ref),
              backgroundColor: AppTheme.primaryBlue,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }

  void _addTask(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(initialDateKey: dateKey),
    );
  }
}
