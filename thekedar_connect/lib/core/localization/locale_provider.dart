import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui' as ui;

// List of initially supported locales
final supportedLocales = [
  const Locale('en'), // English
  const Locale('hi'), // Hindi
  const Locale('ta'), // Tamil
  const Locale('te'), // Telugu
  const Locale('bn'), // Bengali
  const Locale('mr'), // Marathi
  const Locale('gu'), // Gujarati
  const Locale('kn'), // Kannada
  const Locale('ml'), // Malayalam
  const Locale('pa'), // Punjabi
  const Locale('or'), // Odia
  const Locale('ur'), // Urdu
];

class LocaleState {
  final Locale locale;
  final bool hasSelectedLanguage;

  LocaleState({
    required this.locale,
    required this.hasSelectedLanguage,
  });

  LocaleState copyWith({
    Locale? locale,
    bool? hasSelectedLanguage,
  }) {
    return LocaleState(
      locale: locale ?? this.locale,
      hasSelectedLanguage: hasSelectedLanguage ?? this.hasSelectedLanguage,
    );
  }
}

class LocaleNotifier extends Notifier<LocaleState> {
  static const String _langKey = 'preferred_language';
  static const String _hasSelectedKey = 'has_selected_language';

  @override
  LocaleState build() {
    _initLocale();
    return LocaleState(
      locale: const Locale('en'),
      hasSelectedLanguage: false,
    );
  }

  Future<void> _initLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSelected = prefs.getBool(_hasSelectedKey) ?? false;
    final cachedLang = prefs.getString(_langKey);

    Locale resolvedLocale = const Locale('en');

    if (cachedLang != null) {
      resolvedLocale = Locale(cachedLang);
    } else {
      // System language detection fallback
      final systemLocale = ui.PlatformDispatcher.instance.locale.languageCode;
      final isSupported = supportedLocales.any((loc) => loc.languageCode == systemLocale);
      if (isSupported) {
        resolvedLocale = Locale(systemLocale);
      }
    }

    state = LocaleState(
      locale: resolvedLocale,
      hasSelectedLanguage: hasSelected,
    );

    // Sync to database if user is logged in
    _syncToDatabase(resolvedLocale.languageCode, 'device');
  }

  Future<void> setLocale(Locale locale, {required String source}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, locale.languageCode);
    await prefs.setBool(_hasSelectedKey, true);

    state = state.copyWith(
      locale: locale,
      hasSelectedLanguage: true,
    );

    // Sync to database
    await _syncToDatabase(locale.languageCode, source);
  }

  Future<void> _syncToDatabase(String langCode, String source) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('users').update({
          'preferred_language': langCode,
          'language_updated_at': DateTime.now().toUtc().toIso8601String(),
          'language_source': source,
        }).eq('id', user.id);
      }
    } catch (e) {
      debugPrint('Error syncing language to Supabase: $e');
    }
  }

  // Clear language preference on logout if needed
  Future<void> clearPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_langKey);
    await prefs.remove(_hasSelectedKey);
    state = LocaleState(
      locale: const Locale('en'),
      hasSelectedLanguage: false,
    );
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, LocaleState>(() {
  return LocaleNotifier();
});

// Helper model to show language selections
class LanguageModel {
  final String nativeName;
  final String englishName;
  final String code;
  final String flag;

  const LanguageModel({
    required this.nativeName,
    required this.englishName,
    required this.code,
    required this.flag,
  });
}

const List<LanguageModel> languageList = [
  LanguageModel(flag: '🇮🇳', nativeName: 'हिन्दी', englishName: 'Hindi', code: 'hi'),
  LanguageModel(flag: '🇺🇸', nativeName: 'English', englishName: 'English', code: 'en'),
  LanguageModel(flag: '🇮🇳', nativeName: 'தமிழ்', englishName: 'Tamil', code: 'ta'),
  LanguageModel(flag: '🇮🇳', nativeName: 'తెలుగు', englishName: 'Telugu', code: 'te'),
  LanguageModel(flag: '🇮🇳', nativeName: 'বাংলা', englishName: 'Bengali', code: 'bn'),
  LanguageModel(flag: '🇮🇳', nativeName: 'मराठी', englishName: 'Marathi', code: 'mr'),
  LanguageModel(flag: '🇮🇳', nativeName: 'ગુજરાતી', englishName: 'Gujarati', code: 'gu'),
  LanguageModel(flag: '🇮🇳', nativeName: 'ಕನ್ನಡ', englishName: 'Kannada', code: 'kn'),
  LanguageModel(flag: '🇮🇳', nativeName: 'മലയാളம்', englishName: 'Malayalam', code: 'ml'),
  LanguageModel(flag: '🇮🇳', nativeName: 'ਪੰਜਾਬੀ', englishName: 'Punjabi', code: 'pa'),
  LanguageModel(flag: '🇮🇳', nativeName: 'ଓଡ଼ିଆ', englishName: 'Odia', code: 'or'),
  LanguageModel(flag: '🇵🇰', nativeName: 'اردو', englishName: 'Urdu', code: 'ur'),
];
