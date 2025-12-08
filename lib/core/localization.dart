import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'localization_data.dart';

// Locale Provider
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en'));

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'en';
    state = Locale(languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    state = locale;
  }
}

// Translations Helper
class AppTranslations {
  static String get(String key, Locale locale) {
    return translations[locale.languageCode]?[key] ??
        translations['en']?[key] ??
        key;
  }
}

// Extension for easier usage
extension TranslationExtension on String {
  String tr(WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return AppTranslations.get(this, locale);
  }
}
