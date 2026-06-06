// lib/features/settings/data/models/user_settings_model.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings_model.dart';

class UserSettingsModelAdapter extends TypeAdapter<UserSettingsModel> {
  @override
  final int typeId = 4;

  @override
  UserSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettingsModel(
      isDarkMode: fields[0] as bool,
      lastViewedYear: fields[1] as int,
      lastViewedMonth: fields[2] as int,
      notificationsEnabled: fields[3] as bool,
      categoryColors: (fields[4] as Map).cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserSettingsModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.isDarkMode)
      ..writeByte(1)
      ..write(obj.lastViewedYear)
      ..writeByte(2)
      ..write(obj.lastViewedMonth)
      ..writeByte(3)
      ..write(obj.notificationsEnabled)
      ..writeByte(4)
      ..write(obj.categoryColors);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
