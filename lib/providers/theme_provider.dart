import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // Modern Color Palette (Inspired by Movto/Fitness designs)
  static const Color primaryNeon = Color(0xFFD0FF00); // Lime Green
  static const Color secondaryNeon = Color(0xFF00E5FF); // Cyan
  static const Color accentPink = Color(0xFFFF2D55);

  static const Color darkBg = Color(0xFF0A0A0A);
  static const Color darkCard = Color(0xFF1A1A1A);

  static const Color lightBg = Color(0xFFF5F5F7);
  static const Color lightCard = Colors.white;

  ThemeData get currentTheme => isDarkMode ? darkTheme : lightTheme;

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryNeon,
    scaffoldBackgroundColor: darkBg,
    cardColor: darkCard,
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: primaryNeon,
      secondary: secondaryNeon,
      surface: darkCard,
      background: darkBg,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white),
      bodyLarge: TextStyle(fontFamily: 'Cairo', color: Colors.white70),
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryNeon,
    scaffoldBackgroundColor: lightBg,
    cardColor: lightCard,
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primaryNeon,
      secondary: secondaryNeon,
      surface: lightCard,
      background: lightBg,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.black),
      bodyLarge: TextStyle(fontFamily: 'Cairo', color: Colors.black87),
    ),
  );
}
