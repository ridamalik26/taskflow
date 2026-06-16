import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Use case: flip the completion state of a task and persist the result.
class ToggleTaskCompletion {
  const ToggleTaskCompletion(this._repository);

  final TaskRepository _repository;

  Future<void> call(Task task) => _repository.updateTask(task.toggleCompleted());
}
