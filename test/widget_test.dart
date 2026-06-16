import 'package:flutter_test/flutter_test.dart';

import 'package:task_manager_app/features/tasks/domain/entities/task.dart';
import 'package:task_manager_app/features/tasks/domain/entities/task_priority.dart';

void main() {
  group('Task entity', () {
    final Task sample = Task(
      id: '1',
      title: 'Write tests',
      description: 'Cover the domain layer',
      dueDate: DateTime(2026, 6, 20),
      priority: TaskPriority.high,
      isCompleted: false,
      createdAt: DateTime(2026, 6, 16),
    );

    test('toggleCompleted flips completion state', () {
      expect(sample.isCompleted, isFalse);
      expect(sample.toggleCompleted().isCompleted, isTrue);
    });

    test('copyWith replaces only provided fields', () {
      final Task updated = sample.copyWith(title: 'Updated');
      expect(updated.title, 'Updated');
      expect(updated.id, sample.id);
      expect(updated.priority, sample.priority);
    });

    test('equality is based on id', () {
      expect(sample, sample.copyWith(title: 'Different title'));
    });
  });

  group('TaskPriority', () {
    test('fromValue resolves persisted integers', () {
      expect(TaskPriority.fromValue(0), TaskPriority.low);
      expect(TaskPriority.fromValue(2), TaskPriority.high);
      expect(TaskPriority.fromValue(99), TaskPriority.medium); // fallback
    });
  });
}
