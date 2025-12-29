import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<User> users = [];
  List<User> filteredUsers = [];
  bool isLoading = true;
  String? myId;
  final TextEditingController _searchController = TextEditingController();

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
    _loadMyId();
  }

  Future<void> _loadMyId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    myId = prefs.getString('userId');
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final data = await ApiService.getAllUsers();
      if (!mounted) return;

      setState(() {
        users = data.map((json) => User.fromJson(json)).toList();

        // Remove myself from search list
        if (myId != null) {
          users.removeWhere((u) => u.id == myId);
        }

        // Apply filter if text exists, otherwise show all
        if (_searchController.text.isNotEmpty) {
          _runFilter(_searchController.text);
        } else {
          filteredUsers = users;
        }
        isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _runFilter(String keyword) {
    if (keyword.isEmpty) {
      setState(() => filteredUsers = users);
    } else {
      setState(() {
        filteredUsers = users
            .where(
                (u) => u.username.toLowerCase().contains(keyword.toLowerCase()))
            .toList();
      });
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
    return Scaffold(
      backgroundColor: Colors.white, // Solid White Background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: _buildGradientText("Discover", 22), // Gradient Title
      ),
      body: Column(
        children: [
          // --- MODERN SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: _searchController,
              onChanged: _runFilter,
              decoration: InputDecoration(
                hintText: 'Search for friends...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: _seaBlueDark),
                filled: true,
                fillColor: Colors.grey[100], // Matches Auth Input
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // --- USER LIST ---
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: _seaBlueDark))
                : filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_outlined,
                                size: 80, color: Colors.grey[200]),
                            const SizedBox(height: 16),
                            Text(
                              "No users found",
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: filteredUsers.length,
                        separatorBuilder: (ctx, i) => Divider(
                          color: Colors.grey[100],
                          height: 1,
                          indent: 80,
                          endIndent: 20,
                        ),
                        itemBuilder: (ctx, i) {
                          final user = filteredUsers[i];
                          final isFollowing = user.followers.contains(myId);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProfileScreen(userId: user.id),
                                ),
                              ).then((_) => fetchUsers());
                            },
                            leading: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: _seaBlueGradient,
                              ),
                              child: CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white,
                                backgroundImage: user.profilePic.isNotEmpty
                                    ? NetworkImage(user.profilePic)
                                    : null,
                                child: user.profilePic.isEmpty
                                    ? const Icon(Icons.person,
                                        color: Colors.grey)
                                    : null,
                              ),
                            ),
                            title: Text(
                              user.username,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87),
                            ),
                            subtitle: Text(
                              "Tap to view profile",
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 13),
                            ),
                            // --- UPDATED BUTTON UI ---
                            trailing: SizedBox(
                              height: 35,
                              width: 110, // Increased width to fit text neatly
                              child: isFollowing
                                  ? ElevatedButton(
                                      onPressed: () =>
                                          _toggleFollow(user, isFollowing),
                                      style: ElevatedButton.styleFrom(
                                        // "Following" Style: Flat Grey
                                        backgroundColor: Colors.grey[200],
                                        foregroundColor: Colors.black87,
                                        elevation: 0,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          side: BorderSide(
                                              color: Colors.grey.shade300),
                                        ),
                                      ),
                                      child: const Text(
                                        "Following",
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        gradient: _seaBlueGradient,
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _toggleFollow(user, isFollowing),
                                        style: ElevatedButton.styleFrom(
                                          // "Follow" Style: Gradient
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          "Follow",
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _toggleFollow(User user, bool isFollowing) async {
    // Optimistic UI Update
    setState(() {
      if (isFollowing) {
        user.followers.remove(myId);
      } else {
        user.followers.add(myId!);
      }
    });

    try {
      await ApiService.followUser(user.id);
    } catch (e) {
      // Revert if error
      fetchUsers();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Action failed")));
      }
    }
  }
}