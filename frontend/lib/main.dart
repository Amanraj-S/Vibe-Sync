import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <--- Required for ThemeProvider
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/theme_provider.dart'; // <--- Import your ThemeProvider
import 'screens/auth_screen.dart';
import 'screens/layout_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Check Login Status (Token)
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');

  // 2. Run App wrapped in ThemeProvider
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(
        // Decide start screen based on login status
        startScreen: token != null ? const LayoutScreen() : const AuthScreen(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget startScreen;
  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    // 3. Listen to Theme Changes
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'VibeSync',
      debugShowCheckedModeBanner: false,

      // --- THEME CONFIGURATION ---
      // This forces the app to rebuild whenever themeProvider changes
      themeMode: themeProvider.themeMode, 
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,

      home: startScreen,
    );
  }
}