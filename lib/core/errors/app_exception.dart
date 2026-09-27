/// Standard application exception model that maps low-level or network errors
/// to user-friendly, actionable error messages.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({required this.message, this.code, this.originalError});

  @override
  String toString() => message;

  factory AppException.fromFirebase(dynamic error) {
    final String errorStr = error.toString().toLowerCase();

    if (errorStr.contains('permission-denied') ||
        errorStr.contains('permission denied')) {
      return const AppException(
        message:
            'Access restricted. You might not have permission for this group or action.',
        code: 'permission-denied',
      );
    }

    if (errorStr.contains('unavailable') ||
        errorStr.contains('network') ||
        errorStr.contains('socketexception') ||
        errorStr.contains('connection failed')) {
      return const AppException(
        message:
            'No internet connection. Please check your network and try again.',
        code: 'network-unavailable',
      );
    }

    if (errorStr.contains('not-found') || errorStr.contains('not found')) {
      return const AppException(
        message: 'The requested group or record could not be found.',
        code: 'not-found',
      );
    }

    return AppException(
      message: 'An unexpected error occurred. Please try again.',
      code: 'unknown',
      originalError: error,
    );
  }
}
