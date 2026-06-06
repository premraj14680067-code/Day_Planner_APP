// lib/features/planner/data/repositories/planner_repository.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'package:daypilot/core/constants/app_constants.dart';
import 'package:daypilot/features/planner/data/models/planner_block_model.dart';

abstract class IPlannerRepository {
  List<PlannerBlockModel> getBlocksForDate(String dateKey);
  Future<void> saveBlock(PlannerBlockModel block);
  Future<void> updateBlock(PlannerBlockModel block);
  Future<void> deleteBlock(String blockId);
  List<String> getDatesWithBlocks(int year, int month);
  Future<void> deleteAllBlocks();
  List<PlannerBlockModel> getAllBlocks();
}

class PlannerRepository implements IPlannerRepository {
  Box<PlannerBlockModel> get _box =>
      Hive.box<PlannerBlockModel>(AppConstants.plannerBlockBox);

  @override
  List<PlannerBlockModel> getBlocksForDate(String dateKey) {
    return _box.values
        .where((b) => b.dateKey == dateKey)
        .toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
  }

  @override
  Future<void> saveBlock(PlannerBlockModel block) async {
    await _box.put(block.id, block);
  }

  @override
  Future<void> updateBlock(PlannerBlockModel block) async {
    final updated = block.copyWith(updatedAt: DateTime.now());
    await _box.put(updated.id, updated);
  }

  @override
  Future<void> deleteBlock(String blockId) async {
    await _box.delete(blockId);
  }

  @override
  List<String> getDatesWithBlocks(int year, int month) {
    final monthStr = month.toString().padLeft(2, '0');
    final prefix = '$year-$monthStr-';
    final dateKeys = _box.values
        .where((b) => b.dateKey.startsWith(prefix))
        .map((b) => b.dateKey)
        .toSet()
        .toList();
    return dateKeys;
  }

  @override
  Future<void> deleteAllBlocks() async {
    await _box.clear();
  }

  @override
  List<PlannerBlockModel> getAllBlocks() {
    return _box.values.toList();
  }

  /// Check for overlapping blocks on a given date (excluding a block by id)
  bool hasOverlap(String dateKey, int startMins, int endMins, {String? excludeId}) {
    final blocks = getBlocksForDate(dateKey)
        .where((b) => b.id != excludeId)
        .toList();
    for (final b in blocks) {
      if (startMins < b.endMinutes && endMins > b.startMinutes) {
        return true;
      }
    }
    return false;
  }
}
