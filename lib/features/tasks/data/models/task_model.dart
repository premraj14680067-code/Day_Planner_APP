// lib/features/tasks/data/models/task_model.dart

import 'package:hive/hive.dart';
import 'package:daypilot/core/constants/app_constants.dart';

part 'task_model.g.dart';

@HiveType(typeId: 1)
class TaskModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String title;
  @HiveField(2) String? description;
  @HiveField(3) String dateKey;   // 'yyyy-MM-dd'
  @HiveField(4) int priorityIndex;
  @HiveField(5) bool isCompleted;
  @HiveField(6) DateTime createdAt;
  @HiveField(7) DateTime? completedAt;
  @HiveField(8) String? linkedBlockId;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.dateKey,
    required this.priorityIndex,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.linkedBlockId,
  });

  TaskPriority get priority => TaskPriority.values[priorityIndex];

  bool get isOverdue {
    if (isCompleted) return false;
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    return dateKey.compareTo(todayKey) < 0;
  }

  bool get isToday {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    return dateKey == todayKey;
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? dateKey,
    int? priorityIndex,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    String? linkedBlockId,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateKey: dateKey ?? this.dateKey,
      priorityIndex: priorityIndex ?? this.priorityIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      linkedBlockId: linkedBlockId ?? this.linkedBlockId,
    );
  }
}
