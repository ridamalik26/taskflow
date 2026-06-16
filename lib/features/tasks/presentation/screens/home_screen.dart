import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/entities/task.dart';
import '../providers/task_providers.dart';
import '../widgets/stats_card.dart';
import '../widgets/task_card.dart';

/// The main dashboard: greeting, statistics, search, filters and task list.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            loading: () => const _LoadingView(),
            error: (Object error, _) => _ErrorView(
              message: '$error',
              onRetry: () => ref.invalidate(taskListProvider),
            ),
            data: (_) => const _HomeBody(),
          ),
        ),
      ),
    );
  }
}

/// A loading list placeholder that still allows pull-to-refresh.
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: LoadingWidget(message: 'Loading your tasks...'),
        ),
      ],
    );
  }
}

/// Error view with retry, scrollable so refresh still works.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Something went wrong',
            message: message,
            actionLabel: 'Retry',
            onAction: onRetry,
          ),
        ),
      ],
    );
  }
}

/// The populated home content.
class _HomeBody extends ConsumerWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Task> filtered = ref.watch(filteredTasksProvider);
    final TaskStats stats = ref.watch(taskStatsProvider);
    final bool hasAnyTasks = stats.total > 0;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        const SliverToBoxAdapter(child: _Header()),
        SliverToBoxAdapter(child: _StatsRow(stats: stats)),
        if (hasAnyTasks) ...<Widget>[
          const SliverToBoxAdapter(child: _SearchBar()),
          const SliverToBoxAdapter(child: _FilterChips()),
        ],
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyTasks(hasAnyTasks: hasAnyTasks),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spacingMd,
              AppConstants.spacingSm,
              AppConstants.spacingMd,
              100, // leave room for the FAB
            ),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppConstants.spacingSm),
              itemBuilder: (BuildContext context, int index) {
                final Task task = filtered[index];
                return _DismissibleTask(key: ValueKey<String>(task.id), task: task);
              },
            ),
          ),
      ],
    );
  }
}

/// Greeting header showing the current date.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingLg,
        AppConstants.spacingLg,
        AppConstants.spacingLg,
        AppConstants.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppDateUtils.fullDate(DateTime.now()),
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${AppDateUtils.greeting()} 👋',
                  style: text.headlineMedium,
                ),
              ),
              Container(
                height: 46,
                width: 46,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Row of the three statistics cards.
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
            child: StatsCard(
              label: 'Total',
              value: stats.total,
              icon: Icons.list_alt_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: StatsCard(
              label: 'Completed',
              value: stats.completed,
              icon: Icons.task_alt_rounded,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: StatsCard(
              label: 'Pending',
              value: stats.pending,
              icon: Icons.pending_actions_rounded,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Search input that updates [taskSearchProvider].
class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar();

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
        controller: _controller,
        onChanged: (String value) =>
            ref.read(taskSearchProvider.notifier).state = value,
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _controller.clear();
                    ref.read(taskSearchProvider.notifier).state = '';
                    setState(() {});
                  },
                ),
        ),
      ),
    );
  }
}

/// Filter chips for All / Pending / Completed.
class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TaskFilter active = ref.watch(taskFilterProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      child: Row(
        children: TaskFilter.values.map((TaskFilter filter) {
          final bool selected = filter == active;
          return Padding(
            padding: const EdgeInsets.only(right: AppConstants.spacingSm),
            child: ChoiceChip(
              label: Text(filter.label),
              selected: selected,
              onSelected: (_) =>
                  ref.read(taskFilterProvider.notifier).state = filter,
              showCheckmark: false,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Empty state shown when there are no tasks (or none match the filter).
class _EmptyTasks extends ConsumerWidget {
  const _EmptyTasks({required this.hasAnyTasks});

  final bool hasAnyTasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!hasAnyTasks) {
      return EmptyState(
        icon: Icons.event_note_rounded,
        title: 'No tasks yet',
        message: 'Tap the button below to create your first task and get '
            'organized.',
        actionLabel: 'Create Task',
        onAction: () => context.push(AppRoutes.createTask),
      );
    }
    return const EmptyState(
      icon: Icons.filter_alt_off_rounded,
      title: 'Nothing here',
      message: 'No tasks match your current search or filter.',
    );
  }
}

/// Wraps a [TaskCard] with swipe-to-edit (right) and swipe-to-delete (left).
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
          // Swipe right -> edit. Don't actually dismiss the tile.
          context.push('${AppRoutes.editTask}/${task.id}');
          return false;
        }
        // Swipe left -> confirm delete.
        return ConfirmationDialog.show(
          context,
          title: 'Delete task?',
          message: 'Are you sure you want to delete "${task.title}"? '
              'This cannot be undone.',
          confirmLabel: 'Delete',
          isDestructive: true,
          icon: Icons.delete_outline_rounded,
        );
      },
      onDismissed: (_) async {
        await ref.read(taskListProvider.notifier).remove(task.id);
        if (context.mounted) {
          AppSnackbar.info(context, 'Task deleted');
        }
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
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLg),
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
