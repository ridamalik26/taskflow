import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../domain/entities/task.dart';
import 'priority_badge.dart';

/// A card representing a single task in the list.
///
/// Includes an animated completion checkbox, priority badge and due-date chip.
/// Swipe-to-edit / swipe-to-delete are handled by the parent [Dismissible].
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
  });

  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Color priority = priorityColor(task.priority);
    final bool overdue =
        !task.isCompleted && AppDateUtils.isOverdue(task.dueDate);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Colored priority indicator bar.
              Container(
                width: 4,
                height: 44,
                margin: const EdgeInsets.only(right: AppConstants.spacingMd),
                decoration: BoxDecoration(
                  color: priority,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Hero(
                      tag: 'task-title-${task.id}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: AnimatedDefaultTextStyle(
                          duration: AppConstants.shortAnimation,
                          style: (text.titleMedium ?? const TextStyle()).copyWith(
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isCompleted
                                ? AppColors.textSecondary
                                : text.titleMedium?.color,
                          ),
                          child: Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    if (task.description.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        task.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                    ],
                    const SizedBox(height: AppConstants.spacingSm),
                    Wrap(
                      spacing: AppConstants.spacingSm,
                      runSpacing: AppConstants.spacingXs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        PriorityBadge(priority: task.priority, compact: true),
                        _DueChip(dueDate: task.dueDate, overdue: overdue),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              _CompletionCheckbox(
                isCompleted: task.isCompleted,
                onToggle: onToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An animated circular checkbox used to mark a task complete.
class _CompletionCheckbox extends StatelessWidget {
  const _CompletionCheckbox({required this.isCompleted, required this.onToggle});

  final bool isCompleted;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppConstants.shortAnimation,
        curve: Curves.easeOut,
        height: 28,
        width: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted ? AppColors.success : Colors.transparent,
          border: Border.all(
            color: isCompleted ? AppColors.success : AppColors.textSecondary,
            width: 2,
          ),
        ),
        child: AnimatedScale(
          scale: isCompleted ? 1 : 0,
          duration: AppConstants.shortAnimation,
          curve: Curves.elasticOut,
          child: const Icon(Icons.check, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

/// A small chip showing the due-date label, highlighted red when overdue.
class _DueChip extends StatelessWidget {
  const _DueChip({required this.dueDate, required this.overdue});

  final DateTime dueDate;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final Color color = overdue ? AppColors.error : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          overdue ? Icons.warning_amber_rounded : Icons.calendar_today_rounded,
          size: 13,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          AppDateUtils.dueLabel(dueDate),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: overdue ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
