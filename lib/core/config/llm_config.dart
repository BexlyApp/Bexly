// LLM Configuration
// Reads compile-time constants injected via --dart-define-from-file=.env at build time.
// Secret API keys for 3rd-party providers (OpenAI/Gemini/Claude/Groq) live ONLY in
// the ai-proxy Supabase Edge Function and are never embedded in the client.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Supported AI providers
enum AIProvider {
  openai,
  gemini,
  custom, // vLLM, Ollama, or any OpenAI-compatible endpoint
}

class LLMDefaultConfig {
  // ==========================================================================
  // Provider selection
  // ==========================================================================

  static const String provider = String.fromEnvironment(
    'AI_PROVIDER',
    defaultValue: 'custom',
  );

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

  // ==========================================================================
  // OpenAI / Gemini — keys live in ai-proxy edge function, NOT in client.
  // Public model names can ship with the app.
  // ==========================================================================

  static const String model = String.fromEnvironment(
    'OPENAI_MODEL',
    defaultValue: 'gpt-4o-mini',
  );

  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );

  // ==========================================================================
  // Custom / Self-hosted LLM (DOS AI via vLLM)
  // Endpoint URL and model name are public. The API key, if any, must be
  // delivered via the ai-proxy edge function — do NOT inline in the client.
  // ==========================================================================

  static const String _customEndpoint = String.fromEnvironment(
    'CUSTOM_LLM_ENDPOINT',
  );
  static const String _bexlyFreeUrl = String.fromEnvironment('BEXLY_FREE_AI_URL');

  static String get customEndpoint =>
      _customEndpoint.isNotEmpty ? _customEndpoint : _bexlyFreeUrl;

  static const String _customModel = String.fromEnvironment('CUSTOM_LLM_MODEL');
  static const String _bexlyFreeModel =
      String.fromEnvironment('BEXLY_FREE_AI_MODEL', defaultValue: 'dos-ai');

  static String get customModel =>
      _customModel.isNotEmpty ? _customModel : _bexlyFreeModel;

  /// Timeout for custom LLM (DOS AI) in seconds
  static const int customTimeoutSeconds = int.fromEnvironment(
    'DOS_AI_TIMEOUT',
    defaultValue: 5,
  );

  /// Timeout for custom LLM vision/OCR requests (longer than text)
  static const int customVisionTimeoutSeconds = int.fromEnvironment(
    'DOS_AI_VISION_TIMEOUT',
    defaultValue: 30,
  );

  /// Check if custom endpoint is configured
  static bool get hasCustomEndpoint => customEndpoint.isNotEmpty;

  /// DEPRECATED: returns the user's Supabase JWT for direct DOS AI calls.
  /// Migration path: DOS AI server (api.dos.ai) should verify Supabase JWT,
  /// or all DOS AI calls should be routed through ai-proxy edge function.
  /// Until that migration completes, callers send JWT here as Bearer token.
  static String get customApiKey => proxyAccessToken ?? '';

  // ==========================================================================
  // Supabase Edge Function Proxy
  // All AI calls (OpenAI/Gemini/Claude/Custom) route through this proxy so
  // secret keys stay server-side. The proxy authenticates each request with
  // the user's Supabase JWT.
  // ==========================================================================

  /// Proxy URL: Supabase Edge Function endpoint for AI requests
  static String get proxyUrl => '${SupabaseConfig.url}/functions/v1/ai-proxy';

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
