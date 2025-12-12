import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to manage selected month/year for dashboard
class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    // Default to current month
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void setMonth(DateTime month) => state = month;
}

final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, DateTime>(
  SelectedMonthNotifier.new,
);
