import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/features/recurring/data/model/recurring_suggestion.dart';
import 'package:bexly/features/recurring/services/recurring_detection_service.dart';

/// Tracks dismissed suggestion names so they don't reappear.
class DismissedSuggestionsNotifier extends Notifier<Set<String>> {
  static const String _prefsKey = 'dismissed_recurring_suggestions';

  @override
  Set<String> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];
    state = list.toSet();
  }

  Future<void> dismiss(String name) async {
    state = {...state, name.toLowerCase().trim()};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, state.toList());
  }

  Future<void> clearAll() async {
    state = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

final dismissedSuggestionsProvider =
    NotifierProvider<DismissedSuggestionsNotifier, Set<String>>(
  DismissedSuggestionsNotifier.new,
);

/// Fetches AI-detected recurring suggestions, filtered by dismissed items.
final recurringSuggestionsProvider =
    FutureProvider.autoDispose<List<RecurringSuggestion>>((ref) async {
  final transactionDao = ref.read(transactionDaoProvider);
  final recurringDao = ref.read(recurringDaoProvider);
  final dismissed = ref.watch(dismissedSuggestionsProvider);

  final service = RecurringDetectionService(
    transactionDao: transactionDao,
    recurringDao: recurringDao,
  );

  final suggestions = await service.detectPatterns();

  // Filter out dismissed suggestions
  return suggestions
      .where((s) => !dismissed.contains(s.name.toLowerCase().trim()))
      .toList();
});
