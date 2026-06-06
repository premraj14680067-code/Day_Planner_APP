// lib/core/providers/providers.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypilot/features/planner/data/repositories/planner_repository.dart';
import 'package:daypilot/features/tasks/data/repositories/task_repository.dart';
import 'package:daypilot/features/analytics/data/repositories/analytics_repository.dart';
import 'package:daypilot/features/notes/data/repositories/notes_repository.dart';
import 'package:daypilot/features/settings/data/repositories/settings_repository.dart';
import 'package:daypilot/features/settings/data/models/user_settings_model.dart';
import 'package:daypilot/features/planner/data/models/planner_block_model.dart';
import 'package:daypilot/features/tasks/data/models/task_model.dart';
import 'package:daypilot/features/analytics/data/models/daily_stats_model.dart';
import 'package:daypilot/features/notes/data/models/note_model.dart';
import 'package:daypilot/core/constants/app_constants.dart';
import 'package:uuid/uuid.dart';

// ─── Repository Providers ────────────────────────────────────────────────────

final plannerRepositoryProvider = Provider((ref) => PlannerRepository());
final taskRepositoryProvider = Provider((ref) => TaskRepository());
final analyticsRepositoryProvider = Provider((ref) => AnalyticsRepository());
final notesRepositoryProvider = Provider((ref) => NotesRepository());
final settingsRepositoryProvider = Provider((ref) => SettingsRepository());

// ─── Settings Provider ────────────────────────────────────────────────────────

class SettingsNotifier extends StateNotifier<UserSettingsModel> {
  final SettingsRepository _repo;

  SettingsNotifier(this._repo) : super(_repo.getSettings());

  Future<void> toggleTheme() async {
    await _repo.updateTheme(!state.isDarkMode);
    state = _repo.getSettings();
  }

  Future<void> setTheme(bool isDark) async {
    await _repo.updateTheme(isDark);
    state = _repo.getSettings();
  }

  Future<void> updateLastViewed(int year, int month) async {
    await _repo.updateLastViewed(year, month);
    state = _repo.getSettings();
  }

  Future<void> toggleNotifications() async {
    await _repo.updateNotifications(!state.notificationsEnabled);
    state = _repo.getSettings();
  }

  Future<void> updateCategoryColor(int categoryIndex, int colorValue) async {
    await _repo.updateCategoryColor(categoryIndex, colorValue);
    state = _repo.getSettings();
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, UserSettingsModel>(
  (ref) => SettingsNotifier(ref.read(settingsRepositoryProvider)),
);

final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;
});

// ─── Calendar Provider ────────────────────────────────────────────────────────

class CalendarNotifier extends StateNotifier<({int year, int month, DateTime? selectedDate})> {
  final SettingsNotifier _settingsNotifier;

  CalendarNotifier(this._settingsNotifier, UserSettingsModel settings)
      : super((
          year: settings.lastViewedYear,
          month: settings.lastViewedMonth,
          selectedDate: null,
        ));

  void selectDate(DateTime date) {
    state = (year: state.year, month: state.month, selectedDate: date);
  }

  void navigateToMonth(int year, int month) {
    // Handle year boundaries
    int newYear = year;
    int newMonth = month;
    if (newMonth > 12) { newMonth = 1; newYear++; }
    if (newMonth < 1) { newMonth = 12; newYear--; }
    newYear = newYear.clamp(AppConstants.minYear, AppConstants.maxYear);

    state = (year: newYear, month: newMonth, selectedDate: state.selectedDate);
    _settingsNotifier.updateLastViewed(newYear, newMonth);
  }

  void nextMonth() => navigateToMonth(state.year, state.month + 1);
  void prevMonth() => navigateToMonth(state.year, state.month - 1);

  void setYear(int year) => navigateToMonth(year, state.month);
  void setMonth(int month) => navigateToMonth(state.year, month);
}

final calendarProvider =
    StateNotifierProvider<CalendarNotifier, ({int year, int month, DateTime? selectedDate})>(
  (ref) {
    final settings = ref.read(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    return CalendarNotifier(settingsNotifier, settings);
  },
);

// ─── Planner Providers ───────────────────────────────────────────────────────

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final blocksForDateProvider = Provider.family<List<PlannerBlockModel>, String>((ref, dateKey) {
  ref.watch(plannerRefreshProvider);
  return ref.read(plannerRepositoryProvider).getBlocksForDate(dateKey);
});

final plannerRefreshProvider = StateProvider<int>((ref) => 0);

class PlannerNotifier extends StateNotifier<AsyncValue<List<PlannerBlockModel>>> {
  final PlannerRepository _repo;
  final AnalyticsRepository _analyticsRepo;
  final Ref _ref;
  String _currentDateKey = '';

  PlannerNotifier(this._repo, this._analyticsRepo, this._ref)
      : super(const AsyncValue.loading());

  void loadDate(String dateKey) {
    _currentDateKey = dateKey;
    final blocks = _repo.getBlocksForDate(dateKey);
    state = AsyncValue.data(blocks);
  }

  Future<bool> addBlock({
    required int categoryIndex,
    required int startMinutes,
    required int endMinutes,
    String? notes,
    String? title,
  }) async {
    if (_repo.hasOverlap(_currentDateKey, startMinutes, endMinutes)) {
      return false; // Overlap detected
    }

    final block = PlannerBlockModel(
      id: const Uuid().v4(),
      dateKey: _currentDateKey,
      categoryIndex: categoryIndex,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      notes: notes,
      title: title,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repo.saveBlock(block);
    await _analyticsRepo.computeAndSaveStats(_currentDateKey);
    loadDate(_currentDateKey);
    _ref.read(plannerRefreshProvider.notifier).state++;
    return true;
  }

  Future<bool> updateBlock(PlannerBlockModel block) async {
    if (_repo.hasOverlap(
        block.dateKey, block.startMinutes, block.endMinutes,
        excludeId: block.id)) {
      return false;
    }
    await _repo.updateBlock(block);
    await _analyticsRepo.computeAndSaveStats(_currentDateKey);
    loadDate(_currentDateKey);
    _ref.read(plannerRefreshProvider.notifier).state++;
    return true;
  }

  Future<void> deleteBlock(String blockId) async {
    await _repo.deleteBlock(blockId);
    await _analyticsRepo.computeAndSaveStats(_currentDateKey);
    loadDate(_currentDateKey);
    _ref.read(plannerRefreshProvider.notifier).state++;
  }

  Future<void> setActualDuration(String blockId, int actualMinutes) async {
    final block = state.value?.firstWhere((b) => b.id == blockId);
    if (block == null) return;
    await _repo.updateBlock(block.copyWith(actualDurationMinutes: actualMinutes));
    await _analyticsRepo.computeAndSaveStats(_currentDateKey);
    loadDate(_currentDateKey);
  }
}

final plannerNotifierProvider =
    StateNotifierProvider<PlannerNotifier, AsyncValue<List<PlannerBlockModel>>>((ref) {
  return PlannerNotifier(
    ref.read(plannerRepositoryProvider),
    ref.read(analyticsRepositoryProvider),
    ref,
  );
});

// ─── Task Providers ──────────────────────────────────────────────────────────

final taskRefreshProvider = StateProvider<int>((ref) => 0);

class TaskNotifier extends StateNotifier<List<TaskModel>> {
  final TaskRepository _repo;
  final Ref _ref;

  TaskNotifier(this._repo, this._ref) : super(_repo.getAllTasks());

  void _refresh() {
    state = _repo.getAllTasks();
    _ref.read(taskRefreshProvider.notifier).state++;
  }

  Future<void> addTask({
    required String title,
    String? description,
    required String dateKey,
    required int priorityIndex,
  }) async {
    final task = TaskModel(
      id: const Uuid().v4(),
      title: title,
      description: description,
      dateKey: dateKey,
      priorityIndex: priorityIndex,
      createdAt: DateTime.now(),
    );
    await _repo.saveTask(task);
    _refresh();
  }

  Future<void> updateTask(TaskModel task) async {
    await _repo.updateTask(task);
    _refresh();
  }

  Future<void> deleteTask(String taskId) async {
    await _repo.deleteTask(taskId);
    _refresh();
  }

  Future<void> toggleComplete(String taskId) async {
    final task = state.firstWhere((t) => t.id == taskId);
    final updated = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: !task.isCompleted ? DateTime.now() : null,
    );
    await _repo.updateTask(updated);
    _refresh();
  }

  List<TaskModel> getTasksForDate(String dateKey) {
    return _repo.getTasksForDate(dateKey);
  }

  List<TaskModel> getOverdueTasks() => _repo.getOverdueTasks();
  List<TaskModel> getUpcomingTasks() => _repo.getUpcomingTasks();
  List<TaskModel> getCompletedTasks() => _repo.getCompletedTasks();
}

final taskNotifierProvider =
    StateNotifierProvider<TaskNotifier, List<TaskModel>>((ref) {
  return TaskNotifier(ref.read(taskRepositoryProvider), ref);
});

final tasksForDateProvider = Provider.family<List<TaskModel>, String>((ref, dateKey) {
  ref.watch(taskRefreshProvider);
  return ref.read(taskRepositoryProvider).getTasksForDate(dateKey);
});

// ─── Analytics Providers ─────────────────────────────────────────────────────

final analyticsMonthProvider =
    Provider.family<List<DailyStatsModel>, ({int year, int month})>((ref, params) {
  ref.watch(plannerRefreshProvider);
  return ref.read(analyticsRepositoryProvider).getStatsForMonth(params.year, params.month);
});

final statsForDateProvider = Provider.family<DailyStatsModel?, String>((ref, dateKey) {
  ref.watch(plannerRefreshProvider);
  return ref.read(analyticsRepositoryProvider).getStatsForDate(dateKey);
});

// ─── Notes Provider ───────────────────────────────────────────────────────────

final notesRefreshProvider = StateProvider<int>((ref) => 0);

class NotesNotifier extends StateNotifier<NoteModel?> {
  final NotesRepository _repo;
  final Ref _ref;
  String _currentDateKey = '';

  NotesNotifier(this._repo, this._ref) : super(null);

  void loadForDate(String dateKey) {
    _currentDateKey = dateKey;
    state = _repo.getNoteForDate(dateKey);
  }

  Future<void> saveNote(String content) async {
    if (content.trim().isEmpty) {
      await _repo.deleteNote(_currentDateKey);
      state = null;
    } else {
      final existing = _repo.getNoteForDate(_currentDateKey);
      final note = NoteModel(
        id: existing?.id ?? const Uuid().v4(),
        dateKey: _currentDateKey,
        content: content,
        createdAt: existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _repo.saveNote(note);
      state = note;
    }
    _ref.read(notesRefreshProvider.notifier).state++;
  }
}

final notesNotifierProvider =
    StateNotifierProvider<NotesNotifier, NoteModel?>((ref) {
  return NotesNotifier(ref.read(notesRepositoryProvider), ref);
});

// ─── Category Color Provider ─────────────────────────────────────────────────

final categoryColorProvider = Provider.family<Color, BlockCategory>((ref, category) {
  final settings = ref.watch(settingsProvider);
  final customColor = settings.categoryColors['${category.index}'];
  if (customColor != null) return Color(customColor);
  return category.defaultColor;
});

// ─── Dates with blocks (for calendar dots) ───────────────────────────────────

final datesWithBlocksProvider = Provider.family<Set<String>, ({int year, int month})>((ref, params) {
  ref.watch(plannerRefreshProvider);
  final dates = ref.read(plannerRepositoryProvider)
      .getDatesWithBlocks(params.year, params.month);
  return dates.toSet();
});
