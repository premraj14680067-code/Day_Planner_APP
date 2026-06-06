# DayPilot — Personal Planning & Productivity App

A beautiful, fully offline Flutter app for planning every hour of your day, tracking time, managing tasks, and reviewing monthly analytics.

---

## Features

- **Calendar** — Monthly view with activity dots, year/month pickers (2020–2035), today highlight
- **Daily Planner** — Hour-by-hour timeline from 5 AM to midnight, tap to create blocks, color-coded categories
- **11 Block Categories** — Study, Revision, Coaching, School, Exercise, Sleep, Break, Meal, Wasted Time, Personal Work, Other
- **Task Manager** — Today / Overdue / Upcoming / Completed tabs, priority levels, swipe to delete
- **Analytics Dashboard** — Study hours wave chart, sleep bar chart, wasted time chart, revision chart, category pie chart, best/worst day, streak, consistency score
- **Daily Notes** — Freeform notes linked to each date
- **Settings** — Light/dark theme, category color customization, export/import JSON backup, full data reset

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Local Database | Hive |
| Charts | fl_chart |
| Notifications | flutter_local_notifications |
| Architecture | Clean Architecture + MVVM |

---

## Project Structure

```
lib/
├── main.dart
├── app_shell.dart
├── core/
│   ├── constants/app_constants.dart   # Enums, constants
│   ├── theme/app_theme.dart           # Light + dark themes
│   ├── utils/date_utils.dart          # Date helpers
│   ├── providers/providers.dart       # All Riverpod providers
│   └── services/
│       ├── export_import_service.dart
│       └── notification_service.dart
└── features/
    ├── calendar/presentation/screens/calendar_screen.dart
    ├── planner/
    │   ├── data/models/planner_block_model.dart
    │   ├── data/repositories/planner_repository.dart
    │   └── presentation/
    │       ├── screens/planner_screen.dart
    │       └── widgets/
    │           ├── block_card.dart
    │           └── add_block_sheet.dart
    ├── tasks/
    │   ├── data/models/task_model.dart
    │   ├── data/repositories/task_repository.dart
    │   └── presentation/
    │       ├── screens/tasks_screen.dart
    │       └── widgets/
    │           ├── task_item.dart
    │           ├── add_task_sheet.dart
    │           └── day_tasks_widget.dart
    ├── analytics/
    │   ├── data/models/daily_stats_model.dart
    │   ├── data/repositories/analytics_repository.dart
    │   └── presentation/screens/analytics_screen.dart
    ├── notes/
    │   ├── data/models/note_model.dart
    │   ├── data/repositories/notes_repository.dart
    │   └── presentation/widgets/daily_note_widget.dart
    └── settings/
        ├── data/models/user_settings_model.dart
        ├── data/repositories/settings_repository.dart
        └── presentation/
            ├── screens/settings_screen.dart
            └── widgets/category_color_sheet.dart
```

---

## Setup Instructions

### Prerequisites
- Flutter SDK ≥ 3.3.0
- Dart SDK ≥ 3.3.0
- Android Studio or VS Code with Flutter extension
- Android device / emulator (API 21+)

### Step 1 — Clone and install dependencies

```bash
cd daypilot
flutter pub get
```

### Step 2 — Generate Hive adapters

The `.g.dart` adapter files are **already included** in this project (pre-generated). If you ever change the Hive models, regenerate with:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 3 — Run the app

```bash
# Debug mode
flutter run

# Release APK
flutter build apk --release

# Release App Bundle (for Play Store)
flutter build appbundle --release
```

### Step 4 — Run on a physical device

```bash
flutter devices          # list connected devices
flutter run -d <device>  # run on specific device
```

---

## Hive Database Design

| Box | Model | Type ID | Key |
|---|---|---|---|
| `planner_block_box` | PlannerBlockModel | 0 | block.id (UUID) |
| `task_box` | TaskModel | 1 | task.id (UUID) |
| `daily_stats_box` | DailyStatsModel | 2 | dateKey (yyyy-MM-dd) |
| `notes_box` | NoteModel | 3 | dateKey (yyyy-MM-dd) |
| `settings_box` | UserSettingsModel | 4 | 'user_settings' |

---

## Key Design Decisions

**Date Keys** — All date-based records use `yyyy-MM-dd` string keys for fast prefix-based queries and human-readable storage.

**Analytics Auto-Compute** — Stats are recomputed from planner blocks every time a block is added, edited, or deleted. This ensures perfect accuracy.

**Overlap Detection** — The planner prevents overlapping blocks on the same date. A validation check runs before save.

**Offline-First** — Zero network calls. All data lives in Hive boxes on the device.

**Category Colors** — Default colors are baked into each `BlockCategory`. Users can override any color in Settings; custom colors are stored in `UserSettingsModel.categoryColors`.

---

## Customization

### Change supported year range
Edit `AppConstants.minYear` and `AppConstants.maxYear` in `lib/core/constants/app_constants.dart`.

### Change timeline hours
Edit `AppConstants.plannerStartHour` (default: 5) and `AppConstants.plannerEndHour` (default: 24).

### Add a new block category
1. Add entry to `BlockCategory` enum in `app_constants.dart`
2. Add `label`, `defaultColor`, and `emoji` cases to the extensions
3. Add handling in `AnalyticsRepository.computeAndSaveStats`
4. Add a field in `DailyStatsModel` and regenerate adapters

---

## Build & Release

### Generate a release APK

```bash
flutter build apk --release --split-per-abi
```

Output: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

### Sign the APK (for distribution)

1. Create keystore: `keytool -genkey -v -keystore daypilot.jks -keyalg RSA -keysize 2048 -validity 10000 -alias daypilot`
2. Create `android/key.properties` with your keystore details
3. Update `android/app/build.gradle` signingConfigs
4. Run `flutter build apk --release`

---

## License

MIT License — free to use, modify, and distribute.
