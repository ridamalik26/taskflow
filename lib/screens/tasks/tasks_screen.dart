import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_widget.dart';
import '../../features/tasks/domain/entities/task.dart';
import '../../features/tasks/presentation/providers/task_providers.dart';
import '../../features/tasks/presentation/widgets/task_card.dart';
import '../../routes/app_routes.dart';

/// Dedicated task management screen: browse all tasks, filter by status,
/// search, create, edit, delete, and toggle completion.
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  static const List<TaskFilter> _tabs = [
    TaskFilter.all,
    TaskFilter.pending,
    TaskFilter.completed,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    // Reset shared filter + search state when leaving
    Future.microtask(() {
      if (mounted) return;
      ref.read(taskFilterProvider.notifier).state = TaskFilter.all;
      ref.read(taskSearchProvider.notifier).state = '';
    });
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    ref.read(taskFilterProvider.notifier).state = _tabs[_tabController.index];
  }

  void _onSearchChanged(String query) {
    ref.read(taskSearchProvider.notifier).state = query;
    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(taskSearchProvider.notifier).state = '';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Task>> tasksAsync = ref.watch(taskListProvider);
    final TaskStats stats = ref.watch(taskStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        bottom: _FilterTabBar(controller: _tabController, stats: stats),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createTask),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Task'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _TaskSearchBar(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onCleared: _clearSearch,
            ),
            Expanded(
              child: tasksAsync.when(
                loading: () =>
                    const LoadingWidget(message: 'Loading tasks…'),
                error: (Object e, _) => EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Something went wrong',
                  message: '$e',
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(taskListProvider),
                ),
                data: (_) {
                  final List<Task> tasks = ref.watch(filteredTasksProvider);
                  final TaskFilter filter = ref.watch(taskFilterProvider);

                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(taskListProvider.notifier).refresh(),
                    child: tasks.isEmpty
                        ? CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: <Widget>[
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _EmptyTasksView(filter: filter),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              AppConstants.spacingMd,
                              AppConstants.spacingMd,
                              AppConstants.spacingMd,
                              104,
                            ),
                            itemCount: tasks.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppConstants.spacingSm),
                            itemBuilder: (BuildContext context, int index) {
                              final Task task = tasks[index];
                              return _DismissibleTaskTile(
                                key: ValueKey<String>(task.id),
                                task: task,
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter tab bar
// ---------------------------------------------------------------------------

class _FilterTabBar extends ConsumerWidget implements PreferredSizeWidget {
  const _FilterTabBar({required this.controller, required this.stats});

  final TabController controller;
  final TaskStats stats;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabBar(
      controller: controller,
      indicatorColor: AppColors.primary,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      tabs: <Tab>[
        Tab(text: 'All (${stats.total})'),
        Tab(text: 'Pending (${stats.pending})'),
        Tab(text: 'Done (${stats.completed})'),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Search bar
// ---------------------------------------------------------------------------

class _TaskSearchBar extends StatelessWidget {
  const _TaskSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onCleared,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingMd,
        AppConstants.spacingMd,
        AppConstants.spacingXs,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search tasks…',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onCleared,
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dismissible task tile (swipe left → edit, swipe right → delete)
// ---------------------------------------------------------------------------

class _DismissibleTaskTile extends ConsumerWidget {
  const _DismissibleTaskTile({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey<String>('dismiss-tasks-${task.id}'),
      background: _swipeBg(
        color: AppColors.primary,
        icon: Icons.edit_rounded,
        label: 'Edit',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _swipeBg(
        color: AppColors.error,
        icon: Icons.delete_rounded,
        label: 'Delete',
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (DismissDirection direction) async {
        if (direction == DismissDirection.startToEnd) {
          context.push('${AppRoutes.editTask}/${task.id}');
          return false;
        }
        return ConfirmationDialog.show(
          context,
          title: 'Delete task?',
          message:
              'Are you sure you want to delete "${task.title}"? This cannot be undone.',
          confirmLabel: 'Delete',
          isDestructive: true,
          icon: Icons.delete_outline_rounded,
        );
      },
      onDismissed: (_) async {
        await ref.read(taskListProvider.notifier).remove(task.id);
        if (context.mounted) AppSnackbar.info(context, 'Task deleted');
      },
      child: TaskCard(
        task: task,
        onTap: () => context.push('${AppRoutes.taskDetails}/${task.id}'),
        onToggle: () => ref.read(taskListProvider.notifier).toggle(task),
      ),
    );
  }

  Widget _swipeBg({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    final bool isLeft = alignment == Alignment.centerLeft;
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: AppConstants.spacingLg),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (isLeft) Icon(icon, color: Colors.white),
          if (isLeft) const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!isLeft) const SizedBox(width: 8),
          if (!isLeft) Icon(icon, color: Colors.white),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state per filter
// ---------------------------------------------------------------------------

class _EmptyTasksView extends StatelessWidget {
  const _EmptyTasksView({required this.filter});

  final TaskFilter filter;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        switch (filter) {
          case TaskFilter.completed:
            return const EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'No completed tasks',
              message: 'Tasks you mark as done will appear here.',
            );
          case TaskFilter.pending:
            return const EmptyState(
              icon: Icons.inbox_rounded,
              title: 'All caught up!',
              message: 'No pending tasks. Great work!',
            );
          case TaskFilter.all:
            return EmptyState(
              icon: Icons.event_note_rounded,
              title: 'No tasks yet',
              message: 'Tap the button below to create your first task.',
              actionLabel: 'Create Task',
              onAction: () => context.push(AppRoutes.createTask),
            );
        }
      },
    );
  }
}
