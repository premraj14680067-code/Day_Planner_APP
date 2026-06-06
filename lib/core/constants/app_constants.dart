// lib/core/constants/app_constants.dart

import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'DayPilot';
  static const String appVersion = '1.0.0';

  // Supported Years
  static const int minYear = 2020;
  static const int maxYear = 2035;

  // Timeline Hours (5 AM to midnight)
  static const int plannerStartHour = 5;
  static const int plannerEndHour = 24;

  // Hive Box Names
  static const String settingsBox = 'settings_box';
  static const String plannerBlockBox = 'planner_block_box';
  static const String taskBox = 'task_box';
  static const String dailyStatsBox = 'daily_stats_box';
  static const String notesBox = 'notes_box';

  // Settings Keys
  static const String themeKey = 'theme_mode';
  static const String lastYearKey = 'last_year';
  static const String lastMonthKey = 'last_month';
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String categoryColorsKey = 'category_colors';

  // Block height in planner (pixels per hour)
  static const double hourHeightPx = 80.0;
  static const double timeColumnWidth = 60.0;
  static const double minBlockDurationMins = 15.0;
}

// Block categories
enum BlockCategory {
  study,
  revision,
  coaching,
  school,
  exercise,
  sleep,
  breakTime,
  meal,
  wastedTime,
  personalWork,
  other,
}

extension BlockCategoryExtension on BlockCategory {
  String get label {
    switch (this) {
      case BlockCategory.study:        return 'Study';
      case BlockCategory.revision:     return 'Revision';
      case BlockCategory.coaching:     return 'Coaching';
      case BlockCategory.school:       return 'School';
      case BlockCategory.exercise:     return 'Exercise';
      case BlockCategory.sleep:        return 'Sleep';
      case BlockCategory.breakTime:    return 'Break';
      case BlockCategory.meal:         return 'Meal';
      case BlockCategory.wastedTime:   return 'Wasted Time';
      case BlockCategory.personalWork: return 'Personal Work';
      case BlockCategory.other:        return 'Other';
    }
  }

  Color get defaultColor {
    switch (this) {
      case BlockCategory.study:        return const Color(0xFF4F8EF7);
      case BlockCategory.revision:     return const Color(0xFF9C6FE0);
      case BlockCategory.coaching:     return const Color(0xFF5BC4A0);
      case BlockCategory.school:       return const Color(0xFF38B2AC);
      case BlockCategory.exercise:     return const Color(0xFFF6AD55);
      case BlockCategory.sleep:        return const Color(0xFF76A9FA);
      case BlockCategory.breakTime:    return const Color(0xFFA0AEC0);
      case BlockCategory.meal:         return const Color(0xFF68D391);
      case BlockCategory.wastedTime:   return const Color(0xFFFC8181);
      case BlockCategory.personalWork: return const Color(0xFFED8936);
      case BlockCategory.other:        return const Color(0xFFCBD5E0);
    }
  }

  String get emoji {
    switch (this) {
      case BlockCategory.study:        return '📚';
      case BlockCategory.revision:     return '🔁';
      case BlockCategory.coaching:     return '🎓';
      case BlockCategory.school:       return '🏫';
      case BlockCategory.exercise:     return '🏃';
      case BlockCategory.sleep:        return '😴';
      case BlockCategory.breakTime:    return '☕';
      case BlockCategory.meal:         return '🍽️';
      case BlockCategory.wastedTime:   return '😑';
      case BlockCategory.personalWork: return '💼';
      case BlockCategory.other:        return '⬜';
    }
  }
}

// Task priority
enum TaskPriority { low, medium, high }

extension TaskPriorityExtension on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:    return 'Low';
      case TaskPriority.medium: return 'Medium';
      case TaskPriority.high:   return 'High';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:    return const Color(0xFF68D391);
      case TaskPriority.medium: return const Color(0xFFF6AD55);
      case TaskPriority.high:   return const Color(0xFFFC8181);
    }
  }

  int get value {
    switch (this) {
      case TaskPriority.low:    return 0;
      case TaskPriority.medium: return 1;
      case TaskPriority.high:   return 2;
    }
  }
}
