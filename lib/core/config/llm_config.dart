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
  static String get customEndpoint {
    try {
      // Default to localhost vLLM endpoint
      return dotenv.env['CUSTOM_LLM_ENDPOINT'] ?? 'http://localhost:8000/v1';
    } catch (e) {
      return 'http://localhost:8000/v1';
    }
  }

  static String get customApiKey {
    try {
      // vLLM doesn't require API key by default, but can be configured
      return dotenv.env['CUSTOM_LLM_API_KEY'] ?? 'no-key-required';
    } catch (e) {
      return 'no-key-required';
    }
  }

  static String get customModel {
    try {
      // Model name as configured in vLLM
      return dotenv.env['CUSTOM_LLM_MODEL'] ?? 'default';
    } catch (e) {
      return 'default';
    }
  }

  /// Check if custom endpoint is configured
  static bool get hasCustomEndpoint {
    final endpoint = customEndpoint;
    return endpoint.isNotEmpty && endpoint != 'http://localhost:8000/v1';
  }
}