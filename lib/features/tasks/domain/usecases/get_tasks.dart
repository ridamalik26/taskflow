import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Use case: retrieve all tasks.
class GetTasks {
  const GetTasks(this._repository);

  final TaskRepository _repository;

  Future<List<Task>> call() => _repository.getTasks();
}
