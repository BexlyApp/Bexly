import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Language model
class Language {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}

// Available languages
const List<Language> availableLanguages = [
  Language(
    code: 'en',
    name: 'English',
    nativeName: 'English',
    flag: '🇬🇧',
  ),
  Language(
    code: 'vi',
    name: 'Vietnamese',
    nativeName: 'Tiếng Việt',
    flag: '🇻🇳',
  ),
];

// Language provider
final languageProvider = StateNotifierProvider<LanguageNotifier, Language>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<Language> {
  static const String _prefsKey = 'app_language';

  LanguageNotifier() : super(availableLanguages[0]) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_prefsKey) ?? 'en';

    final language = availableLanguages.firstWhere(
      (lang) => lang.code == languageCode,
      orElse: () => availableLanguages[0],
    );

    state = language;
  }

  Future<void> setLanguage(Language language) async {
    state = language;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language.code);
  }
}

// Locale provider for app localization
final localeProvider = Provider<Locale>((ref) {
  final language = ref.watch(languageProvider);
  return Locale(language.code);
});