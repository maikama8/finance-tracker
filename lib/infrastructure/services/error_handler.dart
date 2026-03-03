import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Centralized error handling service for the application
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// Stream controller for error events
  final _errorController = StreamController<AppError>.broadcast();
  
  /// Stream of error events for UI consumption
  Stream<AppError> get errorStream => _errorController.stream;

  /// Handles an error and logs it appropriately
  void handleError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    ErrorSeverity severity = ErrorSeverity.error,
  }) {
    final appError = AppError(
      error: error,
      stackTrace: stackTrace,
      context: context,
      severity: severity,
      timestamp: DateTime.now(),
    );

    // Log the error
    _logError(appError);

    // Emit error to stream for UI handling
    if (!_errorController.isClosed) {
      _errorController.add(appError);
    }
  }

  /// Logs error based on severity
  void _logError(AppError appError) {
    final message = _formatErrorMessage(appError);

    switch (appError.severity) {
      case ErrorSeverity.info:
        developer.log(
          message,
          name: 'FinanceTracker',
          level: 800,
        );
        break;
      case ErrorSeverity.warning:
        developer.log(
          message,
          name: 'FinanceTracker',
          level: 900,
          error: appError.error,
          stackTrace: appError.stackTrace,
        );
        break;
      case ErrorSeverity.error:
      case ErrorSeverity.critical:
        developer.log(
          message,
          name: 'FinanceTracker',
          level: 1000,
          error: appError.error,
          stackTrace: appError.stackTrace,
        );
        break;
    }

    // In debug mode, also print to console
    if (kDebugMode) {
      debugPrint('[${ appError.severity.name.toUpperCase()}] $message');
      if (appError.stackTrace != null) {
        debugPrint('Stack trace:\n${appError.stackTrace}');
      }
    }
  }

  /// Formats error message for logging
  String _formatErrorMessage(AppError appError) {
    final buffer = StringBuffer();
    
    if (appError.context != null) {
      buffer.write('[${appError.context}] ');
    }
    
    buffer.write(appError.error.toString());
    
    return buffer.toString();
  }

  /// Gets user-friendly error message
  String getUserFriendlyMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }

    // Network errors
    if (error.toString().contains('SocketException') ||
        error.toString().contains('NetworkException')) {
      return 'No internet connection. Please check your network and try again.';
    }

    // Timeout errors
    if (error.toString().contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }

    // Firebase errors
    if (error.toString().contains('firebase')) {
      return 'A server error occurred. Please try again later.';
    }

    // Storage errors
    if (error.toString().contains('storage') ||
        error.toString().contains('database')) {
      return 'Failed to save data. Please try again.';
    }

    // Authentication errors
    if (error.toString().contains('auth') ||
        error.toString().contains('permission')) {
      return 'Authentication failed. Please log in again.';
    }

    // Payment errors
    if (error.toString().contains('payment')) {
      return 'Payment processing failed. Please try again.';
    }

    // Generic error
    return 'An unexpected error occurred. Please try again.';
  }

  /// Disposes resources
  void dispose() {
    _errorController.close();
  }
}

/// Represents an application error with context
class AppError {
  final dynamic error;
  final StackTrace? stackTrace;
  final String? context;
  final ErrorSeverity severity;
  final DateTime timestamp;

  AppError({
    required this.error,
    this.stackTrace,
    this.context,
    required this.severity,
    required this.timestamp,
  });

  String get userMessage => ErrorHandler().getUserFriendlyMessage(error);
}

/// Error severity levels
enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

/// Base class for application-specific exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

/// Network-related exceptions
class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.originalError});
}

/// Storage-related exceptions
class StorageException extends AppException {
  StorageException(super.message, {super.code, super.originalError});
}

/// Authentication-related exceptions
class AuthException extends AppException {
  AuthException(super.message, {super.code, super.originalError});
}

/// Validation-related exceptions
class ValidationException extends AppException {
  ValidationException(super.message, {super.code, super.originalError});
}

/// Payment-related exceptions
class PaymentException extends AppException {
  PaymentException(super.message, {super.code, super.originalError});
}

/// Sync-related exceptions
class SyncException extends AppException {
  SyncException(super.message, {super.code, super.originalError});
}
