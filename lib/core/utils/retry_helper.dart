import 'dart:math';
import 'package:bexly/core/utils/logger.dart';

/// Simple retry helper for network operations
/// Retries failed operations with exponential backoff
class RetryHelper {
  /// Executes a function with retry logic
  ///
  /// [operation] - The async operation to retry
  /// [maxAttempts] - Maximum number of attempts (default: 3)
  /// [operationName] - Name for logging (default: 'operation')
  ///
  /// Returns the result of the operation if successful
  /// Throws the last exception if all retries fail
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    String operationName = 'operation',
  }) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final result = await operation();

        if (attempt > 1) {
          Log.d('✅ $operationName succeeded on attempt $attempt', label: 'retry');
        }

        return result;
      } catch (e) {
        final isLastAttempt = attempt == maxAttempts;

        if (isLastAttempt) {
          Log.e('❌ $operationName failed after $maxAttempts attempts: $e', label: 'retry');
          rethrow; // Throw original exception
        }

        // Calculate exponential backoff: 1s, 2s, 4s
        final delaySeconds = pow(2, attempt - 1).toInt();
        Log.w('⚠️ $operationName failed (attempt $attempt/$maxAttempts), retrying in ${delaySeconds}s: $e', label: 'retry');

        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }

    // This should never be reached due to rethrow above, but Dart requires a return
    throw Exception('Retry logic error');
  }
}
