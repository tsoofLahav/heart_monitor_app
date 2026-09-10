import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted app language (English / Hebrew) with live listeners for MaterialApp.
class LocaleController extends ChangeNotifier {
  LocaleController._();
  static final LocaleController instance = LocaleController._();

  static const _prefsKey = 'app_locale_code';

  Locale _locale = const Locale('en');
  bool _ready = false;
  bool _hasChosenLocale = false;

  Locale get locale => _locale;
  bool get isReady => _ready;
  bool get isHebrew => _locale.languageCode == 'he';

  /// False until the user picks a language on first launch (or in Profile).
  bool get hasChosenLocale => _hasChosenLocale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == 'he' || code == 'en') {
      _locale = Locale(code!);
      _hasChosenLocale = true;
    } else {
      _hasChosenLocale = false;
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode != 'en' && locale.languageCode != 'he') return;
    final changed = _locale.languageCode != locale.languageCode;
    final firstChoice = !_hasChosenLocale;
    _locale = locale;
    _hasChosenLocale = true;
    if (changed || firstChoice) notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}
