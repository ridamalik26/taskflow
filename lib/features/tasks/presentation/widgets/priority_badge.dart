import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/task_priority.dart';

/// Maps a [TaskPriority] to a presentation color.
Color priorityColor(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.low:
      return AppColors.success;
    case TaskPriority.medium:
      return AppColors.warning;
    case TaskPriority.high:
      return AppColors.error;
  }
}

/// A small pill that visually communicates a task's priority.
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority, this.compact = false});

  final TaskPriority priority;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color color = priorityColor(priority);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppConstants.spacingSm : AppConstants.spacingMd,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.flag_rounded, size: compact ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Text(
            priority.label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
