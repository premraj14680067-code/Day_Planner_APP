// lib/features/planner/data/models/planner_block_model.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build

part of 'planner_block_model.dart';

class PlannerBlockModelAdapter extends TypeAdapter<PlannerBlockModel> {
  @override
  final int typeId = 0;

  @override
  PlannerBlockModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlannerBlockModel(
      id: fields[0] as String,
      dateKey: fields[1] as String,
      categoryIndex: fields[2] as int,
      startMinutes: fields[3] as int,
      endMinutes: fields[4] as int,
      notes: fields[5] as String?,
      actualDurationMinutes: fields[6] as int?,
      title: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PlannerBlockModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dateKey)
      ..writeByte(2)
      ..write(obj.categoryIndex)
      ..writeByte(3)
      ..write(obj.startMinutes)
      ..writeByte(4)
      ..write(obj.endMinutes)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.actualDurationMinutes)
      ..writeByte(7)
      ..write(obj.title)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlannerBlockModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
