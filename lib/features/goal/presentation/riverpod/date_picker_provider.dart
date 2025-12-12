import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoalDateNotifier extends Notifier<List<DateTime?>> {
  @override
  List<DateTime?> build() => [DateTime.now()];

  void setDates(List<DateTime?> dates) => state = dates;
}

final datePickerProvider = NotifierProvider<GoalDateNotifier, List<DateTime?>>(
  GoalDateNotifier.new,
);
