import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/services/subscription/ai_usage_service.dart';

/// Available AI models for the app
enum AIModel {
  dosAI('dos_ai', 'DOSAI', 'Free AI powered by DOS Labs'),
  gemini('gemini', 'Gemini', 'Google Gemini AI'),
  openAI('openai', 'OpenAI', 'OpenAI GPT models');

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
final aiModelProvider = StateNotifierProvider<AIModelNotifier, AIModel>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AIModelNotifier(prefs);
});

class AIModelNotifier extends StateNotifier<AIModel> {
  final SharedPreferences _prefs;

  AIModelNotifier(this._prefs) : super(AIModel.dosAI) {
    _loadModel();
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
