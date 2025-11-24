import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

import 'prefs_keys.dart';

class LanguageOption {
  const LanguageOption({required this.code, required this.label});

  final String code;
  final String label;
}

/// Central place to manage supported interface/translation languages.
class LanguagePreferences {
  static const fallbackLanguageCode = 'en-US';

  static const supportedLanguages = <LanguageOption>[
    LanguageOption(code: 'en-US', label: 'English'),
    LanguageOption(code: 'zh-CN', label: '简体中文'),
    LanguageOption(code: 'es-ES', label: 'Español'),
    LanguageOption(code: 'fr-FR', label: 'Français'),
  ];

  static bool isSupported(String code) =>
      supportedLanguages.any((lang) => lang.code == code);

  static String labelFor(String code) => supportedLanguages
      .firstWhere(
        (lang) => lang.code == code,
        orElse: () => const LanguageOption(
          code: fallbackLanguageCode,
          label: 'English',
        ),
      )
      .label;

  static Future<String> loadPreferredLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(PrefsKeys.preferredLanguageCode);
    if (stored != null && isSupported(stored)) {
      return stored;
    }

    final guessed = _guessFromDeviceLocale();
    await prefs.setString(PrefsKeys.preferredLanguageCode, guessed);
    return guessed;
  }

  static Future<void> savePreferredLanguageCode(String code) async {
    final normalized = isSupported(code) ? code : fallbackLanguageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.preferredLanguageCode, normalized);
  }

  static Future<String?> loadPreferredTimeZone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefsKeys.preferredTimeZone);
  }

  static Future<void> savePreferredTimeZone(String? timeZone) async {
    final prefs = await SharedPreferences.getInstance();
    if (timeZone == null || timeZone.isEmpty) {
      await prefs.remove(PrefsKeys.preferredTimeZone);
    } else {
      await prefs.setString(PrefsKeys.preferredTimeZone, timeZone);
    }
  }

  static String _guessFromDeviceLocale() {
    final primaryLocale = PlatformDispatcher.instance.locale;
    final matches = _matchLocale(primaryLocale);
    if (matches != null) return matches;

    for (final locale in PlatformDispatcher.instance.locales) {
      final alt = _matchLocale(locale);
      if (alt != null) return alt;
    }

    return fallbackLanguageCode;
  }

  static String? _matchLocale(Locale locale) {
    final lang = locale.languageCode.toLowerCase();
    switch (lang) {
      case 'en':
        return 'en-US';
      case 'zh':
        return 'zh-CN';
      case 'es':
        return 'es-ES';
      case 'fr':
        return 'fr-FR';
      default:
        return null;
    }
  }
}
