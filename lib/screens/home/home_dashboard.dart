import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_widget.dart';
import '../../features/tasks/domain/entities/task.dart';
import '../../features/tasks/domain/entities/task_priority.dart';
import '../../features/tasks/presentation/providers/task_providers.dart';
import '../../features/tasks/presentation/widgets/priority_badge.dart';
import '../../features/tasks/presentation/widgets/task_card.dart';
import '../../routes/app_routes.dart';

/// Post-login home dashboard: welcome, stats, search, today's tasks, categories.
class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({super.key});

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard> {
  final TextEditingController _searchController = TextEditingController();
  TaskPriority? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(taskSearchProvider.notifier).state = query;
    if (query.isNotEmpty) setState(() => _selectedCategory = null);
    setState(() {});
  }

  void _onSearchCleared() {
    _searchController.clear();
    ref.read(taskSearchProvider.notifier).state = '';
    setState(() {});
  }

  void _onCategoryTap(TaskPriority priority) {
    setState(() {
      _selectedCategory = _selectedCategory == priority ? null : priority;
      // Clear search when a category is selected
      if (_selectedCategory != null) {
        _searchController.clear();
        ref.read(taskSearchProvider.notifier).state = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Task>> tasksAsync = ref.watch(taskListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createTask),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Task'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(taskListProvider.notifier).refresh(),
          child: tasksAsync.when(
            loading: () => const CustomScrollView(
              slivers: <Widget>[
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: LoadingWidget(message: 'Loading your tasks...'),
                ),
              ],
            ),
            error: (Object error, _) => CustomScrollView(
              slivers: <Widget>[
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Something went wrong',
                    message: '$error',
                    actionLabel: 'Retry',
                    onAction: () => ref.invalidate(taskListProvider),
                  ),
                ),
              ],
            ),
            data: (List<Task> allTasks) {
              final String searchQuery =
                  ref.watch(taskSearchProvider).trim().toLowerCase();
              final TaskStats stats = ref.watch(taskStatsProvider);

              final List<Task> displayedTasks =
                  _resolveDisplayedTasks(allTasks, searchQuery);

              final DateTime now = DateTime.now();
              final DateTime today = DateTime(now.year, now.month, now.day);
              final int pendingToday = allTasks.where((Task t) {
                final DateTime due =
                    DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
                return due == today && !t.isCompleted;
              }).length;

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: _WelcomeBanner(
                      stats: stats,
                      pendingToday: pendingToday,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _StatsRow(stats: stats),
                  ),
                  SliverToBoxAdapter(
                    child: _SearchBar(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onCleared: _onSearchCleared,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _CategoriesSection(
                      allTasks: allTasks,
                      selectedCategory: _selectedCategory,
                      onCategoryTap: _onCategoryTap,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _TaskListHeader(
                      searchQuery: searchQuery,
                      selectedCategory: _selectedCategory,
                      count: displayedTasks.length,
                    ),
                  ),
                  if (displayedTasks.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyTasksView(
                        hasAnyTasks: allTasks.isNotEmpty,
                        isFiltered: searchQuery.isNotEmpty ||
                            _selectedCategory != null,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppConstants.spacingMd,
                        0,
                        AppConstants.spacingMd,
                        104,
                      ),
                      sliver: SliverList.separated(
                        itemCount: displayedTasks.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppConstants.spacingSm),
                        itemBuilder: (BuildContext context, int index) {
                          final Task task = displayedTasks[index];
                          return _DismissibleTask(
                            key: ValueKey<String>(task.id),
                            task: task,
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Resolves which tasks to show based on search query / selected category.
  List<Task> _resolveDisplayedTasks(List<Task> all, String query) {
    Iterable<Task> tasks = all;

    if (query.isNotEmpty) {
      tasks = tasks.where(
        (Task t) =>
            t.title.toLowerCase().contains(query) ||
            t.description.toLowerCase().contains(query),
      );
    } else if (_selectedCategory != null) {
      tasks = tasks.where((Task t) => t.priority == _selectedCategory);
    } else {
      // Default: today's tasks (due today and not completed)
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      tasks = tasks.where((Task t) {
        final DateTime due =
            DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
        return due == today;
      });
    }

    return (tasks.toList()
      ..sort((Task a, Task b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        return b.priority.value.compareTo(a.priority.value);
      }));
  }
}

// ---------------------------------------------------------------------------
// Welcome banner
// ---------------------------------------------------------------------------

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.stats, required this.pendingToday});

  final TaskStats stats;
  final int pendingToday;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingLg,
        AppConstants.spacingMd,
        AppConstants.spacingSm,
      ),
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppDateUtils.fullDate(DateTime.now()),
                  style: text.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.80),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${AppDateUtils.greeting()}! 👋',
                  style: text.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pendingToday == 0
                      ? 'All caught up for today!'
                      : '$pendingToday task${pendingToday == 1 ? '' : 's'} due today',
                  style: text.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

}

// ---------------------------------------------------------------------------
// Stats row (completed + pending)
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final TaskStats stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _StatCard(
              label: 'Completed',
              value: stats.completed,
              icon: Icons.task_alt_rounded,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: _StatCard(
              label: 'Pending',
              value: stats.pending,
              icon: Icons.pending_actions_rounded,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingMd,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.20)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingSm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AnimatedSwitcher(
                duration: AppConstants.shortAnimation,
                transitionBuilder: (Widget child, Animation<double> anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Text(
                  '$value',
                  key: ValueKey<int>(value),
                  style: text.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(label, style: text.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search bar
// ---------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  const _SearchBar({
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
        AppConstants.spacingSm,
        AppConstants.spacingMd,
        AppConstants.spacingXs,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search tasks...',
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
// Task categories section (priority-based)
// ---------------------------------------------------------------------------

class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection({
    required this.allTasks,
    required this.selectedCategory,
    required this.onCategoryTap,
  });

  final List<Task> allTasks;
  final TaskPriority? selectedCategory;
  final ValueChanged<TaskPriority> onCategoryTap;

  static const List<_CategoryMeta> _categories = <_CategoryMeta>[
    _CategoryMeta(
      priority: TaskPriority.high,
      label: 'High',
      icon: Icons.local_fire_department_rounded,
    ),
    _CategoryMeta(
      priority: TaskPriority.medium,
      label: 'Medium',
      icon: Icons.bolt_rounded,
    ),
    _CategoryMeta(
      priority: TaskPriority.low,
      label: 'Low',
      icon: Icons.spa_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.spacingMd,
            AppConstants.spacingMd,
            AppConstants.spacingMd,
            AppConstants.spacingSm,
          ),
          child: Text('Categories', style: text.titleMedium),
        ),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMd,
            ),
            itemCount: _categories.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppConstants.spacingMd),
            itemBuilder: (BuildContext context, int index) {
              final _CategoryMeta meta = _categories[index];
              final int total =
                  allTasks.where((Task t) => t.priority == meta.priority).length;
              final int pending = allTasks
                  .where(
                    (Task t) =>
                        t.priority == meta.priority && !t.isCompleted,
                  )
                  .length;
              final Color color = priorityColor(meta.priority);
              final bool selected = selectedCategory == meta.priority;

              return _CategoryCard(
                meta: meta,
                total: total,
                pending: pending,
                color: color,
                selected: selected,
                onTap: () => onCategoryTap(meta.priority),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.meta,
    required this.total,
    required this.pending,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final _CategoryMeta meta;
  final int total;
  final int pending;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final double progress = total == 0 ? 0 : (total - pending) / total;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.shortAnimation,
        width: 130,
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        decoration: BoxDecoration(
          color: selected ? color : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.25),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Icon(
                  meta.icon,
                  color: selected ? Colors.white : color,
                  size: 22,
                ),
                Text(
                  '$total',
                  style: text.titleMedium?.copyWith(
                    color: selected ? Colors.white : color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              meta.label,
              style: text.labelLarge?.copyWith(
                color: selected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: selected
                    ? Colors.white.withValues(alpha: 0.30)
                    : color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  selected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryMeta {
  const _CategoryMeta({
    required this.priority,
    required this.label,
    required this.icon,
  });

  final TaskPriority priority;
  final String label;
  final IconData icon;
}

// ---------------------------------------------------------------------------
// Task list section header
// ---------------------------------------------------------------------------

class _TaskListHeader extends StatelessWidget {
  const _TaskListHeader({
    required this.searchQuery,
    required this.selectedCategory,
    required this.count,
  });

  final String searchQuery;
  final TaskPriority? selectedCategory;
  final int count;

  bool get _isDefaultView =>
      searchQuery.isEmpty && selectedCategory == null;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    final String title = searchQuery.isNotEmpty
        ? 'Search Results'
        : selectedCategory != null
            ? '${selectedCategory!.label} Priority Tasks'
            : "Today's Tasks";

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingMd,
        AppConstants.spacingMd,
        AppConstants.spacingSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(title, style: text.titleMedium),
          if (_isDefaultView)
            TextButton(
              onPressed: () => context.push(AppRoutes.tasks),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingSm,
                  vertical: AppConstants.spacingXs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('View All', style: text.labelLarge?.copyWith(
                    color: AppColors.primary,
                  ),),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 16, color: AppColors.primary,),
                ],
              ),
            )
          else
            AnimatedSwitcher(
              duration: AppConstants.shortAnimation,
              child: Text(
                '$count task${count == 1 ? '' : 's'}',
                key: ValueKey<int>(count),
                style: text.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyTasksView extends StatelessWidget {
  const _EmptyTasksView({
    required this.hasAnyTasks,
    required this.isFiltered,
  });

  final bool hasAnyTasks;
  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    if (!hasAnyTasks) {
      return EmptyState(
        icon: Icons.event_note_rounded,
        title: 'No tasks yet',
        message:
            'Tap the button below to create your first task and get organized.',
        actionLabel: 'Create Task',
        onAction: () => context.push(AppRoutes.createTask),
      );
    }
    if (isFiltered) {
      return const EmptyState(
        icon: Icons.filter_alt_off_rounded,
        title: 'Nothing here',
        message: 'No tasks match your current search or filter.',
      );
    }
    return const EmptyState(
      icon: Icons.today_rounded,
      title: 'Free today!',
      message: 'No tasks due today. Enjoy your day or plan ahead.',
    );
  }
}

// ---------------------------------------------------------------------------
// Dismissible task tile (swipe to edit / delete)
// ---------------------------------------------------------------------------

class _DismissibleTask extends ConsumerWidget {
  const _DismissibleTask({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey<String>('dismiss-${task.id}'),
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
