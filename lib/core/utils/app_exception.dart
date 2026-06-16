/// Base class for all domain/data layer failures surfaced to the UI.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when a local-storage (Hive) operation fails.
class CacheException extends AppException {
  const CacheException([super.message = 'Failed to access local storage.']);
}

/// Thrown when a requested task could not be found.
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'The requested task was not found.']);
}
