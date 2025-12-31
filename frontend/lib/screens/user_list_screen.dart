import 'package:flutter/material.dart';
import 'profile_screen.dart';

class UserListScreen extends StatelessWidget {
  final String title;
  final List<dynamic> users;

  const UserListScreen({super.key, required this.title, required this.users});

  // --- SEA BLUE THEME COLORS ---
  final Color _seaBlueLight = const Color(0xFF0093AF);
  final Color _seaBlueDark = const Color(0xFF006994);

  LinearGradient get _seaBlueGradient => LinearGradient(
        colors: [_seaBlueDark, _seaBlueLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // Helper for Gradient Text
  Widget _buildGradientText(String text, double fontSize) {
    return ShaderMask(
      shaderCallback: (bounds) => _seaBlueGradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white, // Required for ShaderMask
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- ACCESS THEME ---
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // <--- DYNAMIC BG
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor, // <--- DYNAMIC APPBAR
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color), // <--- DYNAMIC ICON
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildGradientText(title, 22), // Gradient Title
      ),
      body: users.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off_rounded,
                      size: 80, color: theme.dividerColor), // <--- DYNAMIC ICON
                  const SizedBox(height: 16),
                  Text(
                    "No users found",
                    style: TextStyle(fontSize: 18, color: theme.hintColor), // <--- DYNAMIC TEXT
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: users.length,
              separatorBuilder: (ctx, i) => Divider(
                color: theme.dividerColor, // <--- DYNAMIC DIVIDER
                height: 1,
                indent: 80,
                endIndent: 20,
              ),
              itemBuilder: (context, index) {
                final user = users[index];
                
                // Handle case where user might be just an ID string or a full object
                final username =
                    user is Map ? (user['username'] ?? "Unknown") : "Unknown";
                final profilePic =
                    user is Map ? (user['profilePic'] ?? "") : "";
                final userId = user is Map ? user['_id'] : user.toString();

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _seaBlueGradient,
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.cardColor, // <--- DYNAMIC AVATAR BG
                      backgroundImage: (profilePic.isNotEmpty)
                          ? NetworkImage(profilePic)
                          : null,
                      child: (profilePic.isEmpty)
                          ? Icon(Icons.person, color: theme.iconTheme.color) // <--- DYNAMIC ICON
                          : null,
                    ),
                  ),
                  title: Text(
                    username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.onSurface, // <--- DYNAMIC TEXT COLOR
                    ),
                  ),
                  subtitle: Text(
                    "Tap to view profile",
                    style: TextStyle(color: theme.hintColor, fontSize: 12), // <--- DYNAMIC SUBTEXT
                  ),
                  trailing: Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: theme.dividerColor), // <--- DYNAMIC TRAILING ICON
                  onTap: () {
                    // Navigate to their profile
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProfileScreen(userId: userId)),
                    );
                  },
                );
              },
            ),
    );
  }
}