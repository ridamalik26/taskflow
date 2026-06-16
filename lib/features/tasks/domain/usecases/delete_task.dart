import '../repositories/task_repository.dart';

/// Use case: delete a task by id.
class DeleteTask {
  const DeleteTask(this._repository);

  final TaskRepository _repository;

  Future<void> call(String id) => _repository.deleteTask(id);
}
