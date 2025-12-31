import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <--- Import Provider for Theme Toggle
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'auth_screen.dart';
import 'edit_profile_screen.dart';
import 'user_list_screen.dart';
import '../utils/image_utils.dart';
import '../providers/theme_provider.dart'; // <--- Import ThemeProvider

class ProfileScreen extends StatefulWidget {
  final String? userId; 

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userProfile;
  List<dynamic> userPosts = [];
  bool isLoading = true;
  String? currentUserId;

  // --- SEA BLUE THEME COLORS ---
  final Color _seaBlueLight = const Color(0xFF0093AF);
  final Color _seaBlueDark = const Color(0xFF006994);

  LinearGradient get _seaBlueGradient => LinearGradient(
        colors: [_seaBlueDark, _seaBlueLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString('userId');
    String targetId = widget.userId ?? currentUserId!;

    try {
      final profile = (widget.userId == null || widget.userId == currentUserId)
          ? await ApiService.getMyProfile()
          : await ApiService.getUserProfile(targetId);

      final posts = await ApiService.getUserPosts(targetId);

      if (mounted) {
        setState(() {
          userProfile = profile;
          userPosts = posts;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ... (Keep your existing _showConnections, _handleDeletePost, _handleDeleteAccount helper methods here)
  void _showConnections(String type) async {
    if (userProfile == null) return;
    try {
      final connections = await ApiService.getUserConnections(userProfile!['_id']);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => UserListScreen(title: type, users: type == "Followers" ? connections['followers'] : connections['following'])));
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not load list"))); }
  }

  void _handleDeletePost(String postId) async {
    try { await ApiService.deletePost(postId); Navigator.pop(context); _loadData(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post deleted"))); } 
    catch (e) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete post"))); }
  }

  void _handleDeleteAccount() async {
    try { await ApiService.deleteAccount(); if (!mounted) return; Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthScreen()), (route) => false); } 
    catch (e) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete account"))); }
  }
  // ...

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
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- ACCESS THEME FOR DARK MODE ---
    final theme = Theme.of(context); 
    
    // --- HELPER FOR SUBTEXT COLOR ---
    // If it's dark mode, use a lighter grey for readability
    final Color subTextColor = theme.brightness == Brightness.dark 
        ? Colors.grey[400]! 
        : Colors.grey[600]!;

    if (isLoading)
      return Scaffold(
          body: Center(child: CircularProgressIndicator(color: _seaBlueDark)));
    if (userProfile == null)
      return const Scaffold(body: Center(child: Text("User not found")));

    bool isMe = (widget.userId == null || widget.userId == currentUserId);
    List followers = userProfile!['followers'] ?? [];
    List following = userProfile!['following'] ?? [];

    String profileUrlRaw = userProfile!['profilePic'] ?? "";
    String validProfileUrl = ImageUtils.getValidImageUrl(profileUrlRaw);

    String bioText = userProfile!['about'] ?? userProfile!['desc'] ?? "";
    if (bioText.trim().isEmpty) bioText = "No bio yet.";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // <--- DYNAMIC BG
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor, // <--- DYNAMIC APPBAR
        elevation: 0,
        centerTitle: true,
        iconTheme: theme.iconTheme, // <--- DYNAMIC ICONS
        title: _buildGradientText(
            userProfile!['username'] ?? "Profile", 20),
        actions: [
          // --- DARK MODE TOGGLE ---
          if (isMe)
            IconButton(
              icon: Icon(
                Provider.of<ThemeProvider>(context).isDarkMode 
                    ? Icons.light_mode 
                    : Icons.dark_mode,
                color: Provider.of<ThemeProvider>(context).isDarkMode 
                    ? Colors.amber 
                    : Colors.grey[600],
              ),
              onPressed: () {
                final provider = Provider.of<ThemeProvider>(context, listen: false);
                provider.toggleTheme(!provider.isDarkMode);
              },
            ),
          
          if (isMe)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (r) => false);
              },
            )
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // --- PROFILE HEADER ---
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _seaBlueGradient,
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.cardColor, // <--- DYNAMIC AVATAR BG
                    child: ClipOval(
                      child: SizedBox(
                        width: 100, 
                        height: 100,
                        child: (validProfileUrl.isNotEmpty)
                            ? Image.network(
                                validProfileUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.person, size: 50, color: Colors.grey[300]);
                                },
                              )
                            : Icon(Icons.person, size: 50, color: Colors.grey[300]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  userProfile!['username'] ?? "Unknown",
                  style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface // <--- DYNAMIC TEXT COLOR
                  ),
                ),
                const SizedBox(height: 6),
                
                // --- BIO SECTION ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    bioText,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subTextColor, fontSize: 14), // <--- DYNAMIC SUBTEXT
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- STATS ROW ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem("Posts", userPosts.length.toString(), null, theme, subTextColor),
                Container(width: 1, height: 40, color: theme.dividerColor), // <--- DYNAMIC DIVIDER
                _buildStatItem("Followers", followers.length.toString(),
                    () => _showConnections("Followers"), theme, subTextColor),
                Container(width: 1, height: 40, color: theme.dividerColor), // <--- DYNAMIC DIVIDER
                _buildStatItem("Following", following.length.toString(),
                    () => _showConnections("Following"), theme, subTextColor),
              ],
            ),

            const SizedBox(height: 24),

            // --- ACTION BUTTON ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                height: 45,
                child: isMe
                    ? OutlinedButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const EditProfileScreen())).then(
                            (_) => _loadData()),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _seaBlueDark),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          foregroundColor: _seaBlueDark,
                        ),
                        child: const Text("Edit Profile",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: followers.contains(currentUserId)
                              ? null
                              : _seaBlueGradient,
                          color: followers.contains(currentUserId)
                              ? theme.cardColor // <--- DYNAMIC BUTTON BG
                              : null,
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            await ApiService.followUser(userProfile!['_id']);
                            _loadData();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: followers.contains(currentUserId)
                                ? theme.colorScheme.onSurface // <--- DYNAMIC TEXT
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(followers.contains(currentUserId)
                              ? "Unfollow"
                              : "Follow"),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 30),

            // --- POSTS GRID ---
            userPosts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: Column(
                      children: [
                        Icon(Icons.grid_off_rounded,
                            size: 60, color: theme.dividerColor), // <--- DYNAMIC ICON
                        const SizedBox(height: 10),
                        Text("No posts yet",
                            style: TextStyle(color: subTextColor)), // <--- DYNAMIC TEXT
                      ],
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemCount: userPosts.length,
                    itemBuilder: (context, index) {
                      final post = userPosts[index];
                      // --- POST IMAGES ---
                      String postImgRaw = post['imageUrl'] ?? "";
                      String validPostImg = ImageUtils.getValidImageUrl(postImgRaw);

                      return GestureDetector(
                        onTap: () {
                          // ... (Keep existing showDialog logic here) ...
                          showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    insetPadding: const EdgeInsets.all(10),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            validPostImg,
                                            errorBuilder: (ctx, err, stack) => Container(color: theme.cardColor),
                                          ),
                                        ),
                                        if (isMe)
                                          Positioned(
                                            top: 10, right: 10,
                                            child: CircleAvatar(
                                              backgroundColor: theme.cardColor,
                                              child: IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                onPressed: () => _handleDeletePost(post['_id']),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ));
                        },
                        child: validPostImg.isNotEmpty
                            ? Image.network(
                                validPostImg,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(color: theme.cardColor); // <--- DYNAMIC PLACEHOLDER
                                },
                              )
                            : Container(color: theme.cardColor), // <--- DYNAMIC PLACEHOLDER
                      );
                    },
                  ),

            const SizedBox(height: 40),

            // --- DELETE ACCOUNT ---
            if (isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 30.0),
                child: TextButton(
                  onPressed: () {
                    // ... (Keep delete dialog logic) ...
                    showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                              backgroundColor: theme.cardColor, // <--- DYNAMIC DIALOG BG
                              title: Text("Delete Account?", style: TextStyle(color: theme.colorScheme.onSurface)),
                              content: Text(
                                  "This action cannot be undone. All your posts will be permanently removed.",
                                  style: TextStyle(color: subTextColor)),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text("Cancel", style: TextStyle(color: subTextColor))),
                                TextButton(
                                    onPressed: _handleDeleteAccount,
                                    child: const Text("DELETE", style: TextStyle(color: Colors.red))),
                              ],
                            ));
                  },
                  child: Text("Delete My Account",
                      style: TextStyle(color: Colors.red[300], fontSize: 13)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper updated to accept Theme and Color
  Widget _buildStatItem(String label, String value, VoidCallback? onTap, ThemeData theme, Color subTextColor) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: theme.colorScheme.onSurface // <--- DYNAMIC VALUE COLOR
              )),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: subTextColor, fontSize: 13)), // <--- DYNAMIC LABEL COLOR
        ],
      ),
    );
  }
}