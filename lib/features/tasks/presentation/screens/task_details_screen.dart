import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/entities/task.dart';
import '../providers/task_providers.dart';
import '../widgets/priority_badge.dart';

/// Read-only detail view for a single task with edit/delete/complete actions.
class TaskDetailsScreen extends ConsumerWidget {
  const TaskDetailsScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Task? task = ref.watch(taskByIdProvider(taskId));

    if (task == null) {
      return Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Task not found',
            message: 'This task may have been deleted.',
            actionLabel: 'Back to home',
            onAction: () => context.go(AppRoutes.home),
          ),
        ),
      );
    }

    final bool overdue =
        !task.isCompleted && AppDateUtils.isOverdue(task.dueDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.push('${AppRoutes.editTask}/${task.id}'),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _confirmDelete(context, ref, task),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          children: <Widget>[
            // Status banner.
            _StatusBanner(isCompleted: task.isCompleted, overdue: overdue),
            const SizedBox(height: AppConstants.spacingLg),

            // Title (hero shared with the list tile).
            Hero(
              tag: 'task-title-${task.id}',
              child: Material(
                type: MaterialType.transparency,
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 26,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            PriorityBadge(priority: task.priority),
            const SizedBox(height: AppConstants.spacingLg),

            // Description.
            _SectionCard(
              title: 'Description',
              icon: Icons.notes_rounded,
              child: Text(
                task.description.trim().isEmpty
                    ? 'No description provided.'
                    : task.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),

            // Meta info.
            _SectionCard(
              title: 'Details',
              icon: Icons.info_outline_rounded,
              child: Column(
                children: <Widget>[
                  _InfoRow(
                    icon: Icons.event_rounded,
                    label: 'Due Date',
                    value: AppDateUtils.fullDate(task.dueDate),
                    valueColor: overdue ? AppColors.error : null,
                  ),
                  const Divider(height: AppConstants.spacingLg),
                  _InfoRow(
                    icon: Icons.flag_rounded,
                    label: 'Priority',
                    value: task.priority.label,
                    valueColor: priorityColor(task.priority),
                  ),
                  const Divider(height: AppConstants.spacingLg),
                  _InfoRow(
                    icon: task.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.pending_actions_rounded,
                    label: 'Status',
                    value: task.isCompleted ? 'Completed' : 'Pending',
                    valueColor:
                        task.isCompleted ? AppColors.success : AppColors.warning,
                  ),
                  const Divider(height: AppConstants.spacingLg),
                  _InfoRow(
                    icon: Icons.schedule_rounded,
                    label: 'Created',
                    value: AppDateUtils.fullDate(task.createdAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingXl),

            // Primary action: toggle completion.
            CustomButton(
              label:
                  task.isCompleted ? 'Mark as Pending' : 'Mark as Completed',
              icon: task.isCompleted
                  ? Icons.replay_rounded
                  : Icons.check_circle_rounded,
              color: task.isCompleted ? AppColors.warning : AppColors.success,
              onPressed: () async {
                await ref.read(taskListProvider.notifier).toggle(task);
                if (context.mounted) {
                  AppSnackbar.success(
                    context,
                    task.isCompleted
                        ? 'Marked as pending'
                        : 'Great job! Task completed 🎉',
                  );
                }
              },
            ),
            const SizedBox(height: AppConstants.spacingSm),
            CustomButton(
              label: 'Edit Task',
              icon: Icons.edit_rounded,
              isOutlined: true,
              onPressed: () => context.push('${AppRoutes.editTask}/${task.id}'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final bool confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete task?',
      message: 'Are you sure you want to delete "${task.title}"? '
          'This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed) return;
    await ref.read(taskListProvider.notifier).remove(task.id);
    if (context.mounted) {
      AppSnackbar.info(context, 'Task deleted');
      context.go(AppRoutes.home);
    }
  }
}

/// A colored banner summarizing the task's status.
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.isCompleted, required this.overdue});

  final bool isCompleted;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final Color color = isCompleted
        ? AppColors.success
        : overdue
            ? AppColors.error
            : AppColors.secondary;
    final IconData icon = isCompleted
        ? Icons.check_circle_rounded
        : overdue
            ? Icons.warning_amber_rounded
            : Icons.timelapse_rounded;
    final String label = isCompleted
        ? 'This task is completed'
        : overdue
            ? 'This task is overdue'
            : 'This task is in progress';

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// A titled card section used to group detail content.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: AppConstants.spacingSm),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),
          child,
        ],
      ),
    );
  }
}

/// A single labelled detail row.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppConstants.spacingMd),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
          ),
        ),
      ],
    );
  }
}
