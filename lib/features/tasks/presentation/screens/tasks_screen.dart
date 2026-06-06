// lib/features/tasks/presentation/screens/tasks_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypilot/core/constants/app_constants.dart';
import 'package:daypilot/core/providers/providers.dart';
import 'package:daypilot/core/utils/date_utils.dart';
import 'package:daypilot/core/theme/app_theme.dart';
import 'package:daypilot/features/tasks/data/models/task_model.dart';
import 'package:daypilot/features/tasks/presentation/widgets/task_item.dart';
import 'package:daypilot/features/tasks/presentation/widgets/add_task_sheet.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Watch for updates
    ref.watch(taskRefreshProvider);

    final todayKey = AppDateUtils.toDateKey(DateTime.now());
    final taskNotifier = ref.read(taskNotifierProvider.notifier);

    final todayTasks = taskNotifier.getTasksForDate(todayKey);
    final overdueTasks = taskNotifier.getOverdueTasks();
    final upcomingTasks = taskNotifier.getUpcomingTasks();
    final completedTasks = taskNotifier.getCompletedTasks();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            _buildTab('Today', todayTasks.where((t) => !t.isCompleted).length),
            _buildTab('Overdue', overdueTasks.length, color: Colors.red),
            _buildTab('Upcoming', upcomingTasks.length),
            _buildTab('Done', completedTasks.length, color: Colors.green),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TaskList(
            tasks: todayTasks,
            emptyMessage: 'No tasks for today',
            emptyIcon: Icons.check_circle_outline,
          ),
          _TaskList(
            tasks: overdueTasks,
            emptyMessage: 'No overdue tasks — great!',
            emptyIcon: Icons.celebration_outlined,
            showDate: true,
          ),
          _TaskList(
            tasks: upcomingTasks,
            emptyMessage: 'No upcoming tasks',
            emptyIcon: Icons.calendar_today_outlined,
            showDate: true,
          ),
          _TaskList(
            tasks: completedTasks,
            emptyMessage: 'No completed tasks yet',
            emptyIcon: Icons.task_alt_outlined,
            showDate: true,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTask(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Task'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Tab _buildTab(String label, int count, {Color? color}) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (color ?? AppTheme.primaryBlue).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  color: color ?? AppTheme.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddTask(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTaskSheet(),
    );
  }
}

// ─── Task List ─────────────────────────────────────────────────────────────────

class _TaskList extends ConsumerWidget {
  final List<TaskModel> tasks;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool showDate;

  const _TaskList({
    required this.tasks,
    required this.emptyMessage,
    required this.emptyIcon,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 48, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskItem(
          task: task,
          showDate: showDate,
          onToggle: () =>
              ref.read(taskNotifierProvider.notifier).toggleComplete(task.id),
          onEdit: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddTaskSheet(existingTask: task),
          ),
          onDelete: () =>
              ref.read(taskNotifierProvider.notifier).deleteTask(task.id),
        );
      },
    );
  }
}
