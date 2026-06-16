import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_datasource.dart';
import '../models/task_model.dart';

/// Concrete [TaskRepository] backed by a [TaskLocalDataSource].
///
/// Responsible for mapping between domain entities and data models so neither
/// side leaks into the other.
class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._dataSource);

  final TaskLocalDataSource _dataSource;

  @override
  Future<List<Task>> getTasks() async {
    final List<TaskModel> models = _dataSource.getTasks();
    return models.map((TaskModel m) => m.toEntity()).toList();
  }

  @override
  Future<void> addTask(Task task) {
    return _dataSource.addTask(TaskModel.fromEntity(task));
  }

  @override
  Future<void> updateTask(Task task) {
    return _dataSource.updateTask(TaskModel.fromEntity(task));
  }

  @override
  Future<void> deleteTask(String id) {
    return _dataSource.deleteTask(id);
  }

  @override
  Future<Task> getTaskById(String id) async {
    return _dataSource.getTaskById(id).toEntity();
  }
}
