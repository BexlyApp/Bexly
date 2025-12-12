import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) => state = date;
}

final datePickerProvider = NotifierProvider<TransactionDateNotifier, DateTime>(
  TransactionDateNotifier.new,
);

class FilterDateNotifier extends Notifier<List<DateTime?>> {
  @override
  List<DateTime?> build() => [DateTime.now().subtract(const Duration(days: 5)), DateTime.now()];

  void setDates(List<DateTime?> dates) => state = dates;
}

final filterDatePickerProvider = NotifierProvider<FilterDateNotifier, List<DateTime?>>(
  FilterDateNotifier.new,
);
