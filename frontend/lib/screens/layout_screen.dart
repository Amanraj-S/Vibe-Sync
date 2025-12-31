import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'chat_list_screen.dart';
import 'profile_screen.dart';

class LayoutScreen extends StatefulWidget {
  const LayoutScreen({super.key});

  @override
  State<LayoutScreen> createState() => _LayoutScreenState();
}

class _LayoutScreenState extends State<LayoutScreen> {
  int _page = 0;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    SocketService.initSocket();
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  void navigationTapped(int page) {
    pageController.jumpToPage(page);
  }

  @override
  Widget build(BuildContext context) {
    // --- ACCESS THEME ---
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // <--- DYNAMIC BG
      body: PageView(
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: const NeverScrollableScrollPhysics(), // Prevent swiping
        children: const [
          HomeScreen(),
          SearchScreen(),
          ChatListScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.cardColor, // <--- DYNAMIC BAR BG
          border: Border(
            top: BorderSide(
              color: theme.dividerColor, // <--- DYNAMIC BORDER
              width: 0.5,
            ),
          ),
          boxShadow: [
            // Only show shadow in Light Mode (Shadows look bad in true dark mode)
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: theme.cardColor, // <--- DYNAMIC BG
            indicatorColor: theme.primaryColor.withOpacity(0.1), // <--- DYNAMIC INDICATOR
            labelTextStyle: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor, // <--- DYNAMIC SELECTED LABEL
                );
              }
              return TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[500] : Colors.grey[600], // <--- DYNAMIC UNSELECTED
              );
            }),
            iconTheme: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return IconThemeData(
                    color: theme.primaryColor, size: 26); // <--- DYNAMIC SELECTED ICON
              }
              return IconThemeData(
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                  size: 24); // <--- DYNAMIC UNSELECTED ICON
            }),
          ),
          child: NavigationBar(
            height: 70,
            elevation: 0,
            selectedIndex: _page,
            onDestinationSelected: navigationTapped,
            backgroundColor: theme.cardColor, // <--- ENSURE BG MATCHES
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_rounded),
                selectedIcon: Icon(Icons.saved_search_rounded),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline_rounded),
                selectedIcon: Icon(Icons.chat_bubble_rounded),
                label: 'Chat',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}