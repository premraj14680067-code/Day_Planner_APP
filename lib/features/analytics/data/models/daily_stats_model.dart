// lib/features/analytics/data/models/daily_stats_model.dart

import 'package:hive/hive.dart';

part 'daily_stats_model.g.dart';

@HiveType(typeId: 2)
class DailyStatsModel extends HiveObject {
  @HiveField(0) String dateKey;
  @HiveField(1) int studyMinutes;
  @HiveField(2) int revisionMinutes;
  @HiveField(3) int sleepMinutes;
  @HiveField(4) int wastedMinutes;
  @HiveField(5) int exerciseMinutes;
  @HiveField(6) int coachingMinutes;
  @HiveField(7) int breakMinutes;
  @HiveField(8) int mealMinutes;
  @HiveField(9) int schoolMinutes;
  @HiveField(10) int personalWorkMinutes;
  @HiveField(11) int otherMinutes;
  @HiveField(12) DateTime updatedAt;

  DailyStatsModel({
    required this.dateKey,
    this.studyMinutes = 0,
    this.revisionMinutes = 0,
    this.sleepMinutes = 0,
    this.wastedMinutes = 0,
    this.exerciseMinutes = 0,
    this.coachingMinutes = 0,
    this.breakMinutes = 0,
    this.mealMinutes = 0,
    this.schoolMinutes = 0,
    this.personalWorkMinutes = 0,
    this.otherMinutes = 0,
    required this.updatedAt,
  });

  int get totalProductiveMinutes =>
      studyMinutes + revisionMinutes + coachingMinutes + schoolMinutes;

  double get studyHours => studyMinutes / 60.0;
  double get revisionHours => revisionMinutes / 60.0;
  double get sleepHours => sleepMinutes / 60.0;
  double get wastedHours => wastedMinutes / 60.0;

  DailyStatsModel copyWith({
    String? dateKey,
    int? studyMinutes,
    int? revisionMinutes,
    int? sleepMinutes,
    int? wastedMinutes,
    int? exerciseMinutes,
    int? coachingMinutes,
    int? breakMinutes,
    int? mealMinutes,
    int? schoolMinutes,
    int? personalWorkMinutes,
    int? otherMinutes,
    DateTime? updatedAt,
  }) {
    return DailyStatsModel(
      dateKey: dateKey ?? this.dateKey,
      studyMinutes: studyMinutes ?? this.studyMinutes,
      revisionMinutes: revisionMinutes ?? this.revisionMinutes,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
      wastedMinutes: wastedMinutes ?? this.wastedMinutes,
      exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
      coachingMinutes: coachingMinutes ?? this.coachingMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      mealMinutes: mealMinutes ?? this.mealMinutes,
      schoolMinutes: schoolMinutes ?? this.schoolMinutes,
      personalWorkMinutes: personalWorkMinutes ?? this.personalWorkMinutes,
      otherMinutes: otherMinutes ?? this.otherMinutes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
