import '../entities/task.dart';

/// Contract describing how the rest of the app interacts with task storage.
///
/// The presentation layer depends only on this abstraction (Dependency
/// Inversion), so the underlying data source can be swapped freely.
abstract interface class TaskRepository {
  /// Returns all persisted tasks.
  Future<List<Task>> getTasks();

  /// Persists a brand new task.
  Future<void> addTask(Task task);

  /// Updates an existing task (matched by id).
  Future<void> updateTask(Task task);

  /// Removes a task by its id.
  Future<void> deleteTask(String id);

  /// Fetches a single task by id, or throws if not found.
  Future<Task> getTaskById(String id);
}
