import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/features/ai_chat/data/services/llm_service_interface.dart';

class ApiConfig {
  static const String _llmProviderKey = 'llm_provider';
  static const String _llmApiKeyKey = 'llm_api_key';
  static const String _llmModelKey = 'llm_model';
  static const String _customLLMEndpointKey = 'custom_llm_endpoint';

  // Legacy keys for compatibility
  static const String _claudeApiKeyKey = 'claude_api_key';

  // LLM Provider management
  static Future<void> setLLMProvider(LLMProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_llmProviderKey, provider.name);
  }

  static Future<LLMProvider?> getLLMProvider() async {
    final prefs = await SharedPreferences.getInstance();
    final providerName = prefs.getString(_llmProviderKey);
    if (providerName == null) return null;

    try {
      return LLMProvider.values.firstWhere((p) => p.name == providerName);
    } catch (e) {
      return null;
    }
  }

  // API Key management
  static Future<void> saveLLMApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_llmApiKeyKey, apiKey);
  }

  static Future<String?> getLLMApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_llmApiKeyKey);
  }

  // Model management
  static Future<void> setLLMModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_llmModelKey, model);
  }

  static Future<String?> getLLMModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_llmModelKey);
  }

  // Custom endpoint for custom LLMs
  static Future<void> setCustomLLMEndpoint(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customLLMEndpointKey, endpoint);
  }

  static Future<String?> getCustomLLMEndpoint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customLLMEndpointKey);
  }

  // Clear all LLM settings
  static Future<void> clearLLMConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_llmProviderKey);
    await prefs.remove(_llmApiKeyKey);
    await prefs.remove(_llmModelKey);
    await prefs.remove(_customLLMEndpointKey);
  }

  // Legacy support for old Claude key
  static Future<String?> getClaudeApiKey() async {
    return await getLLMApiKey();
  }

  static Future<String?> getOpenAIApiKey() async {
    return await getLLMApiKey();
  }
}

// Provider for LLM configuration
final llmApiKeyProvider = FutureProvider<String?>((ref) async {
  return await ApiConfig.getLLMApiKey();
});

// Legacy provider for compatibility
final claudeApiKeyProvider = llmApiKeyProvider;