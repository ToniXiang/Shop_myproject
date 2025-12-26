import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.system;
  bool _isInitialized = false;

  AppThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;

  ThemeMode get currentThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
  String getThemeName(){
    switch (_themeMode) {
      case AppThemeMode.light:
        return '淺色模式';
      case AppThemeMode.dark:
        return '深色模式';
      case AppThemeMode.system:
        return '系統預設';
    }
  }
  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  void setThemeMode(AppThemeMode themeMode) {
    if (_themeMode != themeMode) {
      _themeMode = themeMode;
      _saveThemeToPrefs();
      notifyListeners();
    }
  }
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt('theme_mode') ?? 2;
      _themeMode = AppThemeMode.values[themeIndex];
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _themeMode = AppThemeMode.system;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _saveThemeToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_mode', _themeMode.index);
    } catch (e) {
      debugPrint('Failed to save theme preference: $e');
    }
  }
}