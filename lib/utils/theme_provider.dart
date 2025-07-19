import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/colors.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  ThemeProvider() {
    _loadTheme();
  }

  bool get isDarkMode => _isDarkMode;

  ThemeData get themeData => _isDarkMode ? darkTheme : lightTheme;

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _saveTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  static final lightTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.primary(false),
    primaryColor: AppColors.primary(false),
    colorScheme: ColorScheme.light(
      primary: AppColors.primary(false),
      secondary: AppColors.secondary(false),
      onPrimary: AppColors.black(false),
      onSecondary: AppColors.black(false),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: AppColors.black(false)),
      bodyMedium: TextStyle(color: AppColors.black(false)),
      headlineSmall: TextStyle(color: AppColors.mainFontColor(false), fontWeight: FontWeight.bold),
    ),
    iconTheme: IconThemeData(color: AppColors.black(false)),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary(false),
      foregroundColor: AppColors.mainFontColor(false),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.buttonColor(false),
      foregroundColor: AppColors.white(false),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: AppColors.buttonColor(false),
      textTheme: ButtonTextTheme.primary,
    ),
  );

  static final darkTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.primary(true),
    primaryColor: AppColors.primary(true),
    colorScheme: ColorScheme.dark(
        primary: AppColors.primary(true),
        secondary: AppColors.secondary(true),
        onPrimary: AppColors.black(true),
    onSecondary: AppColors.black(true),
  ),
      textTheme: TextTheme(
  bodyLarge: TextStyle(color: AppColors.black(true)),
  bodyMedium: TextStyle(color: AppColors.black(true)),
  headlineSmall: TextStyle(color: AppColors.mainFontColor(true), fontWeight: FontWeight.bold),
  ),
  iconTheme: IconThemeData(color: AppColors.black(true)),
  appBarTheme: AppBarTheme(
  backgroundColor: AppColors.primary(true),
  foregroundColor: AppColors.mainFontColor(true),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
  backgroundColor: AppColors.buttonColor(true),
  foregroundColor: AppColors.white(true),
  ),
  buttonTheme: ButtonThemeData(
  buttonColor: AppColors.buttonColor(true),
  textTheme: ButtonTextTheme.primary,
  ),
  );
}