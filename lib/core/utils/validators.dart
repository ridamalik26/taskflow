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
}
