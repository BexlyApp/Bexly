import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/features/recurring/data/model/recurring_model.dart';
import 'package:bexly/features/recurring/data/model/recurring_enums.dart';

/// Provider for RecurringDao
final recurringDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return db.recurringDao;
});

/// Stream provider for all recurrings
final allRecurringsProvider = StreamProvider.autoDispose<List<RecurringModel>>((ref) {
  final dao = ref.watch(recurringDaoProvider);
  return dao.watchAllRecurrings();
});

/// Stream provider for active recurrings only
final activeRecurringsProvider = StreamProvider.autoDispose<List<RecurringModel>>((ref) {
  final dao = ref.watch(recurringDaoProvider);
  return dao.watchActiveRecurrings();
});

/// Stream provider for upcoming recurrings (due in next 7 days)
final upcomingRecurringsProvider = StreamProvider.autoDispose<List<RecurringModel>>((ref) {
  final dao = ref.watch(recurringDaoProvider);
  return dao.watchUpcomingRecurrings(7);
});

/// Stream provider for overdue recurrings
final overdueRecurringsProvider = StreamProvider.autoDispose<List<RecurringModel>>((ref) {
  final dao = ref.watch(recurringDaoProvider);
  return dao.watchOverdueRecurrings();
});

/// Stream provider for recurrings by wallet
final recurringsByWalletProvider = StreamProvider.autoDispose.family<List<RecurringModel>, int>((ref, walletId) {
  final dao = ref.watch(recurringDaoProvider);
  return dao.watchRecurringsByWallet(walletId);
});

/// Stream provider for recurrings by category
final recurringsByCategoryProvider = StreamProvider.autoDispose.family<List<RecurringModel>, int>((ref, categoryId) {
  final dao = ref.watch(recurringDaoProvider);
  return dao.watchRecurringsByCategory(categoryId);
});

/// Stream provider for recurrings by status
final recurringsByStatusProvider = StreamProvider.autoDispose.family<List<RecurringModel>, RecurringStatus>((ref, status) {
  final dao = ref.watch(recurringDaoProvider);
  return dao.watchRecurringsByStatus(status);
});

/// Stream provider for a single recurring by ID
final recurringByIdProvider = StreamProvider.autoDispose.family<RecurringModel?, int>((ref, id) {
  final dao = ref.watch(recurringDaoProvider);
  return dao.watchRecurringById(id);
});

/// Future provider for total monthly commitment by wallet
final totalMonthlyCommitmentProvider = FutureProvider.autoDispose.family<double, int>((ref, walletId) async {
  final dao = ref.read(recurringDaoProvider);
  return dao.getTotalMonthlyCommitment(walletId);
});

/// Provider for recurring actions (add, update, delete, etc.)
final recurringActionsProvider = Provider((ref) {
  final dao = ref.watch(recurringDaoProvider);
  return RecurringActions(dao);
});

/// Class containing all recurring actions
class RecurringActions {
  final dynamic dao; // RecurringDao type

  RecurringActions(this.dao);

  /// Add a new recurring
  Future<int> addRecurring(RecurringModel recurring) async {
    return dao.addRecurring(recurring);
  }

  /// Update an existing recurring
  Future<bool> updateRecurring(RecurringModel recurring) async {
    return dao.updateRecurring(recurring);
  }

  /// Delete a recurring
  Future<int> deleteRecurring(int id) async {
    return dao.deleteRecurring(id);
  }

  /// Pause a recurring
  Future<bool> pauseRecurring(int id) async {
    return dao.pauseRecurring(id);
  }

  /// Resume a recurring
  Future<bool> resumeRecurring(int id) async {
    return dao.resumeRecurring(id);
  }

  /// Cancel a recurring
  Future<bool> cancelRecurring(int id) async {
    return dao.cancelRecurring(id);
  }

  /// Process payment for a recurring
  Future<bool> processPayment(int id, DateTime nextDueDate) async {
    return dao.processPayment(id, nextDueDate);
  }
}
