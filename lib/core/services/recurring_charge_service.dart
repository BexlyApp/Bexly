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

  /// Create transactions for all due recurring payments
  Future<void> createDueTransactions() async {
    try {
      Log.d('Creating transactions for due recurring payments...', label: 'RecurringChargeService');

      final db = _ref.read(databaseProvider);
      final today = DateTime.now();

      // Get all active recurring payments
      final activeRecurrings = await db.recurringDao.watchActiveRecurrings().first;

      Log.d('Found ${activeRecurrings.length} active recurring payments', label: 'RecurringChargeService');

      for (final recurring in activeRecurrings) {
        // Skip if not auto-charge enabled
        if (!recurring.autoCreate) {
          Log.d('Skipping ${recurring.name} - auto-charge disabled', label: 'RecurringChargeService');
          continue;
        }

        // Check if due or past due
        if (_isDueOrPastDue(recurring.nextDueDate, today)) {
          Log.d('Processing recurring: ${recurring.name} - due on ${recurring.nextDueDate.toIso8601String()}',
                label: 'RecurringChargeService');

          await _chargeRecurring(recurring);
        }
      }

      Log.d('Finished creating due transactions', label: 'RecurringChargeService');
    } catch (e, stackTrace) {
      Log.e('Error creating due transactions: $e', label: 'RecurringChargeService');
      Log.e('Stack trace: $stackTrace', label: 'RecurringChargeService');
    }
  }

  /// Create transaction from recurring payment and update next due date
  /// IMPORTANT: This method handles ALL past due payments, not just one
  Future<void> _chargeRecurring(RecurringModel recurring) async {
    try {
      final db = _ref.read(databaseProvider);
      final today = DateTime.now();

      int transactionsCreated = 0;
      RecurringModel current = recurring;

      // Loop to create ALL past due transactions
      // This ensures we don't skip payments if user doesn't open app for weeks/months
      while (_isDueOrPastDue(current.nextDueDate, today)) {
        // Create transaction with the actual due date (not current date)
        // This ensures transaction shows on correct date even if charged late
        final transaction = TransactionModel(
          transactionType: TransactionType.expense,
          amount: current.amount,
          date: current.nextDueDate, // Use due date, not current date!
          title: current.name,
          category: current.category,
          wallet: current.wallet,
          notes: 'Auto-created from recurring payment: ${current.name}',
          recurringId: current.id, // Link transaction to recurring payment for history tracking
        );

        Log.d('Creating transaction for ${current.name}: ${current.amount} ${current.currency} on ${current.nextDueDate.toIso8601String()}',
              label: 'RecurringChargeService');

        final transactionId = await db.transactionDao.addTransaction(transaction);

        if (transactionId > 0) {
          transactionsCreated++;
          Log.d('Transaction created successfully: ID $transactionId', label: 'RecurringChargeService');

          // Calculate next due date for next iteration
          current = _calculateNextDueDate(current);
        } else {
          Log.e('Failed to create transaction for ${current.name}', label: 'RecurringChargeService');
          break; // Stop if transaction creation fails
        }

        // Safety check: prevent infinite loop (max 365 transactions = 1 year of daily payments)
        if (transactionsCreated >= 365) {
          Log.w('Stopped after creating 365 transactions for ${recurring.name} to prevent infinite loop',
                label: 'RecurringChargeService');
          break;
        }
      }

      // Update recurring with final next due date
      if (transactionsCreated > 0) {
        await db.recurringDao.updateRecurring(current);
        Log.d('Created $transactionsCreated transaction(s) for ${recurring.name}. Next due date: ${current.nextDueDate.toIso8601String()}',
              label: 'RecurringChargeService');
      }
    } catch (e, stackTrace) {
      Log.e('Error charging recurring ${recurring.name}: $e', label: 'RecurringChargeService');
      Log.e('Stack trace: $stackTrace', label: 'RecurringChargeService');
    }
  }

  /// Check if a date is due or past due (same day or before today)
  bool _isDueOrPastDue(DateTime dueDate, DateTime today) {
    // Compare only date parts (ignore time)
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final todayOnly = DateTime(today.year, today.month, today.day);

    return dueDateOnly.isBefore(todayOnly) || dueDateOnly.isAtSameMomentAs(todayOnly);
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

