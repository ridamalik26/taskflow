/// Priority level of a task.
///
/// The integer [value] is what gets persisted in Hive, keeping the storage
/// representation stable even if the enum order changes.
enum TaskPriority {
  low(0, 'Low'),
  medium(1, 'Medium'),
  high(2, 'High');

  const TaskPriority(this.value, this.label);

  final int value;
  final String label;

  /// Resolves a [TaskPriority] from its persisted integer [value].
  static TaskPriority fromValue(int value) {
    return TaskPriority.values.firstWhere(
      (TaskPriority p) => p.value == value,
      orElse: () => TaskPriority.medium,
    );
  }
}
