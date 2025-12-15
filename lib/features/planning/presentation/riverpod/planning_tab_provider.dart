import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier for controlling the selected tab in PlanningScreen
/// 0 = Budgets tab, 1 = Goals tab
class PlanningTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) {
    state = index;
  }
}

/// Provider for PlanningScreen tab state
final planningTabProvider = NotifierProvider<PlanningTabNotifier, int>(
  PlanningTabNotifier.new,
);
