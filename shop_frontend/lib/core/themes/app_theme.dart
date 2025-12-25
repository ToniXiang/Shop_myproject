import 'package:flutter/material.dart';

class AppTheme {

  static const _appBarTheme = AppBarTheme(
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  );
  static const _bottomNavigationBarTheme = BottomNavigationBarThemeData(
    selectedItemColor: Color(0xff0d61ae),
    unselectedItemColor: Color(0xFF938F99),
    selectedLabelStyle: TextStyle(fontSize: 10),
    unselectedLabelStyle: TextStyle(fontSize: 10),
  );
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(0xffcfe6f5),
        brightness: Brightness.light,
        surface: const Color(0xFFFFFFFF),
        onSurface: const Color(0xFF000000),
        surfaceContainer: const Color(0xFFF5F5F5),
        outline: const Color(0xFF938F99),
        primary: const Color(0xff0d61ae),
        onPrimary: const Color(0xFFFFFFFF),
        secondary: const Color(0xffecc45a),
        secondaryContainer: const Color(0xffecc45a),
      ),
      appBarTheme: _appBarTheme,
      bottomNavigationBarTheme: _bottomNavigationBarTheme,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(0xffcfe6f5),
        brightness: Brightness.dark,
        surface: const Color(0xFF1C1B1F),
        onSurface: const Color(0xFFE6E1E6),
        surfaceContainer: const Color(0xFF211F26),
        outline: const Color(0xFF938F99),
        outlineVariant: const Color(0xFF49454E),
        onSurfaceVariant: const Color(0xFFCAC4CF),
        primary: const Color.fromARGB(255, 46, 123, 175),
        onPrimary: const Color(0xFFFFFFFF),
        secondary: const Color(0xffecc45a),
        secondaryContainer: const Color(0xffecc45a),
      ),
      appBarTheme: _appBarTheme,
      bottomNavigationBarTheme: _bottomNavigationBarTheme,
    );
  }
}