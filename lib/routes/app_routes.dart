/// Centralized route path and name constants used with Go Router.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String home = '/home';
  static const String createTask = '/create';
  static const String editTask = '/edit'; // expects :id path param
  static const String taskDetails = '/task'; // expects :id path param

  // Named routes (handy for `context.goNamed`).
  static const String splashName = 'splash';
  static const String homeName = 'home';
  static const String createTaskName = 'create';
  static const String editTaskName = 'edit';
  static const String taskDetailsName = 'details';
}
