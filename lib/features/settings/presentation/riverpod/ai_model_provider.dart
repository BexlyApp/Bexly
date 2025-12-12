import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/services/subscription/ai_usage_service.dart';

/// Available AI models for the app
enum AIModel {
  dosAI('dos_ai', 'Standard', 'Free AI for all users'),
  gemini('gemini', 'Premium', 'Better accuracy (Plus+)'),
  openAI('openai', 'Flagship', 'Best AI capabilities (Pro)');

  final String key;
  final String displayName;
  final String description;

  const AIModel(this.key, this.displayName, this.description);

  static AIModel fromKey(String key) {
    return AIModel.values.firstWhere(
      (model) => model.key == key,
      orElse: () => AIModel.dosAI,
    );
  }
}

const String _aiModelKey = 'selected_ai_model';

/// Provider for the currently selected AI model
class AIModelNotifier extends Notifier<AIModel> {
  late final SharedPreferences _prefs;

  @override
  AIModel build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    _loadModel();
    return AIModel.dosAI;
  }

  void _loadModel() {
    final savedKey = _prefs.getString(_aiModelKey);
    if (savedKey != null) {
      state = AIModel.fromKey(savedKey);
    }
  }

  Future<void> setModel(AIModel model) async {
    state = model;
    await _prefs.setString(_aiModelKey, model.key);
  }
}

final aiModelProvider = NotifierProvider<AIModelNotifier, AIModel>(
  AIModelNotifier.new,
);
