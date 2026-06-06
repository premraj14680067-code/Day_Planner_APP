// lib/features/settings/data/models/user_settings_model.dart

import 'package:hive/hive.dart';

part 'user_settings_model.g.dart';

@HiveType(typeId: 4)
class UserSettingsModel extends HiveObject {
  @HiveField(0) bool isDarkMode;
  @HiveField(1) int lastViewedYear;
  @HiveField(2) int lastViewedMonth;
  @HiveField(3) bool notificationsEnabled;
  @HiveField(4) Map<String, int> categoryColors; // category.index -> color.value

  UserSettingsModel({
    this.isDarkMode = false,
    required this.lastViewedYear,
    required this.lastViewedMonth,
    this.notificationsEnabled = true,
    Map<String, int>? categoryColors,
  }) : categoryColors = categoryColors ?? {};

  UserSettingsModel copyWith({
    bool? isDarkMode,
    int? lastViewedYear,
    int? lastViewedMonth,
    bool? notificationsEnabled,
    Map<String, int>? categoryColors,
  }) {
    return UserSettingsModel(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      lastViewedYear: lastViewedYear ?? this.lastViewedYear,
      lastViewedMonth: lastViewedMonth ?? this.lastViewedMonth,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      categoryColors: categoryColors ?? Map.from(this.categoryColors),
    );
  }
}
