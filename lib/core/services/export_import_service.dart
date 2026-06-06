// lib/core/services/export_import_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:daypilot/core/constants/app_constants.dart';
import 'package:daypilot/features/planner/data/models/planner_block_model.dart';
import 'package:daypilot/features/tasks/data/models/task_model.dart';
import 'package:daypilot/features/analytics/data/models/daily_stats_model.dart';
import 'package:daypilot/features/notes/data/models/note_model.dart';

class ExportImportService {
  /// Export all data to a JSON file and return the file path
  Future<String> exportData() async {
    final blocksBox = Hive.box<PlannerBlockModel>(AppConstants.plannerBlockBox);
    final tasksBox = Hive.box<TaskModel>(AppConstants.taskBox);
    final statsBox = Hive.box<DailyStatsModel>(AppConstants.dailyStatsBox);
    final notesBox = Hive.box<NoteModel>(AppConstants.notesBox);

    final exportData = {
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'blocks': blocksBox.values.map((b) => _blockToJson(b)).toList(),
      'tasks': tasksBox.values.map((t) => _taskToJson(t)).toList(),
      'stats': statsBox.values.map((s) => _statsToJson(s)).toList(),
      'notes': notesBox.values.map((n) => _noteToJson(n)).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData);
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/daypilot_backup_$timestamp.json');
    await file.writeAsString(jsonStr);
    return file.path;
  }

  /// Share the exported file
  Future<void> shareExportedFile(String path) async {
    await Share.shareXFiles([XFile(path)], text: 'DayPilot Data Backup');
  }

  /// Import data from a JSON file
  Future<void> importData() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      throw Exception('No file selected');
    }

    final file = File(result.files.single.path!);
    final jsonStr = await file.readAsString();
    final data = json.decode(jsonStr) as Map<String, dynamic>;

    // Validate version
    if (data['version'] == null) {
      throw Exception('Invalid backup file format');
    }

    final blocksBox = Hive.box<PlannerBlockModel>(AppConstants.plannerBlockBox);
    final tasksBox = Hive.box<TaskModel>(AppConstants.taskBox);
    final statsBox = Hive.box<DailyStatsModel>(AppConstants.dailyStatsBox);
    final notesBox = Hive.box<NoteModel>(AppConstants.notesBox);

    // Import blocks
    final blocks = data['blocks'] as List<dynamic>? ?? [];
    for (final b in blocks) {
      final block = _blockFromJson(b as Map<String, dynamic>);
      await blocksBox.put(block.id, block);
    }

    // Import tasks
    final tasks = data['tasks'] as List<dynamic>? ?? [];
    for (final t in tasks) {
      final task = _taskFromJson(t as Map<String, dynamic>);
      await tasksBox.put(task.id, task);
    }

    // Import stats
    final stats = data['stats'] as List<dynamic>? ?? [];
    for (final s in stats) {
      final stat = _statsFromJson(s as Map<String, dynamic>);
      await statsBox.put(stat.dateKey, stat);
    }

    // Import notes
    final notes = data['notes'] as List<dynamic>? ?? [];
    for (final n in notes) {
      final note = _noteFromJson(n as Map<String, dynamic>);
      await notesBox.put(note.dateKey, note);
    }
  }

  // ─── Serialization helpers ────────────────────────────────────────────────

  Map<String, dynamic> _blockToJson(PlannerBlockModel b) => {
    'id': b.id,
    'dateKey': b.dateKey,
    'categoryIndex': b.categoryIndex,
    'startMinutes': b.startMinutes,
    'endMinutes': b.endMinutes,
    'notes': b.notes,
    'actualDurationMinutes': b.actualDurationMinutes,
    'title': b.title,
    'createdAt': b.createdAt.toIso8601String(),
    'updatedAt': b.updatedAt.toIso8601String(),
  };

  PlannerBlockModel _blockFromJson(Map<String, dynamic> j) => PlannerBlockModel(
    id: j['id'] as String,
    dateKey: j['dateKey'] as String,
    categoryIndex: j['categoryIndex'] as int,
    startMinutes: j['startMinutes'] as int,
    endMinutes: j['endMinutes'] as int,
    notes: j['notes'] as String?,
    actualDurationMinutes: j['actualDurationMinutes'] as int?,
    title: j['title'] as String?,
    createdAt: DateTime.parse(j['createdAt'] as String),
    updatedAt: DateTime.parse(j['updatedAt'] as String),
  );

  Map<String, dynamic> _taskToJson(TaskModel t) => {
    'id': t.id,
    'title': t.title,
    'description': t.description,
    'dateKey': t.dateKey,
    'priorityIndex': t.priorityIndex,
    'isCompleted': t.isCompleted,
    'createdAt': t.createdAt.toIso8601String(),
    'completedAt': t.completedAt?.toIso8601String(),
    'linkedBlockId': t.linkedBlockId,
  };

  TaskModel _taskFromJson(Map<String, dynamic> j) => TaskModel(
    id: j['id'] as String,
    title: j['title'] as String,
    description: j['description'] as String?,
    dateKey: j['dateKey'] as String,
    priorityIndex: j['priorityIndex'] as int,
    isCompleted: j['isCompleted'] as bool,
    createdAt: DateTime.parse(j['createdAt'] as String),
    completedAt: j['completedAt'] != null ? DateTime.parse(j['completedAt'] as String) : null,
    linkedBlockId: j['linkedBlockId'] as String?,
  );

  Map<String, dynamic> _statsToJson(DailyStatsModel s) => {
    'dateKey': s.dateKey,
    'studyMinutes': s.studyMinutes,
    'revisionMinutes': s.revisionMinutes,
    'sleepMinutes': s.sleepMinutes,
    'wastedMinutes': s.wastedMinutes,
    'exerciseMinutes': s.exerciseMinutes,
    'coachingMinutes': s.coachingMinutes,
    'breakMinutes': s.breakMinutes,
    'mealMinutes': s.mealMinutes,
    'schoolMinutes': s.schoolMinutes,
    'personalWorkMinutes': s.personalWorkMinutes,
    'otherMinutes': s.otherMinutes,
    'updatedAt': s.updatedAt.toIso8601String(),
  };

  DailyStatsModel _statsFromJson(Map<String, dynamic> j) => DailyStatsModel(
    dateKey: j['dateKey'] as String,
    studyMinutes: j['studyMinutes'] as int? ?? 0,
    revisionMinutes: j['revisionMinutes'] as int? ?? 0,
    sleepMinutes: j['sleepMinutes'] as int? ?? 0,
    wastedMinutes: j['wastedMinutes'] as int? ?? 0,
    exerciseMinutes: j['exerciseMinutes'] as int? ?? 0,
    coachingMinutes: j['coachingMinutes'] as int? ?? 0,
    breakMinutes: j['breakMinutes'] as int? ?? 0,
    mealMinutes: j['mealMinutes'] as int? ?? 0,
    schoolMinutes: j['schoolMinutes'] as int? ?? 0,
    personalWorkMinutes: j['personalWorkMinutes'] as int? ?? 0,
    otherMinutes: j['otherMinutes'] as int? ?? 0,
    updatedAt: DateTime.parse(j['updatedAt'] as String),
  );

  Map<String, dynamic> _noteToJson(NoteModel n) => {
    'id': n.id,
    'dateKey': n.dateKey,
    'content': n.content,
    'createdAt': n.createdAt.toIso8601String(),
    'updatedAt': n.updatedAt.toIso8601String(),
  };

  NoteModel _noteFromJson(Map<String, dynamic> j) => NoteModel(
    id: j['id'] as String,
    dateKey: j['dateKey'] as String,
    content: j['content'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    updatedAt: DateTime.parse(j['updatedAt'] as String),
  );
}
