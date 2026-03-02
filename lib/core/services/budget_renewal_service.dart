import 'package:bexly/core/database/daos/budget_dao.dart';
import 'package:bexly/core/utils/logger.dart';

/// Auto-creates routine budgets for the current period (weekly or monthly).
///
/// Called from LifecycleManager on app start. For each routine budget whose
/// period has ended, creates a new budget record for the current period
/// with the same wallet, category, amount, and routine settings.
class BudgetRenewalService {
  static const _label = 'BudgetRenewal';

  final BudgetDao _budgetDao;

  BudgetRenewalService(this._budgetDao);

  Future<void> createDueRoutineBudgets() async {
    try {
      final now = DateTime.now();

      final routineBudgets = await _budgetDao.getRoutineBudgets();
      if (routineBudgets.isEmpty) return;

      Log.d('Found ${routineBudgets.length} routine budgets', label: _label);

      // Group by (walletId, categoryId, routinePeriod) → keep only the latest endDate per group
      final latestByGroup = <String, _RoutineBudgetInfo>{};
      for (final b in routineBudgets) {
        final period = b.routinePeriod ?? 'monthly';
        final key = '${b.walletId}_${b.categoryId}_$period';
        final existing = latestByGroup[key];
        if (existing == null || b.endDate.isAfter(existing.endDate)) {
          latestByGroup[key] = _RoutineBudgetInfo(
            id: b.id,
            walletId: b.walletId,
            categoryId: b.categoryId,
            amount: b.amount,
            endDate: b.endDate,
            routinePeriod: period,
          );
        }
      }

      int created = 0;
      for (final info in latestByGroup.values) {
        final DateTime periodStart;
        final DateTime periodEnd;

        if (info.routinePeriod == 'weekly') {
          // Current week: Monday → Sunday
          periodStart = now.subtract(Duration(days: now.weekday - 1));
          periodEnd = periodStart.add(const Duration(days: 6));
          // Normalize to midnight
          final normalizedStart = DateTime(periodStart.year, periodStart.month, periodStart.day);
          final normalizedEnd = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);

          // Only create if the latest budget ended before this week
          if (!info.endDate.isBefore(normalizedStart)) continue;

          // Check if budget already exists for this week
          final existing = await _budgetDao.getRoutineBudgetForWeek(
            info.walletId,
            info.categoryId,
            normalizedStart,
            normalizedEnd,
          );
          if (existing != null) continue;

          // Create for current week
          await _createRenewalBudget(info, normalizedStart, normalizedEnd);
          created++;
        } else {
          // Monthly (default)
          periodStart = DateTime(now.year, now.month, 1);
          periodEnd = DateTime(now.year, now.month + 1, 0);

          // Only create if the latest budget ended before this month
          if (!info.endDate.isBefore(periodStart)) continue;

          // Check if budget already exists for this month
          final existing = await _budgetDao.getRoutineBudgetForMonth(
            info.walletId,
            info.categoryId,
            now.year,
            now.month,
          );
          if (existing != null) continue;

          // Create for current month
          await _createRenewalBudget(info, periodStart, periodEnd);
          created++;
        }
      }

      if (created > 0) {
        Log.i('Created $created routine budgets for current period', label: _label);
      }
    } catch (e, stack) {
      Log.e('Error creating routine budgets: $e', label: _label);
      Log.e('Stack: $stack', label: _label);
    }
  }

  Future<void> _createRenewalBudget(
    _RoutineBudgetInfo info,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final budgetModel = await _budgetDao.getBudgetById(info.id);
    if (budgetModel == null) return;

    await _budgetDao.addBudget(budgetModel.copyWith(
      id: null,
      cloudId: null,
      startDate: startDate,
      endDate: endDate,
      createdAt: null,
      updatedAt: null,
    ));

    Log.i(
      'Auto-created ${info.routinePeriod} budget: '
      '${budgetModel.category.title} ${budgetModel.amount}',
      label: _label,
    );
  }
}

class _RoutineBudgetInfo {
  final int id;
  final int walletId;
  final int categoryId;
  final double amount;
  final DateTime endDate;
  final String routinePeriod;

  _RoutineBudgetInfo({
    required this.id,
    required this.walletId,
    required this.categoryId,
    required this.amount,
    required this.endDate,
    required this.routinePeriod,
  });
}
