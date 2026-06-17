/// Reusable form field validators.
class Validators {
  Validators._();

  /// Validates that a task title is present and reasonably sized.
  static String? title(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return 'Title is required';
    if (text.length < 3) return 'Title must be at least 3 characters';
    if (text.length > 100) return 'Title must be under 100 characters';
    return null;
  }

  /// Description is optional but capped in length.
  static String? description(String? value) {
    final String text = (value ?? '').trim();
    if (text.length > 500) return 'Description must be under 500 characters';
    return null;
  }

  static final RegExp _emailPattern = RegExp(
    r'^[\w.+-]+@[\w-]+\.[\w.-]+$',
  );

  /// Validates a person's full name.
  static String? fullName(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return 'Full name is required';
    if (text.length < 2) return 'Name must be at least 2 characters';
    if (text.length > 50) return 'Name must be under 50 characters';
    return null;
  }

  /// Validates that an email is present and well-formed.
  static String? email(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }

  /// Validates that a password meets minimum strength requirements.
  static String? password(String? value) {
    final String text = value ?? '';
    if (text.isEmpty) return 'Password is required';
    if (text.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  /// Validates that the confirmation matches the original [password].
  static String? confirmPassword(String? value, String password) {
    final String text = value ?? '';
    if (text.isEmpty) return 'Please confirm your password';
    if (text != password) return 'Passwords do not match';
    return null;
  }
}
