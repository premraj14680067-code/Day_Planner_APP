// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:daypilot/core/constants/app_constants.dart';
import 'package:daypilot/core/theme/app_theme.dart';
import 'package:daypilot/core/providers/providers.dart';
import 'package:daypilot/features/planner/data/models/planner_block_model.dart';
import 'package:daypilot/features/tasks/data/models/task_model.dart';
import 'package:daypilot/features/analytics/data/models/daily_stats_model.dart';
import 'package:daypilot/features/notes/data/models/note_model.dart';
import 'package:daypilot/features/settings/data/models/user_settings_model.dart';
import 'package:daypilot/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(PlannerBlockModelAdapter());
  Hive.registerAdapter(TaskModelAdapter());
  Hive.registerAdapter(DailyStatsModelAdapter());
  Hive.registerAdapter(NoteModelAdapter());
  Hive.registerAdapter(UserSettingsModelAdapter());

  // Open boxes
  await Hive.openBox<PlannerBlockModel>(AppConstants.plannerBlockBox);
  await Hive.openBox<TaskModel>(AppConstants.taskBox);
  await Hive.openBox<DailyStatsModel>(AppConstants.dailyStatsBox);
  await Hive.openBox<NoteModel>(AppConstants.notesBox);
  await Hive.openBox<UserSettingsModel>(AppConstants.settingsBox);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: DayPilotApp()));
}

class DayPilotApp extends ConsumerWidget {
  const DayPilotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const AppShell(),
    );
  }
}
