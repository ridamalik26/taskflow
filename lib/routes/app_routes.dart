/// Centralized route path and name constants used with Go Router.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String createTask = '/create';
  static const String editTask = '/edit'; // expects :id path param
  static const String taskDetails = '/task'; // expects :id path param
  static const String tasks = '/tasks';
  static const String profile = '/profile';

  // Named routes (handy for `context.goNamed`).
  static const String splashName = 'splash';
  static const String loginName = 'login';
  static const String registerName = 'register';
  static const String homeName = 'home';
  static const String createTaskName = 'create';
  static const String editTaskName = 'edit';
  static const String taskDetailsName = 'details';
  static const String tasksName = 'tasks';
  static const String profileName = 'profile';
}
