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
  static const Color surfaceGlass = Color(0x1AFFFFFF);

  static const Color darkBg = Color(0xFF000000);
  static const Color darkCard = Color(0xFF121212);

  static const Color lightBg = Color(0xFFF2F2F7);
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
      tertiary: accentPink,
      surface: darkCard,
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Colors.white,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, color: Colors.white, fontSize: 32),
      displayMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24),
      bodyLarge: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 16),
      bodyMedium: TextStyle(fontFamily: 'Cairo', color: Colors.white70, fontSize: 14),
      labelLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: primaryNeon),
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
      tertiary: accentPink,
      surface: lightCard,
      onSurface: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Colors.black,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, color: Colors.black, fontSize: 32),
      displayMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.black, fontSize: 24),
      bodyLarge: TextStyle(fontFamily: 'Cairo', color: Colors.black, fontSize: 16),
      bodyMedium: TextStyle(fontFamily: 'Cairo', color: Colors.black54, fontSize: 14),
      labelLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.black87),
    ),
  );
}
