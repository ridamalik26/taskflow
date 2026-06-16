import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../features/tasks/presentation/screens/create_task_screen.dart';
import '../features/tasks/presentation/screens/edit_task_screen.dart';
import '../features/tasks/presentation/screens/home_screen.dart';
import '../features/tasks/presentation/screens/splash_screen.dart';
import '../features/tasks/presentation/screens/task_details_screen.dart';
import 'app_routes.dart';

/// Builds the application's [GoRouter] with all routes and transitions.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: AppRoutes.homeName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadePage(state, const HomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.createTask,
        name: AppRoutes.createTaskName,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slidePage(state, const CreateTaskScreen()),
      ),
      GoRoute(
        path: '${AppRoutes.editTask}/:id',
        name: AppRoutes.editTaskName,
        pageBuilder: (BuildContext context, GoRouterState state) => _slidePage(
          state,
          EditTaskScreen(taskId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '${AppRoutes.taskDetails}/:id',
        name: AppRoutes.taskDetailsName,
        pageBuilder: (BuildContext context, GoRouterState state) => _slidePage(
          state,
          TaskDetailsScreen(taskId: state.pathParameters['id']!),
        ),
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );

  /// A fade transition page (used for the home screen).
  static CustomTransitionPage<void> _fadePage(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppConstants.mediumAnimation,
      transitionsBuilder: (_, Animation<double> animation, __, Widget child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  /// A slide-up + fade transition page (used for detail/form screens).
  static CustomTransitionPage<void> _slidePage(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppConstants.mediumAnimation,
      transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
        final Animation<Offset> offset = Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
    );
  }
}
