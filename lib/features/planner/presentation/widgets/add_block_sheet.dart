// lib/features/planner/presentation/widgets/add_block_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypilot/core/constants/app_constants.dart';
import 'package:daypilot/core/providers/providers.dart';
import 'package:daypilot/core/utils/date_utils.dart';
import 'package:daypilot/core/theme/app_theme.dart';
import 'package:daypilot/features/planner/data/models/planner_block_model.dart';

class AddBlockSheet extends ConsumerStatefulWidget {
  final String dateKey;
  final int? initialStartMinutes;
  final PlannerBlockModel? existingBlock;

  const AddBlockSheet({
    super.key,
    required this.dateKey,
    this.initialStartMinutes,
    this.existingBlock,
  });

  @override
  ConsumerState<AddBlockSheet> createState() => _AddBlockSheetState();
}

class _AddBlockSheetState extends ConsumerState<AddBlockSheet> {
  late BlockCategory _selectedCategory;
  late int _startMinutes;
  late int _endMinutes;
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingBlock != null) {
      final b = widget.existingBlock!;
      _selectedCategory = b.category;
      _startMinutes = b.startMinutes;
      _endMinutes = b.endMinutes;
      _titleController.text = b.title ?? '';
      _notesController.text = b.notes ?? '';
    } else {
      _selectedCategory = BlockCategory.study;
      _startMinutes = widget.initialStartMinutes ??
          AppConstants.plannerStartHour * 60;
      _endMinutes = _startMinutes + 60;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.existingBlock != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = ref.watch(categoryColorProvider(_selectedCategory));

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
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              _isEditing ? 'Edit Block' : 'Add Block',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),

            // Category selection
            Text('Category', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            _CategoryGrid(
              selectedCategory: _selectedCategory,
              onCategorySelected: (c) => setState(() => _selectedCategory = c),
            ),
            const SizedBox(height: 20),

            // Title field
            Text('Title (optional)', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'e.g. Physics - Kinematics',
              ),
            ),
            const SizedBox(height: 16),

            // Time selection
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start Time', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      _TimeSelector(
                        minutes: _startMinutes,
                        onChanged: (m) => setState(() {
                          _startMinutes = m;
                          if (_endMinutes <= _startMinutes) {
                            _endMinutes = _startMinutes + 60;
                          }
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('End Time', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      _TimeSelector(
                        minutes: _endMinutes,
                        onChanged: (m) => setState(() {
                          _endMinutes = m;
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Duration display
            Center(
              child: Text(
                'Duration: ${AppDateUtils.formatMinutes(_endMinutes - _startMinutes)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            Text('Notes (optional)', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any notes for this block...',
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                if (_isEditing)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _deleteBlock,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                if (_isEditing) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveBlock,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isEditing ? 'Save Changes' : 'Add Block'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBlock() async {
    if (_endMinutes <= _startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() => _isSaving = true);

    bool success;
    final notifier = ref.read(plannerNotifierProvider.notifier);

    if (_isEditing) {
      final updated = widget.existingBlock!.copyWith(
        categoryIndex: _selectedCategory.index,
        startMinutes: _startMinutes,
        endMinutes: _endMinutes,
        title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      success = await notifier.updateBlock(updated);
    } else {
      success = await notifier.addBlock(
        categoryIndex: _selectedCategory.index,
        startMinutes: _startMinutes,
        endMinutes: _endMinutes,
        title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
    }

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This time slot overlaps with an existing block'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteBlock() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Block'),
        content: const Text('Are you sure you want to delete this block?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(plannerNotifierProvider.notifier)
          .deleteBlock(widget.existingBlock!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }
}

// ─── Category Grid ────────────────────────────────────────────────────────────

class _CategoryGrid extends ConsumerWidget {
  final BlockCategory selectedCategory;
  final ValueChanged<BlockCategory> onCategorySelected;

  const _CategoryGrid({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: BlockCategory.values.map((category) {
        final color = ref.watch(categoryColorProvider(category));
        final isSelected = category == selectedCategory;

        return GestureDetector(
          onTap: () => onCategorySelected(category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? color : color.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(category.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Text(
                  category.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Time Selector ────────────────────────────────────────────────────────────

class _TimeSelector extends StatelessWidget {
  final int minutes;
  final ValueChanged<int> onChanged;

  const _TimeSelector({required this.minutes, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => _showTimePicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface2 : AppTheme.lightSurface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 16),
            const SizedBox(width: 8),
            Text(
              AppDateUtils.formatTimeFromMinutes(minutes),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour % 24, minute: minute),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );

    if (picked != null) {
      onChanged(picked.hour * 60 + picked.minute);
    }
  }
}
