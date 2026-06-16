import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/task.dart';
import 'task_providers.dart';

/// Owns the canonical list of tasks and exposes CRUD operations.
///
/// All mutations write through to the repository and then refresh local state,
/// applying optimistic updates so the UI feels instant.
class TaskListNotifier extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() async {
    return ref.watch(getTasksProvider).call();
  }

  /// Re-reads tasks from storage (used by pull-to-refresh).
  Future<void> refresh() async {
    state = const AsyncLoading<List<Task>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => ref.read(getTasksProvider).call());
  }

  /// Adds a new task and prepends it to the in-memory list.
  Future<void> add(Task task) async {
    await ref.read(addTaskProvider).call(task);
    final List<Task> current = state.valueOrNull ?? <Task>[];
    state = AsyncData<List<Task>>(<Task>[task, ...current]);
  }

  /// Updates an existing task in place.
  Future<void> updateTask(Task task) async {
    await ref.read(updateTaskProvider).call(task);
    final List<Task> current = state.valueOrNull ?? <Task>[];
    state = AsyncData<List<Task>>(
      current.map((Task t) => t.id == task.id ? task : t).toList(),
    );
  }

  /// Deletes a task by id.
  Future<void> remove(String id) async {
    await ref.read(deleteTaskProvider).call(id);
    final List<Task> current = state.valueOrNull ?? <Task>[];
    state = AsyncData<List<Task>>(
      current.where((Task t) => t.id != id).toList(),
    );
  }

  /// Toggles the completion state of a task and persists it.
  Future<void> toggle(Task task) async {
    final Task updated = task.toggleCompleted();
    await ref.read(toggleTaskProvider).call(task);
    final List<Task> current = state.valueOrNull ?? <Task>[];
    state = AsyncData<List<Task>>(
      current.map((Task t) => t.id == updated.id ? updated : t).toList(),
    );
  }
}
