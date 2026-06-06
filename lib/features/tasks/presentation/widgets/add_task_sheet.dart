// lib/features/tasks/presentation/widgets/add_task_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypilot/core/constants/app_constants.dart';
import 'package:daypilot/core/providers/providers.dart';
import 'package:daypilot/core/utils/date_utils.dart';
import 'package:daypilot/core/theme/app_theme.dart';
import 'package:daypilot/features/tasks/data/models/task_model.dart';

class AddTaskSheet extends ConsumerStatefulWidget {
  final TaskModel? existingTask;
  final String? initialDateKey;

  const AddTaskSheet({super.key, this.existingTask, this.initialDateKey});

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  late DateTime _selectedDate;
  late TaskPriority _priority;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingTask != null) {
      final t = widget.existingTask!;
      _titleController.text = t.title;
      _descController.text = t.description ?? '';
      _selectedDate = AppDateUtils.fromDateKey(t.dateKey);
      _priority = t.priority;
    } else {
      _selectedDate = widget.initialDateKey != null
          ? AppDateUtils.fromDateKey(widget.initialDateKey!)
          : DateTime.now();
      _priority = TaskPriority.medium;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.existingTask != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(_isEditing ? 'Edit Task' : 'New Task',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 20),

            // Title
            Text('Title', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              autofocus: !_isEditing,
              decoration: const InputDecoration(hintText: 'What needs to be done?'),
            ),
            const SizedBox(height: 16),

            // Description
            Text('Description (optional)', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Add more details...'),
            ),
            const SizedBox(height: 16),

            // Due date
            Text('Due Date', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface2 : AppTheme.lightSurface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      AppDateUtils.formatDateFull(_selectedDate),
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Priority
            Text('Priority', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: TaskPriority.values.map((p) {
                final isSelected = p == _priority;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: EdgeInsets.only(right: p != TaskPriority.high ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? p.color : p.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: p.color.withOpacity(isSelected ? 1 : 0.3),
                        ),
                      ),
                      child: Text(
                        p.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : p.color,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                if (_isEditing) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _deleteTask,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveTask,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_isEditing ? 'Save Changes' : 'Add Task'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(AppConstants.minYear),
      lastDate: DateTime(AppConstants.maxYear, 12, 31),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final notifier = ref.read(taskNotifierProvider.notifier);

    if (_isEditing) {
      final updated = widget.existingTask!.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        dateKey: AppDateUtils.toDateKey(_selectedDate),
        priorityIndex: _priority.index,
      );
      await notifier.updateTask(updated);
    } else {
      await notifier.addTask(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        dateKey: AppDateUtils.toDateKey(_selectedDate),
        priorityIndex: _priority.index,
      );
    }

    setState(() => _isSaving = false);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(taskNotifierProvider.notifier).deleteTask(widget.existingTask!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }
}
