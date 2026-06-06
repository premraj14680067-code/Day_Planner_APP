// lib/features/settings/presentation/widgets/category_color_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daypilot/core/constants/app_constants.dart';
import 'package:daypilot/core/providers/providers.dart';
import 'package:daypilot/core/theme/app_theme.dart';

class CategoryColorSheet extends ConsumerStatefulWidget {
  const CategoryColorSheet({super.key});

  @override
  ConsumerState<CategoryColorSheet> createState() => _CategoryColorSheetState();
}

class _CategoryColorSheetState extends ConsumerState<CategoryColorSheet> {
  // Preset colors to choose from
  static const List<Color> _presets = [
    Color(0xFF4F8EF7), Color(0xFF9C6FE0), Color(0xFF5BC4A0),
    Color(0xFF38B2AC), Color(0xFFF6AD55), Color(0xFF76A9FA),
    Color(0xFFA0AEC0), Color(0xFF68D391), Color(0xFFFC8181),
    Color(0xFFED8936), Color(0xFFCBD5E0), Color(0xFFE53E3E),
    Color(0xFF2B6CB0), Color(0xFF276749), Color(0xFF744210),
    Color(0xFF702459), Color(0xFF1A365D), Color(0xFF22543D),
    Color(0xFFF687B3), Color(0xFF81E6D9), Color(0xFFFED7AA),
    Color(0xFFC6F6D5),
  ];

  BlockCategory? _expandedCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle + title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Category Colors', style: theme.textTheme.headlineSmall),
                    const Spacer(),
                    TextButton(
                      onPressed: _resetToDefaults,
                      child: const Text('Reset to defaults'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: BlockCategory.values.length,
              itemBuilder: (context, index) {
                final category = BlockCategory.values[index];
                final currentColor = ref.watch(categoryColorProvider(category));
                final isExpanded = _expandedCategory == category;

                return Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() {
                        _expandedCategory = isExpanded ? null : category;
                      }),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        child: Row(
                          children: [
                            Text(category.emoji, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(category.label, style: theme.textTheme.titleMedium),
                            ),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: currentColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.outline.withOpacity(0.3),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _presets.map((color) {
                            final isSelected = color.value == currentColor.value;
                            return GestureDetector(
                              onTap: () async {
                                await ref.read(settingsProvider.notifier)
                                    .updateCategoryColor(category.index, color.value);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: isSelected
                                      ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    if (index < BlockCategory.values.length - 1)
                      Divider(
                        height: 1,
                        color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder)
                            .withOpacity(0.5),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetToDefaults() async {
    for (final cat in BlockCategory.values) {
      await ref.read(settingsProvider.notifier)
          .updateCategoryColor(cat.index, cat.defaultColor.value);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Colors reset to defaults')),
      );
    }
  }
}
