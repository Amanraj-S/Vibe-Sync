import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'auth_screen.dart';
import 'edit_profile_screen.dart';
import 'user_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // If null, loads logged-in user. If set, loads that user.

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

  void _showConnections(String type) async {
    if (userProfile == null) return;
    try {
      final connections =
          await ApiService.getUserConnections(userProfile!['_id']);
      if (!mounted) return;

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => UserListScreen(
                    title: type,
                    users: type == "Followers"
                        ? connections['followers']
                        : connections['following'],
                  )));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Could not load list")));
    }
  }

  void _handleDeletePost(String postId) async {
    try {
      await ApiService.deletePost(postId);
      Navigator.pop(context);
      _loadData();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Post deleted")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to delete post")));
    }
  }

  void _handleDeleteAccount() async {
    try {
      await ApiService.deleteAccount();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete account")));
    }
  }

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
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return Scaffold(
          body: Center(child: CircularProgressIndicator(color: _seaBlueDark)));
    if (userProfile == null)
      return const Scaffold(body: Center(child: Text("User not found")));

    bool isMe = (widget.userId == null || widget.userId == currentUserId);
    List followers = userProfile!['followers'] ?? [];
    List following = userProfile!['following'] ?? [];

    return Scaffold(
      backgroundColor: Colors.white, // Solid White Background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: _buildGradientText(
            userProfile!['username'] ?? "Profile", 20), // Gradient Username
        actions: [
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
                // Avatar with Sea Blue Gradient Ring
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _seaBlueGradient,
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: (userProfile!['profilePic'] != null &&
                            userProfile!['profilePic'] != "")
                        ? NetworkImage(userProfile!['profilePic'])
                        : null,
                    child: (userProfile!['profilePic'] == null ||
                            userProfile!['profilePic'] == "")
                        ? Icon(Icons.person, size: 50, color: Colors.grey[300])
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  userProfile!['username'] ?? "Unknown",
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    userProfile!['about'] ?? "No bio yet.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- STATS ROW ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem("Posts", userPosts.length.toString(), null),
                Container(width: 1, height: 40, color: Colors.grey[200]),
                _buildStatItem("Followers", followers.length.toString(),
                    () => _showConnections("Followers")),
                Container(width: 1, height: 40, color: Colors.grey[200]),
                _buildStatItem("Following", following.length.toString(),
                    () => _showConnections("Following")),
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
                              ? null // Grey for Unfollow
                              : _seaBlueGradient, // Gradient for Follow
                          color: followers.contains(currentUserId)
                              ? Colors.grey[200]
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
                                ? Colors.black
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
                            size: 60, color: Colors.grey[200]),
                        const SizedBox(height: 10),
                        Text("No posts yet",
                            style: TextStyle(color: Colors.grey[400])),
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
                      return GestureDetector(
                        onTap: () {
                          // Show Post Detail
                          showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    insetPadding: const EdgeInsets.all(10),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(post['imageUrl']),
                                        ),
                                        if (isMe)
                                          Positioned(
                                            top: 10,
                                            right: 10,
                                            child: CircleAvatar(
                                              backgroundColor: Colors.white,
                                              child: IconButton(
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () =>
                                                    _handleDeletePost(
                                                        post['_id']),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ));
                        },
                        child: post['imageUrl'] != null
                            ? Image.network(post['imageUrl'], fit: BoxFit.cover)
                            : Container(color: Colors.grey[100]),
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
                    showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                              title: const Text("Delete Account?"),
                              content: const Text(
                                  "This action cannot be undone. All your posts will be permanently removed."),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Cancel")),
                                TextButton(
                                    onPressed: _handleDeleteAccount,
                                    child: const Text("DELETE",
                                        style: TextStyle(color: Colors.red))),
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

  Widget _buildStatItem(String label, String value, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }
}