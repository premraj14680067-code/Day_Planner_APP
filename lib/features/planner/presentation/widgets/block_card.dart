// lib/features/planner/presentation/widgets/block_card.dart

import 'package:flutter/material.dart';
import 'package:daypilot/core/constants/app_constants.dart';
import 'package:daypilot/core/utils/date_utils.dart';
import 'package:daypilot/features/planner/data/models/planner_block_model.dart';

class BlockCard extends StatelessWidget {
  final PlannerBlockModel block;
  final Color color;
  final VoidCallback onTap;

  const BlockCard({
    super.key,
    required this.block,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final height = (block.endMinutes - block.startMinutes) *
        AppConstants.hourHeightPx / 60;
    final isCompact = height < 36;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: color, width: 3),
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: isCompact ? 2 : 6,
        ),
        child: isCompact
            ? _CompactBlockContent(block: block, color: color)
            : _FullBlockContent(block: block, color: color),
      ),
    );
  }
}

class _CompactBlockContent extends StatelessWidget {
  final PlannerBlockModel block;
  final Color color;

  const _CompactBlockContent({required this.block, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          block.category.emoji,
          style: const TextStyle(fontSize: 10),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            block.title ?? block.category.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _FullBlockContent extends StatelessWidget {
  final PlannerBlockModel block;
  final Color color;

  const _FullBlockContent({required this.block, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(block.category.emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                block.title ?? block.category.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${block.startTimeLabel} – ${block.endTimeLabel}',
          style: TextStyle(
            fontSize: 10,
            color: color.withOpacity(0.75),
          ),
        ),
        if (block.notes != null && block.notes!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            block.notes!,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ],
    );
  }
}
