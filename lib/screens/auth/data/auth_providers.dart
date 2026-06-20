import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'auth_service.dart';

/// Provides the already-opened Hive box for accounts.
///
/// Overridden in `main()` once the box has been opened asynchronously.
final authBoxProvider = Provider<Box<dynamic>>(
  (ref) => throw UnimplementedError('authBoxProvider must be overridden'),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(authBoxProvider)),
);

/// Holds the normalized email of the currently signed-in user.
/// Empty string means no session.
final currentUserEmailProvider = StateProvider<String>((ref) => '');
