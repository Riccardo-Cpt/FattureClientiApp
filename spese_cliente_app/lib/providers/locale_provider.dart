import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _key = 'language_code';

  final SharedPreferences? _prefs;
  Locale _locale;

  LocaleProvider(this._prefs, {Locale? initial}) : _locale = initial ?? const Locale('en');

  /// Restores the saved language; on first launch uses Italian when the
  /// device language is Italian, English otherwise.
  factory LocaleProvider.fromPrefs(SharedPreferences prefs, Locale deviceLocale) {
    final saved = prefs.getString(_key);
    final code = saved ?? (deviceLocale.languageCode == 'it' ? 'it' : 'en');
    return LocaleProvider(prefs, initial: Locale(code));
  }

  Locale get locale => _locale;

  Future<void> setLocale(Locale locale) async {
    if (locale == _locale) return;
    _locale = locale;
    notifyListeners();
    await _prefs?.setString(_key, locale.languageCode);
  }
}
