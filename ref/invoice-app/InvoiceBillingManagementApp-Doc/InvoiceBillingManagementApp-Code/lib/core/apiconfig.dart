// DO NOT COMMIT API KEYS TO VERSION CONTROL!
// Use environment variables or secure configuration instead

const String apiKey = String.fromEnvironment('GROQ_API_KEY',
    defaultValue: 'YOUR_API_KEY_HERE'); // Set via --dart-define or .env
const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY',
    defaultValue: 'YOUR_API_KEY_HERE'); // Set via --dart-define or .env

class ApiConstants {
  // API keys should be loaded from environment variables
  static const String apiKey = String.fromEnvironment('GROQ_API_KEY',
      defaultValue: 'YOUR_API_KEY_HERE');
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY',
      defaultValue: 'YOUR_API_KEY_HERE');
}
