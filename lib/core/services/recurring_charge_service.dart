import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/recurring/data/model/recurring_model.dart';
import 'package:bexly/features/recurring/data/model/recurring_enums.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Service to handle automatic charging of recurring payments
class RecurringChargeService {
  final Ref _ref;

  RecurringChargeService(this._ref);

  /// Process all due recurring payments and create transactions
  Future<void> processDueRecurringPayments() async {
    try {
      Log.d('Processing due recurring payments...', label: 'RecurringChargeService');

      final db = _ref.read(databaseProvider);
      final today = DateTime.now();

      // Get all active recurring payments
      final activeRecurrings = await db.recurringDao.watchActiveRecurrings().first;

      Log.d('Found ${activeRecurrings.length} active recurring payments', label: 'RecurringChargeService');

      for (final recurring in activeRecurrings) {
        // Skip if not auto-charge enabled
        if (!recurring.autoCharge) {
          Log.d('Skipping ${recurring.name} - auto-charge disabled', label: 'RecurringChargeService');
          continue;
        }

        // Check if due date is today or in the past
        final nextDueDate = recurring.nextDueDate;
        final isDue = nextDueDate.year == today.year &&
                      nextDueDate.month == today.month &&
                      nextDueDate.day == today.day;

        final isPastDue = nextDueDate.isBefore(today) &&
                         (today.difference(nextDueDate).inDays > 0);

        if (isDue || isPastDue) {
          Log.d('Processing recurring: ${recurring.name} - due on ${nextDueDate.toIso8601String()}',
                label: 'RecurringChargeService');

          await _chargeRecurring(recurring);
        }
      }

      Log.d('Finished processing recurring payments', label: 'RecurringChargeService');
    } catch (e, stackTrace) {
      Log.e('Error processing recurring payments: $e', label: 'RecurringChargeService');
      Log.e('Stack trace: $stackTrace', label: 'RecurringChargeService');
    }
  }

  /// Create transaction from recurring payment and update next due date
  Future<void> _chargeRecurring(RecurringModel recurring) async {
    try {
      final db = _ref.read(databaseProvider);

      // Create transaction with the actual due date (not current date)
      // This ensures transaction shows on correct date even if charged late
      final transaction = TransactionModel(
        transactionType: TransactionType.expense,
        amount: recurring.amount,
        date: recurring.nextDueDate, // Use due date, not current date!
        title: recurring.name,
        category: recurring.category,
        wallet: recurring.wallet,
        notes: 'Auto-charged from recurring payment: ${recurring.name}',
      );

      Log.d('Creating transaction for ${recurring.name}: ${recurring.amount} ${recurring.currency}',
            label: 'RecurringChargeService');

      final transactionId = await db.transactionDao.addTransaction(transaction);

      if (transactionId > 0) {
        Log.d('Transaction created successfully: ID $transactionId', label: 'RecurringChargeService');

        // Update recurring: increment next due date and total payments
        final updatedRecurring = _calculateNextDueDate(recurring);

        await db.recurringDao.updateRecurring(updatedRecurring);

        Log.d('Updated next due date to ${updatedRecurring.nextDueDate.toIso8601String()}',
              label: 'RecurringChargeService');
      } else {
        Log.e('Failed to create transaction for ${recurring.name}', label: 'RecurringChargeService');
      }
    } catch (e, stackTrace) {
      Log.e('Error charging recurring ${recurring.name}: $e', label: 'RecurringChargeService');
      Log.e('Stack trace: $stackTrace', label: 'RecurringChargeService');
    }
  }

  /// Calculate next due date based on frequency
  RecurringModel _calculateNextDueDate(RecurringModel recurring) {
    DateTime nextDate = recurring.nextDueDate;

    switch (recurring.frequency) {
      case RecurringFrequency.daily:
        nextDate = nextDate.add(const Duration(days: 1));
        break;
      case RecurringFrequency.weekly:
        nextDate = nextDate.add(const Duration(days: 7));
        break;
      case RecurringFrequency.monthly:
        // Add 1 month
        nextDate = DateTime(
          nextDate.year,
          nextDate.month + 1,
          nextDate.day,
        );
        break;
      case RecurringFrequency.quarterly:
        // Add 3 months
        nextDate = DateTime(
          nextDate.year,
          nextDate.month + 3,
          nextDate.day,
        );
        break;
      case RecurringFrequency.yearly:
        // Add 1 year
        nextDate = DateTime(
          nextDate.year + 1,
          nextDate.month,
          nextDate.day,
        );
        break;
      case RecurringFrequency.custom:
        // Use custom interval if available
        if (recurring.customInterval != null && recurring.customUnit != null) {
          final interval = recurring.customInterval!;
          switch (recurring.customUnit!.toLowerCase()) {
            case 'day':
            case 'days':
              nextDate = nextDate.add(Duration(days: interval));
              break;
            case 'week':
            case 'weeks':
              nextDate = nextDate.add(Duration(days: interval * 7));
              break;
            case 'month':
            case 'months':
              nextDate = DateTime(nextDate.year, nextDate.month + interval, nextDate.day);
              break;
            case 'year':
            case 'years':
              nextDate = DateTime(nextDate.year + interval, nextDate.month, nextDate.day);
              break;
            default:
              Log.w('Unknown custom unit: ${recurring.customUnit}, defaulting to monthly',
                    label: 'RecurringChargeService');
              nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
          }
        } else {
          // Fallback to monthly if custom interval not set
          nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
        }
        break;
    }

    return recurring.copyWith(
      nextDueDate: nextDate,
      lastChargedDate: DateTime.now(),
      totalPayments: recurring.totalPayments + 1,
    );
  }
}

/// Provider for RecurringChargeService
final recurringChargeServiceProvider = Provider<RecurringChargeService>((ref) {
  return RecurringChargeService(ref);
});
