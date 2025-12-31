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

  // --- SEA BLUE BRAND COLORS ---
  static const Color _seaBlueLight = Color(0xFF0093AF);
  static const Color _seaBlueDark = Color(0xFF006994);

  // --- LIGHT THEME DEFINITION ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light grey for contrast
    primaryColor: _seaBlueDark,
    cardColor: Colors.white,
    dividerColor: Colors.grey[300],
    
    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: _seaBlueDark,
      secondary: _seaBlueLight,
      surface: Colors.white,
      onSurface: Colors.black87,
      onPrimary: Colors.white,
    ),

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
        color: Colors.black87, 
        fontSize: 20, 
        fontWeight: FontWeight.bold
      ),
    ),

    // Input Fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: Colors.grey[500]),
    ),
  );

  // --- DARK THEME DEFINITION ---
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212), // True Dark
    primaryColor: _seaBlueLight,
    cardColor: const Color(0xFF1E1E1E), // Elevated Dark Surface
    dividerColor: Colors.grey[800],

    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: _seaBlueLight,
      secondary: _seaBlueDark,
      surface: Color(0xFF1E1E1E),
      onSurface: Color(0xFFE0E0E0), // Soft White text
      onPrimary: Colors.white,
    ),

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white, 
        fontSize: 20, 
        fontWeight: FontWeight.bold
      ),
    ),

    // Input Fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C), // Dark Grey fill
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: Colors.grey[500]),
    ),
  );

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