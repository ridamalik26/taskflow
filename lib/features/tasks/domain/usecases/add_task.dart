import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Use case: create a new task.
class AddTask {
  const AddTask(this._repository);

  final TaskRepository _repository;

  Future<void> call(Task task) => _repository.addTask(task);
}
