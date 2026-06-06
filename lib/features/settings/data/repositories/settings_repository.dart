// lib/features/settings/data/repositories/settings_repository.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'package:daypilot/core/constants/app_constants.dart';
import 'package:daypilot/features/settings/data/models/user_settings_model.dart';

class SettingsRepository {
  static const String _settingsKey = 'user_settings';

  Box<UserSettingsModel> get _box =>
      Hive.box<UserSettingsModel>(AppConstants.settingsBox);

  UserSettingsModel getSettings() {
    return _box.get(_settingsKey) ??
        UserSettingsModel(
          lastViewedYear: DateTime.now().year,
          lastViewedMonth: DateTime.now().month,
        );
  }

  Future<void> saveSettings(UserSettingsModel settings) async {
    await _box.put(_settingsKey, settings);
  }

  Future<void> updateTheme(bool isDarkMode) async {
    final s = getSettings().copyWith(isDarkMode: isDarkMode);
    await saveSettings(s);
  }

  Future<void> updateLastViewed(int year, int month) async {
    final s = getSettings().copyWith(lastViewedYear: year, lastViewedMonth: month);
    await saveSettings(s);
  }

  Future<void> updateNotifications(bool enabled) async {
    final s = getSettings().copyWith(notificationsEnabled: enabled);
    await saveSettings(s);
  }

  Future<void> updateCategoryColor(int categoryIndex, int colorValue) async {
    final current = getSettings();
    final newColors = Map<String, int>.from(current.categoryColors);
    newColors['$categoryIndex'] = colorValue;
    final s = current.copyWith(categoryColors: newColors);
    await saveSettings(s);
  }
}
