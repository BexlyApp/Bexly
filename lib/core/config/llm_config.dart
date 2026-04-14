// LLM Configuration
// Uses environment variables for API keys — NO hardcoded secrets
// Supports: OpenAI, Gemini, and self-hosted vLLM/Ollama (OpenAI-compatible)

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  static String get customEndpoint {
    try {
      final envEndpoint = dotenv.env['CUSTOM_LLM_ENDPOINT'];
      if (envEndpoint != null && envEndpoint.isNotEmpty) {
        return envEndpoint;
      }
      final bexlyFreeUrl = dotenv.env['BEXLY_FREE_AI_URL'];
      if (bexlyFreeUrl != null && bexlyFreeUrl.isNotEmpty) {
        return bexlyFreeUrl;
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  static String get customApiKey {
    try {
      final customKey = dotenv.env['CUSTOM_LLM_API_KEY'];
      if (customKey != null && customKey.isNotEmpty) {
        return customKey;
      }
      final bexlyFreeKey = dotenv.env['BEXLY_FREE_AI_KEY'];
      if (bexlyFreeKey != null && bexlyFreeKey.isNotEmpty) {
        return bexlyFreeKey;
      }
      return 'no-key-required';
    } catch (e) {
      return 'no-key-required';
    }
  }

  static String get customModel {
    try {
      final customModel = dotenv.env['CUSTOM_LLM_MODEL'];
      if (customModel != null && customModel.isNotEmpty) {
        return customModel;
      }
      final bexlyFreeModel = dotenv.env['BEXLY_FREE_AI_MODEL'];
      if (bexlyFreeModel != null && bexlyFreeModel.isNotEmpty) {
        return bexlyFreeModel;
      }
      return 'default';
    } catch (e) {
      return 'default';
    }
  }

  /// Timeout for custom LLM (DOS AI) in seconds
  static int get customTimeoutSeconds {
    try {
      final timeout = dotenv.env['DOS_AI_TIMEOUT'];
      if (timeout != null && timeout.isNotEmpty) {
        return int.tryParse(timeout) ?? 5;
      }
      return 5;
    } catch (e) {
      return 5;
    }
  }

  /// Check if custom endpoint is configured
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

  // ==========================================================================
  // Supabase Edge Function Proxy (for OpenAI/Gemini — keeps keys server-side)
  // ==========================================================================

  /// Proxy URL: Supabase Edge Function endpoint for AI requests
  static String get proxyUrl {
    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://dos.supabase.co';
      return '$supabaseUrl/functions/v1/ai-proxy';
    } catch (e) {
      return 'https://dos.supabase.co/functions/v1/ai-proxy';
    }
  }

  /// Current user's Supabase access token for proxy auth
  static String? get proxyAccessToken {
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (e) {
      return null;
    }
  }

  /// Proxy headers with JWT auth
  static Map<String, String>? get proxyHeaders {
    final token = proxyAccessToken;
    if (token == null) return null;
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}
