// lib/features/planner/presentation/screens/planner_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypilot/core/constants/app_constants.dart';
import 'package:daypilot/core/providers/providers.dart';
import 'package:daypilot/core/utils/date_utils.dart';
import 'package:daypilot/core/theme/app_theme.dart';
import 'package:daypilot/features/planner/data/models/planner_block_model.dart';
import 'package:daypilot/features/planner/presentation/widgets/block_card.dart';
import 'package:daypilot/features/planner/presentation/widgets/add_block_sheet.dart';
import 'package:daypilot/features/notes/presentation/widgets/daily_note_widget.dart';
import 'package:daypilot/features/tasks/presentation/widgets/day_tasks_widget.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _timelineScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final date = ref.read(selectedDateProvider);
      final dateKey = AppDateUtils.toDateKey(date);
      ref.read(plannerNotifierProvider.notifier).loadDate(dateKey);
      ref.read(notesNotifierProvider.notifier).loadForDate(dateKey);

      // Scroll to current hour
      final now = DateTime.now();
      final scrollOffset = (now.hour - AppConstants.plannerStartHour)
          .clamp(0, AppConstants.plannerEndHour - AppConstants.plannerStartHour)
          .toDouble() * AppConstants.hourHeightPx;
      if (scrollOffset > 0) {
        _timelineScroll.animateTo(
          scrollOffset,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timelineScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final date = ref.watch(selectedDateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppDateUtils.getMonthName(date.month) + ' ${date.day}',
              style: theme.textTheme.headlineMedium,
            ),
            Text(
              AppDateUtils.getDayName(date.weekday),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Timeline'),
            Tab(text: 'Tasks'),
            Tab(text: 'Notes'),
          ],
        ),
        actions: [
          // Date navigation
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () {
              final newDate = date.subtract(const Duration(days: 1));
              ref.read(selectedDateProvider.notifier).state = newDate;
              ref.read(plannerNotifierProvider.notifier).loadDate(AppDateUtils.toDateKey(newDate));
              ref.read(notesNotifierProvider.notifier).loadForDate(AppDateUtils.toDateKey(newDate));
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () {
              final newDate = date.add(const Duration(days: 1));
              ref.read(selectedDateProvider.notifier).state = newDate;
              ref.read(plannerNotifierProvider.notifier).loadDate(AppDateUtils.toDateKey(newDate));
              ref.read(notesNotifierProvider.notifier).loadForDate(AppDateUtils.toDateKey(newDate));
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TimelineTab(scrollController: _timelineScroll),
          DayTasksWidget(dateKey: AppDateUtils.toDateKey(date)),
          DailyNoteWidget(dateKey: AppDateUtils.toDateKey(date)),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddBlockSheet(context, ref, date),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Block'),
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  void _showAddBlockSheet(BuildContext context, WidgetRef ref, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBlockSheet(
        dateKey: AppDateUtils.toDateKey(date),
        initialStartMinutes: null,
      ),
    );
  }
}

// ─── Timeline Tab ─────────────────────────────────────────────────────────────

class _TimelineTab extends ConsumerWidget {
  final ScrollController scrollController;
  const _TimelineTab({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plannerState = ref.watch(plannerNotifierProvider);
    final date = ref.watch(selectedDateProvider);

    return plannerState.when(
      data: (blocks) => _buildTimeline(context, ref, blocks, date),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildTimeline(
      BuildContext context, WidgetRef ref, List<PlannerBlockModel> blocks, DateTime date) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalHours = AppConstants.plannerEndHour - AppConstants.plannerStartHour;
    final totalHeight = totalHours * AppConstants.hourHeightPx;

    return SingleChildScrollView(
      controller: scrollController,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time column
            SizedBox(
              width: AppConstants.timeColumnWidth,
              height: totalHeight,
              child: Stack(
                children: List.generate(totalHours + 1, (i) {
                  final hour = AppConstants.plannerStartHour + i;
                  final y = i * AppConstants.hourHeightPx;
                  return Positioned(
                    top: y - 8,
                    left: 0,
                    right: 0,
                    child: Text(
                      _formatHour(hour),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.45),
                        fontSize: 10,
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Blocks column
            Expanded(
              child: SizedBox(
                height: totalHeight,
                child: Stack(
                  children: [
                    // Hour grid lines
                    ...List.generate(totalHours + 1, (i) {
                      return Positioned(
                        top: i * AppConstants.hourHeightPx,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 0.5,
                          color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder)
                              .withOpacity(0.6),
                        ),
                      );
                    }),
                    // 30-min lines
                    ...List.generate(totalHours, (i) {
                      return Positioned(
                        top: i * AppConstants.hourHeightPx + AppConstants.hourHeightPx / 2,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 0.5,
                          color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder)
                              .withOpacity(0.3),
                        ),
                      );
                    }),
                    // Current time indicator
                    if (AppDateUtils.isToday(date))
                      _CurrentTimeIndicator(),
                    // Blocks
                    ...blocks.map((block) => _PositionedBlock(block: block)),
                    // Tap to create
                    Positioned.fill(
                      child: _TapToCreateOverlay(
                        blocks: blocks,
                        date: date,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0 || hour == 24) return '12AM';
    if (hour == 12) return '12PM';
    if (hour < 12) return '${hour}AM';
    return '${hour - 12}PM';
  }
}

// ─── Current Time Indicator ───────────────────────────────────────────────────

class _CurrentTimeIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final minutesSinceStart = (now.hour - AppConstants.plannerStartHour) * 60 + now.minute;
    final top = minutesSinceStart * AppConstants.hourHeightPx / 60;

    if (top < 0) return const SizedBox.shrink();

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              height: 1.5,
              color: Colors.red.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Positioned Block ─────────────────────────────────────────────────────────

class _PositionedBlock extends ConsumerWidget {
  final PlannerBlockModel block;
  const _PositionedBlock({required this.block});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startOffset = (block.startMinutes - AppConstants.plannerStartHour * 60);
    final top = startOffset * AppConstants.hourHeightPx / 60;
    final height = (block.endMinutes - block.startMinutes) * AppConstants.hourHeightPx / 60;
    final color = ref.watch(categoryColorProvider(block.category));

    return Positioned(
      top: top,
      left: 4,
      right: 4,
      height: height.clamp(20.0, double.infinity),
      child: BlockCard(
        block: block,
        color: color,
        onTap: () => _showBlockOptions(context, ref, block),
      ),
    );
  }

  void _showBlockOptions(BuildContext context, WidgetRef ref, PlannerBlockModel block) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBlockSheet(
        dateKey: block.dateKey,
        existingBlock: block,
      ),
    );
  }
}

// ─── Tap to Create Overlay ────────────────────────────────────────────────────

class _TapToCreateOverlay extends ConsumerWidget {
  final List<PlannerBlockModel> blocks;
  final DateTime date;

  const _TapToCreateOverlay({required this.blocks, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (details) {
        final tapY = details.localPosition.dy;
        final tappedMinutes =
            (tapY / AppConstants.hourHeightPx * 60).round() +
                AppConstants.plannerStartHour * 60;
        // Snap to 15 min
        final snapped = (tappedMinutes / 15).round() * 15;

        // Check if tapping on empty space
        final onBlock = blocks.any((b) =>
            snapped >= b.startMinutes && snapped < b.endMinutes);
        if (!onBlock) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddBlockSheet(
              dateKey: AppDateUtils.toDateKey(date),
              initialStartMinutes: snapped,
            ),
          );
        }
      },
    );
  }
}
