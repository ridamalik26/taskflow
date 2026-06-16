import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_exception.dart';
import '../models/task_model.dart';

/// Abstraction over the local persistence mechanism for tasks.
abstract interface class TaskLocalDataSource {
  List<TaskModel> getTasks();
  Future<void> addTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String id);
  TaskModel getTaskById(String id);
}

/// Hive-backed implementation of [TaskLocalDataSource].
///
/// Every Hive call is wrapped so low-level [HiveError]s are translated into the
/// app's own [CacheException], keeping framework details out of higher layers.
class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  TaskLocalDataSourceImpl(this._box);

  final Box<TaskModel> _box;

  @override
  List<TaskModel> getTasks() {
    try {
      return _box.values.toList(growable: false);
    } catch (e) {
      throw CacheException('Could not load tasks: $e');
    }
  }

  @override
  Future<void> addTask(TaskModel task) async {
    try {
      await _box.put(task.id, task);
    } catch (e) {
      throw CacheException('Could not save task: $e');
    }
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    try {
      if (!_box.containsKey(task.id)) {
        throw const NotFoundException();
      }
      await _box.put(task.id, task);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw CacheException('Could not update task: $e');
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw CacheException('Could not delete task: $e');
    }
  }

  @override
  TaskModel getTaskById(String id) {
    final TaskModel? model = _box.get(id);
    if (model == null) throw const NotFoundException();
    return model;
  }

  /// Opens (or returns the already-open) Hive box for tasks.
  static Future<Box<TaskModel>> openBox() async {
    try {
      if (Hive.isBoxOpen(AppConstants.taskBoxName)) {
        return Hive.box<TaskModel>(AppConstants.taskBoxName);
      }
      return await Hive.openBox<TaskModel>(AppConstants.taskBoxName);
    } catch (e) {
      throw CacheException('Could not open storage: $e');
    }
  }
}
