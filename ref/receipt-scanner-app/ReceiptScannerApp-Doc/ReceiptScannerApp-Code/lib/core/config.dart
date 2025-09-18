import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get geminiApiKey {
    return dotenv.env['GEMINI_API_KEY'] ??
        (throw Exception('GEMINI_API_KEY not found in .env'));
  }
  // static Uri get geminiBaseUrl {
  //   return Uri.parse(
  //     'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey',
  //   );
  // }
}