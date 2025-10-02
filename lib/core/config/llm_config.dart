// LLM Configuration
// Uses environment variables for API keys

import 'package:flutter_dotenv/flutter_dotenv.dart';

class LLMDefaultConfig {
  // Get AI provider from environment (openai or gemini)
  static String get provider {
    try {
      return dotenv.env['AI_PROVIDER'] ?? 'openai';
    } catch (e) {
      return 'openai';
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

  // For custom LLM only
  static const String? customEndpoint = null;
}