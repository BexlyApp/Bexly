import 'package:hooks_riverpod/hooks_riverpod.dart';

// Provider to manage selected month/year for dashboard
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  // Default to current month
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});
