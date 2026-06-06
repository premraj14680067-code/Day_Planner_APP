// lib/features/analytics/data/models/daily_stats_model.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_stats_model.dart';

class DailyStatsModelAdapter extends TypeAdapter<DailyStatsModel> {
  @override
  final int typeId = 2;

  @override
  DailyStatsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyStatsModel(
      dateKey: fields[0] as String,
      studyMinutes: fields[1] as int,
      revisionMinutes: fields[2] as int,
      sleepMinutes: fields[3] as int,
      wastedMinutes: fields[4] as int,
      exerciseMinutes: fields[5] as int,
      coachingMinutes: fields[6] as int,
      breakMinutes: fields[7] as int,
      mealMinutes: fields[8] as int,
      schoolMinutes: fields[9] as int,
      personalWorkMinutes: fields[10] as int,
      otherMinutes: fields[11] as int,
      updatedAt: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DailyStatsModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.dateKey)
      ..writeByte(1)
      ..write(obj.studyMinutes)
      ..writeByte(2)
      ..write(obj.revisionMinutes)
      ..writeByte(3)
      ..write(obj.sleepMinutes)
      ..writeByte(4)
      ..write(obj.wastedMinutes)
      ..writeByte(5)
      ..write(obj.exerciseMinutes)
      ..writeByte(6)
      ..write(obj.coachingMinutes)
      ..writeByte(7)
      ..write(obj.breakMinutes)
      ..writeByte(8)
      ..write(obj.mealMinutes)
      ..writeByte(9)
      ..write(obj.schoolMinutes)
      ..writeByte(10)
      ..write(obj.personalWorkMinutes)
      ..writeByte(11)
      ..write(obj.otherMinutes)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyStatsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
