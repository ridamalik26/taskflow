import 'package:hive/hive.dart';

import '../../domain/entities/task.dart';
import '../../domain/entities/task_priority.dart';

/// Hive-persistable data model for a [Task].
///
/// A hand-written [TypeAdapter] is used (see [TaskModelAdapter]) so the project
/// does not require a build_runner code-generation step.
class TaskModel {
  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.isCompleted,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime dueDate;

  /// Persisted priority as its integer value (see [TaskPriority.value]).
  final int priority;
  final bool isCompleted;
  final DateTime createdAt;

  /// Maps a pure domain [Task] into a storable model.
  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      priority: task.priority.value,
      isCompleted: task.isCompleted,
      createdAt: task.createdAt,
    );
  }

  /// Maps this storage model back into a domain [Task].
  Task toEntity() {
    return Task(
      id: id,
      title: title,
      description: description,
      dueDate: dueDate,
      priority: TaskPriority.fromValue(priority),
      isCompleted: isCompleted,
      createdAt: createdAt,
    );
  }
}

/// Manually implemented Hive adapter for [TaskModel].
///
/// Fields are written/read in a fixed order; never reorder them or existing
/// stored data will be corrupted.
class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 0;

  @override
  TaskModel read(BinaryReader reader) {
    final int fieldCount = reader.readByte();
    final Map<int, dynamic> fields = <int, dynamic>{
      for (int i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return TaskModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      dueDate: fields[3] as DateTime,
      priority: fields[4] as int,
      isCompleted: fields[5] as bool,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.dueDate)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskModelAdapter && other.typeId == typeId);
}
