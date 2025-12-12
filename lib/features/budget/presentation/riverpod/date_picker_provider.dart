import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetDateNotifier extends Notifier<List<DateTime?>> {
  @override
  List<DateTime?> build() => [DateTime.now()];

  void setDates(List<DateTime?> dates) => state = dates;
}

final datePickerProvider = NotifierProvider<BudgetDateNotifier, List<DateTime?>>(
  BudgetDateNotifier.new,
);
