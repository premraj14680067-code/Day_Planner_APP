// lib/features/tasks/data/repositories/task_repository.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'package:daypilot/core/constants/app_constants.dart';
import 'package:daypilot/features/tasks/data/models/task_model.dart';

abstract class ITaskRepository {
  List<TaskModel> getTasksForDate(String dateKey);
  List<TaskModel> getAllTasks();
  List<TaskModel> getOverdueTasks();
  List<TaskModel> getUpcomingTasks();
  List<TaskModel> getCompletedTasks();
  Future<void> saveTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String taskId);
  Future<void> deleteAllTasks();
}

class TaskRepository implements ITaskRepository {
  Box<TaskModel> get _box => Hive.box<TaskModel>(AppConstants.taskBox);

  @override
  List<TaskModel> getTasksForDate(String dateKey) {
    return _box.values.where((t) => t.dateKey == dateKey).toList()
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return b.priorityIndex.compareTo(a.priorityIndex);
      });
  }

  @override
  List<TaskModel> getAllTasks() {
    return _box.values.toList();
  }

  @override
  List<TaskModel> getOverdueTasks() {
    return _box.values.where((t) => t.isOverdue).toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
  }

  @override
  List<TaskModel> getUpcomingTasks() {
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    return _box.values
        .where((t) => !t.isCompleted && t.dateKey.compareTo(todayKey) > 0)
        .toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
  }

  @override
  List<TaskModel> getCompletedTasks() {
    return _box.values.where((t) => t.isCompleted).toList()
      ..sort((a, b) =>
          (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));
  }

  @override
  Future<void> saveTask(TaskModel task) async {
    await _box.put(task.id, task);
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    await _box.put(task.id, task);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _box.delete(taskId);
  }

  @override
  Future<void> deleteAllTasks() async {
    await _box.clear();
  }
}
