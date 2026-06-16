import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../data/datasources/task_local_datasource.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/usecases/add_task.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../domain/usecases/toggle_task_completion.dart';
import '../../domain/usecases/update_task.dart';
import 'task_list_notifier.dart';

/// The visibility filter applied to the task list.
enum TaskFilter {
  all('All'),
  pending('Pending'),
  completed('Completed');

  const TaskFilter(this.label);
  final String label;
}

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

/// Provides the already-opened Hive box.
///
/// Overridden in `main()` once the box has been opened asynchronously.
final taskBoxProvider = Provider<Box<TaskModel>>(
  (ref) => throw UnimplementedError('taskBoxProvider must be overridden'),
);

final taskLocalDataSourceProvider = Provider<TaskLocalDataSource>(
  (ref) => TaskLocalDataSourceImpl(ref.watch(taskBoxProvider)),
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepositoryImpl(ref.watch(taskLocalDataSourceProvider)),
);

// ---------------------------------------------------------------------------
// Use case providers
// ---------------------------------------------------------------------------

final getTasksProvider =
    Provider<GetTasks>((ref) => GetTasks(ref.watch(taskRepositoryProvider)));
final addTaskProvider =
    Provider<AddTask>((ref) => AddTask(ref.watch(taskRepositoryProvider)));
final updateTaskProvider =
    Provider<UpdateTask>((ref) => UpdateTask(ref.watch(taskRepositoryProvider)));
final deleteTaskProvider =
    Provider<DeleteTask>((ref) => DeleteTask(ref.watch(taskRepositoryProvider)));
final toggleTaskProvider = Provider<ToggleTaskCompletion>(
  (ref) => ToggleTaskCompletion(ref.watch(taskRepositoryProvider)),
);

// ---------------------------------------------------------------------------
// State providers
// ---------------------------------------------------------------------------

/// Holds the asynchronously-loaded list of all tasks and exposes CRUD ops.
final taskListProvider =
    AsyncNotifierProvider<TaskListNotifier, List<Task>>(TaskListNotifier.new);

/// Current active filter.
final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);

/// Current search query.
final taskSearchProvider = StateProvider<String>((ref) => '');

/// Derived list of tasks after applying [taskFilterProvider] and
/// [taskSearchProvider]. Sorted by completion, then priority, then due date.
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final List<Task> tasks =
      ref.watch(taskListProvider).valueOrNull ?? const <Task>[];
  final TaskFilter filter = ref.watch(taskFilterProvider);
  final String query = ref.watch(taskSearchProvider).trim().toLowerCase();

  Iterable<Task> result = tasks;

  switch (filter) {
    case TaskFilter.pending:
      result = result.where((Task t) => !t.isCompleted);
    case TaskFilter.completed:
      result = result.where((Task t) => t.isCompleted);
    case TaskFilter.all:
      break;
  }

  if (query.isNotEmpty) {
    result = result.where(
      (Task t) =>
          t.title.toLowerCase().contains(query) ||
          t.description.toLowerCase().contains(query),
    );
  }

  final List<Task> sorted = result.toList()
    ..sort((Task a, Task b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1; // incomplete first
      }
      final int byPriority = b.priority.value.compareTo(a.priority.value);
      if (byPriority != 0) return byPriority; // high priority first
      return a.dueDate.compareTo(b.dueDate); // soonest due first
    });

  return sorted;
});

/// Lightweight statistics derived from the full task list.
class TaskStats {
  const TaskStats({
    required this.total,
    required this.completed,
    required this.pending,
  });

  final int total;
  final int completed;
  final int pending;
}

final taskStatsProvider = Provider<TaskStats>((ref) {
  final List<Task> tasks =
      ref.watch(taskListProvider).valueOrNull ?? const <Task>[];
  final int completed = tasks.where((Task t) => t.isCompleted).length;
  return TaskStats(
    total: tasks.length,
    completed: completed,
    pending: tasks.length - completed,
  );
});

/// Looks up a single task by id from the loaded list (used by details screen).
final taskByIdProvider = Provider.family<Task?, String>((ref, String id) {
  final List<Task> tasks =
      ref.watch(taskListProvider).valueOrNull ?? const <Task>[];
  for (final Task t in tasks) {
    if (t.id == id) return t;
  }
  return null;
});
