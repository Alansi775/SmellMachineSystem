/// ChangeNotifier to manage locale switching at runtime.
///
/// This provider allows the app to change language on-the-fly without restart.
/// Language preference is persisted in SharedPreferences.
///
/// TODO: Implement locale switching and persistence logic
import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _preferenceKey = 'preferred_locale';
  static const String _defaultLocaleCode = 'tr';

  // TODO: Initialize from SharedPreferences
  String _localeCode = _defaultLocaleCode;

  String get localeCode => _localeCode;

  Locale get locale {
    final parts = _localeCode.split('_');
    return parts.length > 1
        ? Locale(parts[0], parts[1])
        : Locale(parts[0]);
  }

  /// Switches the app locale and persists the choice.
  /// Valid codes: 'en', 'tr'
  Future<void> setLocale(String localeCode) async {
    // TODO: Validate localeCode
    // TODO: Save to SharedPreferences
    // TODO: Notify listeners
    if (_localeCode != localeCode) {
      _localeCode = localeCode;
      notifyListeners();
    }
  }

  /// Resets locale to system default.
  Future<void> resetLocale() async {
    // TODO: Clear SharedPreferences
    // TODO: Notify listeners
  }
}
