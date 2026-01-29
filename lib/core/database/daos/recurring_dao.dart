import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/tables/recurrings_table.dart';
import 'package:bexly/core/database/tables/category_table.dart';
import 'package:bexly/core/database/tables/wallet_table.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/recurring/data/model/recurring_model.dart';
import 'package:bexly/features/recurring/data/model/recurring_enums.dart';
import 'package:bexly/core/services/sync/supabase_sync_provider.dart';

part 'recurring_dao.g.dart';

@DriftAccessor(tables: [Recurrings, Categories, Wallets])
class RecurringDao extends DatabaseAccessor<AppDatabase> with _$RecurringDaoMixin {
  final Ref? _ref;

  RecurringDao(super.db, [this._ref]);

  Future<RecurringModel> _mapRecurring(Recurring recurringData) async {
    final wallet = await db.walletDao.getWalletById(recurringData.walletId);
    final category = await db.categoryDao.getCategoryById(
      recurringData.categoryId,
    );

    if (wallet == null || category == null) {
      throw Exception(
        'Failed to map recurring: Wallet or Category not found for recurring ID ${recurringData.id}',
      );
    }

    return RecurringModel(
      id: recurringData.id,
      cloudId: recurringData.cloudId,
      name: recurringData.name,
      description: recurringData.description,
      wallet: wallet.toModel(),
      category: category.toModel(),
      amount: recurringData.amount,
      currency: recurringData.currency,
      startDate: recurringData.startDate,
      nextDueDate: recurringData.nextDueDate,
      frequency: RecurringFrequencyExtension.fromDbValue(recurringData.frequency),
      customInterval: recurringData.customInterval,
      customUnit: recurringData.customUnit,
      billingDay: recurringData.billingDay,
      endDate: recurringData.endDate,
      status: RecurringStatusExtension.fromDbValue(recurringData.status),
      autoCreate: recurringData.autoCreate,
      enableReminder: recurringData.enableReminder,
      reminderDaysBefore: recurringData.reminderDaysBefore,
      notes: recurringData.notes,
      vendorName: recurringData.vendorName,
      iconName: recurringData.iconName,
      colorHex: recurringData.colorHex,
      lastChargedDate: recurringData.lastChargedDate,
      totalPayments: recurringData.totalPayments,
      createdAt: recurringData.createdAt,
      updatedAt: recurringData.updatedAt,
    );
  }

  Future<List<RecurringModel>> _mapRecurrings(List<Recurring> recurringDataList) async {
    // Fetch all required wallets and categories in batches for efficiency
    final walletIds = recurringDataList.map((r) => r.walletId).toSet().toList();
    final categoryIds = recurringDataList.map((r) => r.categoryId).toSet().toList();

    final walletsMap = {
      for (var w in await db.walletDao.getWalletsByIds(walletIds)) w.id: w,
    };
    final categoriesMap = {
      for (var c in await db.categoryDao.getCategoriesByIds(categoryIds)) c.id: c,
    };

    List<RecurringModel> result = [];
    for (var recurringData in recurringDataList) {
      final wallet = walletsMap[recurringData.walletId];
      final category = categoriesMap[recurringData.categoryId];
      if (wallet == null || category == null) {
        Log.e(
          'Warning: Could not find wallet or category for recurring ${recurringData.id}',
          label: 'recurring',
        );
        continue;
      }
      result.add(
        RecurringModel(
          id: recurringData.id,
          cloudId: recurringData.cloudId,
          name: recurringData.name,
          description: recurringData.description,
          wallet: wallet.toModel(),
          category: category.toModel(),
          amount: recurringData.amount,
          currency: recurringData.currency,
          startDate: recurringData.startDate,
          nextDueDate: recurringData.nextDueDate,
          frequency: RecurringFrequencyExtension.fromDbValue(recurringData.frequency),
          customInterval: recurringData.customInterval,
          customUnit: recurringData.customUnit,
          billingDay: recurringData.billingDay,
          endDate: recurringData.endDate,
          status: RecurringStatusExtension.fromDbValue(recurringData.status),
          autoCreate: recurringData.autoCreate,
          enableReminder: recurringData.enableReminder,
          reminderDaysBefore: recurringData.reminderDaysBefore,
          notes: recurringData.notes,
          vendorName: recurringData.vendorName,
          iconName: recurringData.iconName,
          colorHex: recurringData.colorHex,
          lastChargedDate: recurringData.lastChargedDate,
          totalPayments: recurringData.totalPayments,
          createdAt: recurringData.createdAt,
          updatedAt: recurringData.updatedAt,
        ),
      );
    }
    return result;
  }

  /// Watch all recurring payments
  Stream<List<RecurringModel>> watchAllRecurrings() {
    return (select(recurrings)
          ..orderBy([
            (t) => OrderingTerm(expression: t.nextDueDate, mode: OrderingMode.asc),
          ]))
        .watch()
        .asyncMap(_mapRecurrings);
  }

  /// Watch active recurring payments only
  Stream<List<RecurringModel>> watchActiveRecurrings() {
    return (select(recurrings)
          ..where((r) => r.status.equals(RecurringStatus.active.toDbValue()))
          ..orderBy([
            (t) => OrderingTerm(expression: t.nextDueDate, mode: OrderingMode.asc),
          ]))
        .watch()
        .asyncMap(_mapRecurrings);
  }

  /// Get a single recurring payment by ID
  Future<RecurringModel?> getRecurringById(int id) async {
    final recurringData = await (select(recurrings)
          ..where((r) => r.id.equals(id)))
        .getSingleOrNull();
    return recurringData != null ? _mapRecurring(recurringData) : null;
  }

  /// Watch a single recurring payment by ID
  Stream<RecurringModel?> watchRecurringById(int id) {
    return (select(recurrings)..where((r) => r.id.equals(id)))
        .watchSingleOrNull()
        .asyncMap(
          (recurringData) => recurringData != null ? _mapRecurring(recurringData) : null,
        );
  }

  /// Get upcoming recurring payments (due within specified days)
  Stream<List<RecurringModel>> watchUpcomingRecurrings(int days) {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));

    return (select(recurrings)
          ..where((r) => r.status.equals(RecurringStatus.active.toDbValue()))
          ..where((r) => r.nextDueDate.isBetweenValues(now, futureDate))
          ..orderBy([
            (t) => OrderingTerm(expression: t.nextDueDate, mode: OrderingMode.asc),
          ]))
        .watch()
        .asyncMap(_mapRecurrings);
  }

  /// Get overdue recurring payments
  Stream<List<RecurringModel>> watchOverdueRecurrings() {
    final now = DateTime.now();

    return (select(recurrings)
          ..where((r) => r.status.equals(RecurringStatus.active.toDbValue()))
          ..where((r) => r.nextDueDate.isSmallerThanValue(now))
          ..orderBy([
            (t) => OrderingTerm(expression: t.nextDueDate, mode: OrderingMode.asc),
          ]))
        .watch()
        .asyncMap(_mapRecurrings);
  }

  /// Get recurring payments by wallet
  Stream<List<RecurringModel>> watchRecurringsByWallet(int walletId) {
    return (select(recurrings)
          ..where((r) => r.walletId.equals(walletId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.nextDueDate, mode: OrderingMode.asc),
          ]))
        .watch()
        .asyncMap(_mapRecurrings);
  }

  /// Get recurring payments by category
  Stream<List<RecurringModel>> watchRecurringsByCategory(int categoryId) {
    return (select(recurrings)
          ..where((r) => r.categoryId.equals(categoryId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.nextDueDate, mode: OrderingMode.asc),
          ]))
        .watch()
        .asyncMap(_mapRecurrings);
  }

  /// Get recurring payments by status
  Stream<List<RecurringModel>> watchRecurringsByStatus(RecurringStatus status) {
    return (select(recurrings)
          ..where((r) => r.status.equals(status.toDbValue()))
          ..orderBy([
            (t) => OrderingTerm(expression: t.nextDueDate, mode: OrderingMode.asc),
          ]))
        .watch()
        .asyncMap(_mapRecurrings);
  }

  /// Add a new recurring payment
  Future<int> addRecurring(RecurringModel recurringModel) async {
    Log.d('addRecurring → ${recurringModel.name}', label: 'recurring');

    // CRITICAL: Generate UUID v7 for cloud sync if not present
    final cloudId = recurringModel.cloudId ?? const Uuid().v7();
    Log.d('CloudId for new recurring: $cloudId', label: 'recurring');

    // 1. Save to local database with cloudId
    final id = await into(recurrings).insert(
      RecurringsCompanion.insert(
        cloudId: Value(cloudId),
        name: recurringModel.name,
        description: Value(recurringModel.description),
        walletId: recurringModel.wallet.id!,
        categoryId: recurringModel.category.id!,
        amount: recurringModel.amount,
        currency: recurringModel.currency,
        startDate: recurringModel.startDate,
        nextDueDate: recurringModel.nextDueDate,
        frequency: recurringModel.frequency.toDbValue(),
        customInterval: Value(recurringModel.customInterval),
        customUnit: Value(recurringModel.customUnit),
        billingDay: Value(recurringModel.billingDay),
        endDate: Value(recurringModel.endDate),
        status: recurringModel.status.toDbValue(),
        autoCreate: Value(recurringModel.autoCreate),
        enableReminder: Value(recurringModel.enableReminder),
        reminderDaysBefore: Value(recurringModel.reminderDaysBefore),
        notes: Value(recurringModel.notes),
        vendorName: Value(recurringModel.vendorName),
        iconName: Value(recurringModel.iconName),
        colorHex: Value(recurringModel.colorHex),
        lastChargedDate: Value(recurringModel.lastChargedDate),
        totalPayments: Value(recurringModel.totalPayments),
      ),
    );
    Log.d('Recurring inserted with id=$id', label: 'recurring');

    // 2. Upload to cloud (if sync available)
    if (_ref != null) {
      final syncService = _ref?.read(supabaseSyncServiceProvider);
      if (syncService != null && syncService.isAuthenticated) {
        try {
          final savedRecurring = await getRecurringById(id);
          if (savedRecurring != null) {
            // Sync dependencies first (category, wallet should already be synced)
            await syncService.uploadRecurring(savedRecurring);
            Log.d('✅ [RECURRING SYNC] Recurring uploaded successfully', label: 'sync');
          }
        } catch (e, stack) {
          Log.e('Failed to upload recurring to cloud: $e', label: 'sync');
          Log.e('Stack: $stack', label: 'sync');
          // Don't rethrow - local save succeeded
        }
      }
    }

    return id;
  }

  /// Update an existing recurring payment
  Future<bool> updateRecurring(RecurringModel recurringModel) async {
    if (recurringModel.id == null) return false;
    Log.d('updateRecurring → ${recurringModel.name}', label: 'recurring');

    // 1. Update local database
    final count = await (update(recurrings)..where((r) => r.id.equals(recurringModel.id!)))
        .write(
          RecurringsCompanion(
            cloudId: Value(recurringModel.cloudId),
            name: Value(recurringModel.name),
            description: Value(recurringModel.description),
            walletId: Value(recurringModel.wallet.id!),
            categoryId: Value(recurringModel.category.id!),
            amount: Value(recurringModel.amount),
            currency: Value(recurringModel.currency),
            startDate: Value(recurringModel.startDate),
            nextDueDate: Value(recurringModel.nextDueDate),
            frequency: Value(recurringModel.frequency.toDbValue()),
            customInterval: Value(recurringModel.customInterval),
            customUnit: Value(recurringModel.customUnit),
            billingDay: Value(recurringModel.billingDay),
            endDate: Value(recurringModel.endDate),
            status: Value(recurringModel.status.toDbValue()),
            autoCreate: Value(recurringModel.autoCreate),
            enableReminder: Value(recurringModel.enableReminder),
            reminderDaysBefore: Value(recurringModel.reminderDaysBefore),
            notes: Value(recurringModel.notes),
            vendorName: Value(recurringModel.vendorName),
            iconName: Value(recurringModel.iconName),
            colorHex: Value(recurringModel.colorHex),
            lastChargedDate: Value(recurringModel.lastChargedDate),
            totalPayments: Value(recurringModel.totalPayments),
            updatedAt: Value(DateTime.now()),
          ),
        );
    final success = count > 0;
    Log.d('updateRecurring success=$success', label: 'recurring');

    // 2. Upload to cloud (if sync available)
    if (success && _ref != null) {
      final syncService = _ref?.read(supabaseSyncServiceProvider);
      if (syncService != null && syncService.isAuthenticated) {
        try {
          await syncService.uploadRecurring(recurringModel);
          Log.d('✅ [RECURRING SYNC] Recurring update uploaded successfully', label: 'sync');
        } catch (e, stack) {
          Log.e('Failed to upload recurring update to cloud: $e', label: 'sync');
          Log.e('Stack: $stack', label: 'sync');
          // Don't rethrow - local update succeeded
        }
      }
    }

    return success;
  }

  /// Delete a recurring payment
  Future<int> deleteRecurring(int id) async {
    Log.d('deleteRecurring → id=$id', label: 'recurring');

    // 1. Get recurring to retrieve cloudId
    final recurring = await (select(recurrings)..where((r) => r.id.equals(id)))
        .getSingleOrNull();

    // 2. Delete from local database
    final count = await (delete(recurrings)..where((r) => r.id.equals(id))).go();
    Log.d('deleteRecurring deleted $count row(s)', label: 'recurring');

    // 3. Delete from cloud (if sync available and has cloudId)
    if (count > 0 && _ref != null && recurring != null && recurring.cloudId != null) {
      final syncService = _ref?.read(supabaseSyncServiceProvider);
      if (syncService != null && syncService.isAuthenticated) {
        try {
          await syncService.deleteRecurringFromCloud(recurring.cloudId!);
          Log.d('✅ [RECURRING SYNC] Recurring deleted from cloud', label: 'sync');
        } catch (e, stack) {
          Log.e('Failed to delete recurring from cloud: $e', label: 'sync');
          Log.e('Stack: $stack', label: 'sync');
          // Don't rethrow - local delete succeeded
        }
      }
    }

    return count;
  }

  /// Pause a recurring payment
  Future<bool> pauseRecurring(int id) {
    return (update(recurrings)..where((r) => r.id.equals(id)))
        .write(
          RecurringsCompanion(
            status: Value(RecurringStatus.paused.toDbValue()),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((count) => count > 0);
  }

  /// Resume a paused recurring payment
  Future<bool> resumeRecurring(int id) {
    return (update(recurrings)..where((r) => r.id.equals(id)))
        .write(
          RecurringsCompanion(
            status: Value(RecurringStatus.active.toDbValue()),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((count) => count > 0);
  }

  /// Cancel a recurring payment
  Future<bool> cancelRecurring(int id) {
    return (update(recurrings)..where((r) => r.id.equals(id)))
        .write(
          RecurringsCompanion(
            status: Value(RecurringStatus.cancelled.toDbValue()),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((count) => count > 0);
  }

  /// Mark a recurring payment as expired
  Future<bool> expireRecurring(int id) {
    return (update(recurrings)..where((r) => r.id.equals(id)))
        .write(
          RecurringsCompanion(
            status: Value(RecurringStatus.expired.toDbValue()),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((count) => count > 0);
  }

  /// Process payment for a recurring (updates next due date and total payments)
  Future<bool> processPayment(int id, DateTime nextDueDate) async {
    // First get current recurring to increment totalPayments
    final current = await (select(recurrings)..where((r) => r.id.equals(id))).getSingleOrNull();
    if (current == null) return false;

    return (update(recurrings)..where((r) => r.id.equals(id)))
        .write(
          RecurringsCompanion(
            nextDueDate: Value(nextDueDate),
            lastChargedDate: Value(DateTime.now()),
            totalPayments: Value(current.totalPayments + 1),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((count) => count > 0);
  }

  /// Get total monthly commitment for a wallet
  Future<double> getTotalMonthlyCommitment(int walletId) async {
    final recurrings = await (select(this.recurrings)
          ..where((r) => r.walletId.equals(walletId))
          ..where((r) => r.status.equals(RecurringStatus.active.toDbValue())))
        .get();

    final recurringModels = await _mapRecurrings(recurrings);
    return recurringModels.totalMonthlyCost;
  }

  /// Get all recurring payments (for backup)
  Future<List<Recurring>> getAllRecurrings() {
    return select(recurrings).get();
  }

  /// Upsert recurring payment
  Future<int> upsertRecurring(RecurringModel recurringModel) {
    if (recurringModel.id != null) {
      return updateRecurring(recurringModel).then((success) =>
        success ? recurringModel.id! : -1
      );
    } else {
      return addRecurring(recurringModel);
    }
  }
}
