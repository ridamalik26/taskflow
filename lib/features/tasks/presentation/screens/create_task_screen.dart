import 'package:flutter/material.dart';

import '../widgets/task_form.dart';

/// Screen for creating a brand new task.
class CreateTaskScreen extends StatelessWidget {
  const CreateTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Task')),
      body: const SafeArea(child: TaskForm()),
    );
  }
}
