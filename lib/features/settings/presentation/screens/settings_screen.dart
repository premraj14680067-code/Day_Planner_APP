// lib/features/settings/presentation/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypilot/core/constants/app_constants.dart';
import 'package:daypilot/core/providers/providers.dart';
import 'package:daypilot/core/theme/app_theme.dart';
import 'package:daypilot/features/settings/presentation/widgets/category_color_sheet.dart';
import 'package:daypilot/core/services/export_import_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Appearance ────────────────────────────────────────────────────
          _SectionHeader(title: 'Appearance'),
          _SettingsCard(children: [
            SwitchListTile(
              value: settings.isDarkMode,
              onChanged: (v) => ref.read(settingsProvider.notifier).setTheme(v),
              title: const Text('Dark Mode'),
              subtitle: const Text('Switch between light and dark theme'),
              secondary: Icon(
                settings.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                color: AppTheme.primaryBlue,
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Categories ────────────────────────────────────────────────────
          _SectionHeader(title: 'Categories'),
          _SettingsCard(children: [
            ListTile(
              leading: const Icon(Icons.palette_outlined, color: AppTheme.accentPurple),
              title: const Text('Customize Category Colors'),
              subtitle: const Text('Change colors for each block type'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const CategoryColorSheet(),
              ),
            ),
            Divider(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: BlockCategory.values.map((cat) {
                  final color = ref.watch(categoryColorProvider(cat));
                  return Chip(
                    avatar: CircleAvatar(backgroundColor: color, radius: 8),
                    label: Text(cat.label, style: const TextStyle(fontSize: 11)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Notifications ─────────────────────────────────────────────────
          _SectionHeader(title: 'Notifications'),
          _SettingsCard(children: [
            SwitchListTile(
              value: settings.notificationsEnabled,
              onChanged: (v) => ref.read(settingsProvider.notifier).toggleNotifications(),
              title: const Text('Enable Notifications'),
              subtitle: const Text('Block reminders and daily summaries'),
              secondary: const Icon(Icons.notifications_outlined, color: AppTheme.accentTeal),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Data ──────────────────────────────────────────────────────────
          _SectionHeader(title: 'Data'),
          _SettingsCard(children: [
            ListTile(
              leading: const Icon(Icons.upload_outlined, color: AppTheme.primaryBlue),
              title: const Text('Export Data'),
              subtitle: const Text('Save all data as JSON file'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _exportData(context, ref),
            ),
            Divider(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ListTile(
              leading: const Icon(Icons.download_outlined, color: AppTheme.accentPurple),
              title: const Text('Import Data'),
              subtitle: const Text('Restore from a JSON backup'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _importData(context, ref),
            ),
            Divider(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
              title: const Text('Reset All Data', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Permanently delete everything'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _confirmReset(context, ref),
            ),
          ]),
          const SizedBox(height: 16),

          // ── About ─────────────────────────────────────────────────────────
          _SectionHeader(title: 'About'),
          _SettingsCard(children: [
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppTheme.primaryBlue),
              title: const Text('DayPilot'),
              subtitle: Text('Version ${AppConstants.appVersion}'),
            ),
            Divider(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            const ListTile(
              leading: Icon(Icons.storage_outlined),
              title: Text('Storage'),
              subtitle: Text('All data stored locally on device. No internet required.'),
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final service = ExportImportService();
      final path = await service.exportData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported to: $path'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => service.shareExportedFile(path),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
            'This will merge imported data with your existing data. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Import')),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final service = ExportImportService();
      await service.importData();
      // Refresh all providers
      ref.invalidate(plannerRefreshProvider);
      ref.invalidate(taskRefreshProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data imported successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Data'),
        content: const Text(
            'This will permanently delete all your planner data, tasks, notes, and analytics. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(plannerRepositoryProvider).deleteAllBlocks();
    await ref.read(taskRepositoryProvider).deleteAllTasks();
    await ref.read(notesRepositoryProvider).deleteAllNotes();
    await ref.read(analyticsRepositoryProvider).deleteAllStats();

    ref.invalidate(plannerRefreshProvider);
    ref.invalidate(taskRefreshProvider);
    ref.invalidate(notesRefreshProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data has been deleted')),
      );
    }
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.2,
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
