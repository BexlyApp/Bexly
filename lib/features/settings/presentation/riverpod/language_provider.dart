import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
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
  Language(
    code: 'zh',
    name: 'Chinese',
    nativeName: '中文',
    flag: '🇨🇳',
  ),
  Language(
    code: 'fr',
    name: 'French',
    nativeName: 'Français',
    flag: '🇫🇷',
  ),
  Language(
    code: 'th',
    name: 'Thai',
    nativeName: 'ไทย',
    flag: '🇹🇭',
  ),
  Language(
    code: 'id',
    name: 'Indonesian',
    nativeName: 'Bahasa Indonesia',
    flag: '🇮🇩',
  ),
  Language(
    code: 'es',
    name: 'Spanish',
    nativeName: 'Español',
    flag: '🇪🇸',
  ),
  Language(
    code: 'pt',
    name: 'Portuguese',
    nativeName: 'Português',
    flag: '🇧🇷',
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
    final savedLanguageCode = prefs.getString(_prefsKey);

    // If user has never selected a language, auto-detect from device
    if (savedLanguageCode == null) {
      final deviceLanguage = _detectDeviceLanguage();
      state = deviceLanguage;
      // Sync Intl locale
      Intl.defaultLocale = deviceLanguage.code;
      // Save the detected language so we don't detect again
      await prefs.setString(_prefsKey, deviceLanguage.code);
      return;
    }

    final language = availableLanguages.firstWhere(
      (lang) => lang.code == savedLanguageCode,
      orElse: () => availableLanguages[0],
    );

    state = language;
    // Sync Intl locale
    Intl.defaultLocale = language.code;
  }

  /// Detect language from device settings
  /// Priority: Device locale → Fallback to English
  Language _detectDeviceLanguage() {
    // Get device locale from platform dispatcher
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final deviceLanguageCode = deviceLocale.languageCode;

    // Find matching language in available languages
    final matchedLanguage = availableLanguages.cast<Language?>().firstWhere(
      (lang) => lang?.code == deviceLanguageCode,
      orElse: () => null,
    );

    // Return matched language or default to English
    return matchedLanguage ?? availableLanguages[0];
  }

  Future<void> setLanguage(Language language) async {
    state = language;
    // Sync Intl locale for date/time formatting
    Intl.defaultLocale = language.code;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language.code);
  }
}

// Locale provider for app localization
final localeProvider = Provider<Locale>((ref) {
  final language = ref.watch(languageProvider);
  return Locale(language.code);
});