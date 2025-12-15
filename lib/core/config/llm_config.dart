// LLM Configuration
// Uses environment variables for API keys
// Supports: OpenAI, Gemini, and self-hosted vLLM/Ollama (OpenAI-compatible)

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supported AI providers
enum AIProvider {
  openai,
  gemini,
  custom, // vLLM, Ollama, or any OpenAI-compatible endpoint
}

class LLMDefaultConfig {
  // Get AI provider from environment (openai, gemini, or custom)
  static String get provider {
    try {
      return dotenv.env['AI_PROVIDER'] ?? 'openai';
    } catch (e) {
      return 'openai';
    }
  }

  /// Parse provider string to enum
  static AIProvider get providerEnum {
    switch (provider.toLowerCase()) {
      case 'gemini':
        return AIProvider.gemini;
      case 'custom':
      case 'vllm':
      case 'ollama':
        return AIProvider.custom;
      default:
        return AIProvider.openai;
    }
  }

  // OpenAI Configuration
  static String get apiKey {
    try {
      return dotenv.env['OPENAI_API_KEY'] ?? '';
    } catch (e) {
      return '';
    }
  }

  static String get model {
    try {
      return dotenv.env['OPENAI_MODEL'] ?? 'gpt-4o-mini';
    } catch (e) {
      return 'gpt-4o-mini';
    }
  }

  // Gemini Configuration
  static String get geminiApiKey {
    try {
      return dotenv.env['GEMINI_API_KEY'] ?? '';
    } catch (e) {
      return '';
    }
  }

  static String get geminiModel {
    try {
      return dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash';
    } catch (e) {
      return 'gemini-2.5-flash';
    }
  }

  // Custom/Self-hosted LLM Configuration (vLLM, Ollama, etc.)
  // These use OpenAI-compatible API format
  // IMPORTANT: For mobile apps, user MUST set CUSTOM_LLM_ENDPOINT in .env
  // to a publicly accessible URL (not localhost!)

  // Default endpoint for Bexly Free AI (DOS AI vLLM server)
  static const String _defaultBexlyFreeEndpoint = 'https://api.dos.ai/v1';

  static String get customEndpoint {
    try {
      // Try CUSTOM_LLM_ENDPOINT first, then fall back to BEXLY_FREE_AI_URL
      final envEndpoint = dotenv.env['CUSTOM_LLM_ENDPOINT'];
      if (envEndpoint != null && envEndpoint.isNotEmpty) {
        return envEndpoint;
      }
      // Fallback to Bexly Free AI URL
      final bexlyFreeUrl = dotenv.env['BEXLY_FREE_AI_URL'];
      if (bexlyFreeUrl != null && bexlyFreeUrl.isNotEmpty) {
        return bexlyFreeUrl;
      }
      // Fallback to default Bexly Free AI endpoint
      return _defaultBexlyFreeEndpoint;
    } catch (e) {
      return _defaultBexlyFreeEndpoint;
    }
  }

  // Default API key for Bexly Free AI
  static const String _defaultBexlyFreeApiKey = 'bexly-free-tier';

  static String get customApiKey {
    try {
      // Try CUSTOM_LLM_API_KEY first, then fall back to BEXLY_FREE_AI_KEY
      final customKey = dotenv.env['CUSTOM_LLM_API_KEY'];
      if (customKey != null && customKey.isNotEmpty) {
        return customKey;
      }
      final bexlyFreeKey = dotenv.env['BEXLY_FREE_AI_KEY'];
      if (bexlyFreeKey != null && bexlyFreeKey.isNotEmpty) {
        return bexlyFreeKey;
      }
      // Fallback to default Bexly Free AI key
      return _defaultBexlyFreeApiKey;
    } catch (e) {
      return _defaultBexlyFreeApiKey;
    }
  }

  // Default model for Bexly Free AI (DOS AI vLLM server)
  static const String _defaultBexlyFreeModel = 'Qwen/Qwen3-VL-30B-A3B-Instruct';

  static String get customModel {
    try {
      // Try CUSTOM_LLM_MODEL first, then fall back to BEXLY_FREE_AI_MODEL
      final customModel = dotenv.env['CUSTOM_LLM_MODEL'];
      if (customModel != null && customModel.isNotEmpty) {
        return customModel;
      }
      final bexlyFreeModel = dotenv.env['BEXLY_FREE_AI_MODEL'];
      if (bexlyFreeModel != null && bexlyFreeModel.isNotEmpty) {
        return bexlyFreeModel;
      }
      // Fallback to default Bexly Free AI model
      return _defaultBexlyFreeModel;
    } catch (e) {
      return _defaultBexlyFreeModel;
    }
  }

  /// Check if custom endpoint is configured (from env variable)
  static bool get hasCustomEndpoint {
    try {
      final envEndpoint = dotenv.env['CUSTOM_LLM_ENDPOINT'];
      if (envEndpoint != null && envEndpoint.isNotEmpty) {
        return true;
      }
      final bexlyFreeUrl = dotenv.env['BEXLY_FREE_AI_URL'];
      return bexlyFreeUrl != null && bexlyFreeUrl.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}