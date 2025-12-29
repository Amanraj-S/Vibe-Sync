import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  // --- SEA BLUE PALETTE ---
  static final Color _seaBlueLight = const Color(0xFF0093AF);
  static final Color _seaBlueDark = const Color(0xFF006994);

  // LIGHT THEME
  static final ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: Colors.white,
    primaryColor: _seaBlueDark,
    cardColor: Colors.white,
    dividerColor: Colors.grey[200],
    colorScheme: ColorScheme.light(
      primary: _seaBlueDark,
      secondary: _seaBlueLight,
      surface: Colors.white,
      onSurface: Colors.black87, // Text color
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    iconTheme: const IconThemeData(color: Colors.black87),
  );

  // DARK THEME
  static final ThemeData darkTheme = ThemeData(
    scaffoldBackgroundColor: const Color(0xFF121212), // Standard Dark BG
    primaryColor: _seaBlueLight, // Lighter blue for dark mode visibility
    cardColor: const Color(0xFF1E1E1E), // Slightly lighter grey for cards
    dividerColor: Colors.grey[800],
    colorScheme: ColorScheme.dark(
      primary: _seaBlueLight,
      secondary: _seaBlueDark,
      surface: const Color(0xFF1E1E1E),
      onSurface: Colors.white, // Text color
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
  );

  // --- LOGIC ---
  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme(bool isOn) async {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', isOn);
  }

  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isDark = prefs.getBool('isDarkMode');
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    }
  }
}