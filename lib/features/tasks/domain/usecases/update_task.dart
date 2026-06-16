import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Use case: update an existing task.
class UpdateTask {
  const UpdateTask(this._repository);

  final TaskRepository _repository;

  Future<void> call(Task task) => _repository.updateTask(task);
}
