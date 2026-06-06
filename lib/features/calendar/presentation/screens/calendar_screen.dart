// lib/features/calendar/presentation/screens/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:daypilot/core/constants/app_constants.dart';
import 'package:daypilot/core/providers/providers.dart';
import 'package:daypilot/core/utils/date_utils.dart';
import 'package:daypilot/core/theme/app_theme.dart';
import 'package:daypilot/features/planner/presentation/screens/planner_screen.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calState = ref.watch(calendarProvider);

    return Scaffold(
      appBar: _CalendarAppBar(year: calState.year, month: calState.month),
      body: Column(
        children: [
          _MonthNavigationBar(year: calState.year, month: calState.month),
          _WeekdayHeader(),
          Expanded(
            child: _CalendarGrid(
              year: calState.year,
              month: calState.month,
              selectedDate: calState.selectedDate,
            ),
          ),
          if (calState.selectedDate != null)
            _SelectedDayPreview(date: calState.selectedDate!),
        ],
      ),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _CalendarAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final int year;
  final int month;

  const _CalendarAppBar({required this.year, required this.month});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 20, color: AppTheme.primaryBlue),
          const SizedBox(width: 8),
          Text(
            AppConstants.appName,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.today_outlined),
          tooltip: 'Go to today',
          onPressed: () {
            final now = DateTime.now();
            ref.read(calendarProvider.notifier).navigateToMonth(now.year, now.month);
            ref.read(calendarProvider.notifier).selectDate(now);
          },
        ),
      ],
    );
  }
}

// ─── Month Navigation ────────────────────────────────────────────────────────

class _MonthNavigationBar extends ConsumerWidget {
  final int year;
  final int month;

  const _MonthNavigationBar({required this.year, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(calendarProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Year dropdown
          _StyledDropdown<int>(
            value: year,
            items: List.generate(
              AppConstants.maxYear - AppConstants.minYear + 1,
              (i) => AppConstants.minYear + i,
            ),
            labelBuilder: (y) => y.toString(),
            onChanged: (y) => notifier.setYear(y!),
          ),
          const SizedBox(width: 8),
          // Month dropdown
          _StyledDropdown<int>(
            value: month,
            items: List.generate(12, (i) => i + 1),
            labelBuilder: (m) => AppDateUtils.getMonthName(m),
            onChanged: (m) => notifier.setMonth(m!),
          ),
          const Spacer(),
          // Navigation arrows
          _NavButton(
            icon: Icons.chevron_left_rounded,
            onTap: notifier.prevMonth,
          ),
          const SizedBox(width: 4),
          _NavButton(
            icon: Icons.chevron_right_rounded,
            onTap: notifier.nextMonth,
          ),
        ],
      ),
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;

  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface2 : AppTheme.lightSurface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          style: theme.textTheme.titleMedium,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(labelBuilder(item)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface2 : AppTheme.lightSurface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
        child: Icon(icon, size: 22),
      ),
    );
  }
}

// ─── Weekday Header ───────────────────────────────────────────────────────────

class _WeekdayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: days.map((d) {
          final isWeekend = d == 'Sat' || d == 'Sun';
          return Expanded(
            child: Center(
              child: Text(
                d,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isWeekend
                      ? AppTheme.primaryBlue.withOpacity(0.6)
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Calendar Grid ────────────────────────────────────────────────────────────

class _CalendarGrid extends ConsumerWidget {
  final int year;
  final int month;
  final DateTime? selectedDate;

  const _CalendarGrid({
    required this.year,
    required this.month,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datesWithBlocks = ref.watch(
        datesWithBlocksProvider((year: year, month: month)));

    final firstDay = DateTime(year, month, 1);
    final daysInMonth = AppDateUtils.daysInMonth(year, month);
    // Monday=1, so offset for grid
    final startOffset = (firstDay.weekday - 1) % 7;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.85,
      ),
      itemCount: rows * 7,
      itemBuilder: (context, index) {
        final dayNumber = index - startOffset + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final date = DateTime(year, month, dayNumber);
        final dateKey = AppDateUtils.toDateKey(date);
        final isToday = AppDateUtils.isToday(date);
        final isSelected = selectedDate != null && AppDateUtils.isSameDay(date, selectedDate!);
        final hasBlocks = datesWithBlocks.contains(dateKey);

        return _DayCell(
          date: date,
          isToday: isToday,
          isSelected: isSelected,
          hasBlocks: hasBlocks,
          onTap: () {
            ref.read(calendarProvider.notifier).selectDate(date);
          },
          onDoubleTap: () {
            ref.read(calendarProvider.notifier).selectDate(date);
            _openPlanner(context, ref, date);
          },
        );
      },
    );
  }

  void _openPlanner(BuildContext context, WidgetRef ref, DateTime date) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderScope(
          overrides: [
            selectedDateProvider.overrideWith((ref) => date),
          ],
          child: const PlannerScreen(),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final bool hasBlocks;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  const _DayCell({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.hasBlocks,
    required this.onTap,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bgColor = Colors.transparent;
    Color textColor = theme.colorScheme.onSurface;

    if (isSelected) {
      bgColor = AppTheme.primaryBlue;
      textColor = Colors.white;
    } else if (isToday) {
      bgColor = AppTheme.primaryBlue.withOpacity(0.12);
      textColor = AppTheme.primaryBlue;
    }

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !isSelected
              ? Border.all(color: AppTheme.primaryBlue, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 3),
            if (hasBlocks)
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.8)
                      : AppTheme.primaryBlue.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}

// ─── Selected Day Preview ─────────────────────────────────────────────────────

class _SelectedDayPreview extends ConsumerWidget {
  final DateTime date;

  const _SelectedDayPreview({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateKey = AppDateUtils.toDateKey(date);
    final blocks = ref.watch(blocksForDateProvider(dateKey));
    final tasks = ref.watch(tasksForDateProvider(dateKey));
    final stats = ref.watch(statsForDateProvider(dateKey));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppDateUtils.formatDateFull(date),
                  style: theme.textTheme.titleLarge,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProviderScope(
                        overrides: [
                          selectedDateProvider.overrideWith((ref) => date),
                        ],
                        child: const PlannerScreen(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Open Planner'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                icon: Icons.book_outlined,
                label: stats != null
                    ? AppDateUtils.formatMinutes(stats.studyMinutes)
                    : '0m',
                color: BlockCategory.study.defaultColor,
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.check_circle_outline,
                label: '${tasks.where((t) => t.isCompleted).length}/${tasks.length} tasks',
                color: AppTheme.accentTeal,
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.view_timeline_outlined,
                label: '${blocks.length} blocks',
                color: AppTheme.accentPurple,
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3, end: 0, duration: 300.ms, curve: Curves.easeOut)
     .fadeIn(duration: 300.ms);
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
