import 'package:firebase_auth/firebase_auth.dart';

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

/// Thrown when linking an account conflicts with an already-existing account.
class AuthConflictException extends AppException {
  final AuthCredential? credential;
  final String? conflictingEmail;

  const AuthConflictException({
    required super.message,
    super.code = 'credential-already-in-use',
    this.credential,
    this.conflictingEmail,
    super.originalError,
  });
}

/// Thrown when the user intentionally cancels or dismisses an external authentication sheet.
class AuthCancelledException extends AppException {
  const AuthCancelledException({
    super.message = 'Authentication was cancelled.',
    super.code = 'cancelled',
    super.originalError,
  });
}

/// Thrown when a sensitive action requires recent authentication.
/// The user should re-authenticate and retry the operation.
class AuthReauthRequiredException extends AppException {
  const AuthReauthRequiredException({
    super.message = 'Please sign in again to confirm this action.',
    super.code = 'requires-recent-login',
    super.originalError,
  });
}
