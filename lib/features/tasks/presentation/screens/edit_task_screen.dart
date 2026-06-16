import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/task.dart';
import '../providers/task_providers.dart';
import '../widgets/task_form.dart';

/// Screen for editing an existing task, identified by [taskId].
class EditTaskScreen extends ConsumerWidget {
  const EditTaskScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Task? task = ref.watch(taskByIdProvider(taskId));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Task')),
      body: SafeArea(
        child: task == null
            ? EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Task not found',
                message: 'This task may have been deleted.',
                actionLabel: 'Go back',
                onAction: () => context.pop(),
              )
            : TaskForm(existing: task),
      ),
    );
  }
}
