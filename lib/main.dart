import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/tasks/data/datasources/task_local_datasource.dart';
import 'features/tasks/data/models/task_model.dart';
import 'features/tasks/presentation/providers/task_providers.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  // Ensure bindings are ready before any async/platform work.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and register the (hand-written) task adapter.
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TaskModelAdapter());
  }

  // Open the box up-front so the UI never has to await it.
  final box = await TaskLocalDataSourceImpl.openBox();

  // Catch any otherwise-unhandled framework errors and log them.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Uncaught Flutter error: ${details.exception}');
  };

  runApp(
    ProviderScope(
      // Inject the opened Hive box into the provider graph.
      overrides: <Override>[taskBoxProvider.overrideWithValue(box)],
      child: const TaskManagerApp(),
    ),
  );
}

/// Root application widget.
class TaskManagerApp extends ConsumerWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'TaskFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
      // Constrain text scaling so the premium layout stays consistent.
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData mq = MediaQuery.of(context);
        final double clamped = mq.textScaler.scale(1).clamp(0.85, 1.3);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(clamped)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
