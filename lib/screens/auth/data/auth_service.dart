import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';

/// Outcome of a login attempt.
enum LoginResult { success, notRegistered, wrongPassword }

/// A minimal, local-only account store backed by Hive.
///
/// There is no backend: accounts are persisted on-device, keyed by a
/// normalized (trimmed + lower-cased) email. This lets a user register once and
/// then sign in with the same credentials, even across app restarts.
class AuthService {
  AuthService(this._box);

  final Box<dynamic> _box;

  /// Whether an account already exists for [email].
  bool isRegistered(String email) => _box.containsKey(_key(email));

  /// Persists a new account. Returns `false` if the email is already taken.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final String key = _key(email);
    if (_box.containsKey(key)) return false;
    await _box.put(key, <String, String>{
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
    });
    return true;
  }

  /// Verifies credentials against the stored account.
  LoginResult login({required String email, required String password}) {
    final String key = _key(email);
    final dynamic stored = _box.get(key);
    if (stored == null) return LoginResult.notRegistered;
    if (stored['password'] != password) return LoginResult.wrongPassword;
    return LoginResult.success;
  }

  /// Returns the stored account data for [email], or `null` if not found.
  Map<String, String>? getUser(String email) {
    final dynamic stored = _box.get(_key(email));
    if (stored == null) return null;
    return Map<String, String>.from(stored as Map);
  }

  String _key(String email) => email.trim().toLowerCase();

  /// Opens (or returns the already-open) Hive box backing the account store.
  static Future<Box<dynamic>> openBox() async {
    if (Hive.isBoxOpen(AppConstants.authBoxName)) {
      return Hive.box<dynamic>(AppConstants.authBoxName);
    }
    return Hive.openBox<dynamic>(AppConstants.authBoxName);
  }
}
