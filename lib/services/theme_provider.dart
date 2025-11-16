import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app's theme mode (light, dark, or system).
///
/// Use [ChangeNotifierProvider] to provide this to the widget tree.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  static const String _themeKey = 'themeMode';

  ThemeProvider() {
    _loadThemeMode();
  }

  /// Loads the saved theme mode from SharedPreferences.
  /// Defaults to [ThemeMode.system] if no preference is found.
  void _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);

    switch (savedTheme) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
        break;
    }
    notifyListeners();
  }

  /// Updates the theme mode and saves the preference to SharedPreferences.
  void setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_themeKey, mode.name);
  }
}