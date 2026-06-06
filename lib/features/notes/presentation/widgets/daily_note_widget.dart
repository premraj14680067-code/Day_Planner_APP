// lib/features/notes/presentation/widgets/daily_note_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypilot/core/providers/providers.dart';
import 'package:daypilot/core/theme/app_theme.dart';

class DailyNoteWidget extends ConsumerStatefulWidget {
  final String dateKey;
  const DailyNoteWidget({super.key, required this.dateKey});

  @override
  ConsumerState<DailyNoteWidget> createState() => _DailyNoteWidgetState();
}

class _DailyNoteWidgetState extends ConsumerState<DailyNoteWidget> {
  late TextEditingController _controller;
  bool _isDirty = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final note = ref.read(notesNotifierProvider);
    _controller = TextEditingController(text: note?.content ?? '');
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    setState(() => _isSaving = true);
    await ref.read(notesNotifierProvider.notifier).saveNote(_controller.text);
    setState(() {
      _isSaving = false;
      _isDirty = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note saved'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.notes_rounded, size: 18, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Text('Daily Notes',
                  style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.primaryBlue)),
              const Spacer(),
              if (_isDirty)
                TextButton.icon(
                  onPressed: _isSaving ? null : _saveNote,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Save'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primaryBlue),
                ),
            ],
          ),
        ),
        // Note editor
        Expanded(
          child: TextField(
            controller: _controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.7,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: '✏️  Write notes, ideas, reflections, or reminders for today...\n\n'
                  '• Mistakes to avoid\n'
                  '• Topics to revise\n'
                  '• Key learnings\n'
                  '• Tomorrow\'s plan',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.35),
                height: 1.8,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
              filled: false,
            ),
          ),
        ),
        // Word count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          alignment: Alignment.centerRight,
          child: Text(
            '${_controller.text.trim().isEmpty ? 0 : _controller.text.trim().split(RegExp(r'\s+')).length} words',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.35),
            ),
          ),
        ),
      ],
    );
  }
}
