import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_priority.dart';
import '../providers/task_providers.dart';

/// A reusable form for creating or editing a [Task].
///
/// When [existing] is null the form operates in "create" mode; otherwise it is
/// pre-filled and operates in "edit" mode.
class TaskForm extends ConsumerStatefulWidget {
  const TaskForm({super.key, this.existing});

  final Task? existing;

  @override
  ConsumerState<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends ConsumerState<TaskForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final TextEditingController _dueDateController = TextEditingController();

  DateTime? _dueDate;
  TaskPriority _priority = TaskPriority.medium;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final Task? task = widget.existing;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController =
        TextEditingController(text: task?.description ?? '');
    if (task != null) {
      _dueDate = task.dueDate;
      _priority = task.priority;
      _dueDateController.text = AppDateUtils.fullDate(task.dueDate);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime initial = _dueDate ?? now;
    final DateTime picked = await showDatePicker(
          context: context,
          initialDate: initial.isBefore(now) ? now : initial,
          firstDate: DateTime(now.year, now.month, now.day),
          lastDate: DateTime(now.year + 5),
        ) ??
        initial;
    setState(() {
      _dueDate = picked;
      _dueDateController.text = AppDateUtils.fullDate(picked);
    });
  }

  Future<void> _submit() async {
    // Validate text fields.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Validate due date separately (it is not a TextFormField value).
    if (_dueDate == null) {
      AppSnackbar.error(context, 'Please select a due date');
      return;
    }

    setState(() => _saving = true);

    final Task task = (widget.existing ??
            Task(
              id: const Uuid().v4(),
              title: '',
              description: '',
              dueDate: _dueDate!,
              priority: _priority,
              isCompleted: false,
              createdAt: DateTime.now(),
            ))
        .copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dueDate: _dueDate,
      priority: _priority,
    );

    try {
      final notifier = ref.read(taskListProvider.notifier);
      if (_isEditing) {
        await notifier.updateTask(task);
      } else {
        await notifier.add(task);
      }
      if (!mounted) return;
      AppSnackbar.success(
        context,
        _isEditing ? 'Task updated successfully' : 'Task created successfully',
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.error(context, 'Something went wrong: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        children: <Widget>[
          CustomTextField(
            controller: _titleController,
            label: 'Task Title',
            hint: 'e.g. Prepare project presentation',
            prefixIcon: Icons.title_rounded,
            textInputAction: TextInputAction.next,
            validator: Validators.title,
            maxLength: 100,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          CustomTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Add more details (optional)',
            prefixIcon: Icons.notes_rounded,
            maxLines: 4,
            maxLength: 500,
            validator: Validators.description,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          CustomTextField(
            controller: _dueDateController,
            label: 'Due Date',
            hint: 'Select a due date',
            prefixIcon: Icons.event_rounded,
            readOnly: true,
            onTap: _pickDate,
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text('Priority', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppConstants.spacingSm),
          _PrioritySelector(
            selected: _priority,
            onChanged: (TaskPriority p) => setState(() => _priority = p),
          ),
          const SizedBox(height: AppConstants.spacingXl),
          CustomButton(
            label: _isEditing ? 'Update Task' : 'Save Task',
            icon: Icons.check_rounded,
            isLoading: _saving,
            onPressed: _submit,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          CustomButton(
            label: 'Cancel',
            isOutlined: true,
            onPressed: _saving ? null : () => context.pop(),
          ),
        ],
      ),
    );
  }
}

/// A segmented selector for choosing a [TaskPriority].
class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({required this.selected, required this.onChanged});

  final TaskPriority selected;
  final ValueChanged<TaskPriority> onChanged;

  Color _colorFor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return AppColors.success;
      case TaskPriority.medium:
        return AppColors.warning;
      case TaskPriority.high:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TaskPriority.values.map((TaskPriority p) {
        final bool isSelected = p == selected;
        final Color color = _colorFor(p);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: AppConstants.shortAnimation,
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spacingMd,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.15)
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : AppColors.textSecondary.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Icon(
                      Icons.flag_rounded,
                      color: isSelected ? color : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.label,
                      style: TextStyle(
                        color: isSelected ? color : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
