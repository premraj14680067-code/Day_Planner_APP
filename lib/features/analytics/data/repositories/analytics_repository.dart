// lib/features/analytics/data/repositories/analytics_repository.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'package:daypilot/core/constants/app_constants.dart';
import 'package:daypilot/features/analytics/data/models/daily_stats_model.dart';
import 'package:daypilot/features/planner/data/models/planner_block_model.dart';

class AnalyticsRepository {
  Box<DailyStatsModel> get _statsBox =>
      Hive.box<DailyStatsModel>(AppConstants.dailyStatsBox);
  Box<PlannerBlockModel> get _blocksBox =>
      Hive.box<PlannerBlockModel>(AppConstants.plannerBlockBox);

  /// Recompute stats for a date from planner blocks
  Future<DailyStatsModel> computeAndSaveStats(String dateKey) async {
    final blocks = _blocksBox.values
        .where((b) => b.dateKey == dateKey)
        .toList();

    int study = 0, revision = 0, sleep = 0, wasted = 0,
        exercise = 0, coaching = 0, breakT = 0, meal = 0,
        school = 0, personal = 0, other = 0;

    for (final b in blocks) {
      final dur = b.actualDurationMinutes ?? b.plannedDurationMinutes;
      switch (b.category) {
        case BlockCategory.study:        study += dur; break;
        case BlockCategory.revision:     revision += dur; break;
        case BlockCategory.sleep:        sleep += dur; break;
        case BlockCategory.wastedTime:   wasted += dur; break;
        case BlockCategory.exercise:     exercise += dur; break;
        case BlockCategory.coaching:     coaching += dur; break;
        case BlockCategory.breakTime:    breakT += dur; break;
        case BlockCategory.meal:         meal += dur; break;
        case BlockCategory.school:       school += dur; break;
        case BlockCategory.personalWork: personal += dur; break;
        case BlockCategory.other:        other += dur; break;
      }
    }

    final stats = DailyStatsModel(
      dateKey: dateKey,
      studyMinutes: study,
      revisionMinutes: revision,
      sleepMinutes: sleep,
      wastedMinutes: wasted,
      exerciseMinutes: exercise,
      coachingMinutes: coaching,
      breakMinutes: breakT,
      mealMinutes: meal,
      schoolMinutes: school,
      personalWorkMinutes: personal,
      otherMinutes: other,
      updatedAt: DateTime.now(),
    );

    await _statsBox.put(dateKey, stats);
    return stats;
  }

  DailyStatsModel? getStatsForDate(String dateKey) {
    return _statsBox.get(dateKey);
  }

  List<DailyStatsModel> getStatsForMonth(int year, int month) {
    final prefix = '$year-${month.toString().padLeft(2, '0')}-';
    return _statsBox.values
        .where((s) => s.dateKey.startsWith(prefix))
        .toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
  }

  List<DailyStatsModel> getStatsForYear(int year) {
    return _statsBox.values
        .where((s) => s.dateKey.startsWith('$year-'))
        .toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
  }

  Future<void> deleteAllStats() async {
    await _statsBox.clear();
  }

  /// Calculate consistency score for a month (0-100)
  /// Based on days with at least 1 hour of productive activity
  double getConsistencyScore(int year, int month) {
    final stats = getStatsForMonth(year, month);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final activeDays = stats.where((s) => s.totalProductiveMinutes >= 60).length;
    return (activeDays / daysInMonth * 100).clamp(0, 100);
  }

  /// Get best day (most study hours) in a month
  DailyStatsModel? getBestDay(int year, int month) {
    final stats = getStatsForMonth(year, month);
    if (stats.isEmpty) return null;
    return stats.reduce((a, b) =>
        a.totalProductiveMinutes > b.totalProductiveMinutes ? a : b);
  }

  /// Get worst day (most wasted time) in a month  
  DailyStatsModel? getWorstDay(int year, int month) {
    final stats = getStatsForMonth(year, month).where((s) => s.wastedMinutes > 0).toList();
    if (stats.isEmpty) return null;
    return stats.reduce((a, b) => a.wastedMinutes > b.wastedMinutes ? a : b);
  }

  /// Calculate study streak (consecutive days with >= 30 min study)
  int getStudyStreak() {
    final allStats = _statsBox.values.toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));

    int streak = 0;
    DateTime? prevDate;

    for (final stat in allStats) {
      if (stat.studyMinutes < 30) break;
      final parts = stat.dateKey.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

      if (prevDate == null) {
        prevDate = date;
        streak = 1;
      } else {
        final diff = prevDate.difference(date).inDays;
        if (diff == 1) {
          streak++;
          prevDate = date;
        } else {
          break;
        }
      }
    }
    return streak;
  }
}
