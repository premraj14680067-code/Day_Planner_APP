// lib/features/planner/data/models/planner_block_model.dart

import 'package:hive/hive.dart';
import 'package:daypilot/core/constants/app_constants.dart';

part 'planner_block_model.g.dart';

@HiveType(typeId: 0)
class PlannerBlockModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String dateKey; // 'yyyy-MM-dd'
  @HiveField(2) int categoryIndex; // BlockCategory.index
  @HiveField(3) int startMinutes; // minutes from midnight
  @HiveField(4) int endMinutes;   // minutes from midnight
  @HiveField(5) String? notes;
  @HiveField(6) int? actualDurationMinutes;
  @HiveField(7) String? title;
  @HiveField(8) DateTime createdAt;
  @HiveField(9) DateTime updatedAt;

  PlannerBlockModel({
    required this.id,
    required this.dateKey,
    required this.categoryIndex,
    required this.startMinutes,
    required this.endMinutes,
    this.notes,
    this.actualDurationMinutes,
    this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  BlockCategory get category => BlockCategory.values[categoryIndex];

  int get plannedDurationMinutes => endMinutes - startMinutes;

  String get startTimeLabel {
    final h = startMinutes ~/ 60;
    final m = startMinutes % 60;
    final period = h < 12 ? 'AM' : 'PM';
    final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${displayH.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
  }

  String get endTimeLabel {
    final h = endMinutes ~/ 60;
    final m = endMinutes % 60;
    final period = h < 12 ? 'AM' : 'PM';
    final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${displayH.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
  }

  PlannerBlockModel copyWith({
    String? id,
    String? dateKey,
    int? categoryIndex,
    int? startMinutes,
    int? endMinutes,
    String? notes,
    int? actualDurationMinutes,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlannerBlockModel(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      categoryIndex: categoryIndex ?? this.categoryIndex,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      notes: notes ?? this.notes,
      actualDurationMinutes: actualDurationMinutes ?? this.actualDurationMinutes,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
