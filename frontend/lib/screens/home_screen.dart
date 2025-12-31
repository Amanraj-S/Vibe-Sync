import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../services/api_service.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';
import 'add_post_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Post> posts = [];
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
    _loadUserAndPosts();
  }

  // Load User ID first, then posts
  Future<void> _loadUserAndPosts() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString('userId'); 
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    try {
      final data = await ApiService.getPosts();
      if (!mounted) return;
      setState(() {
        posts = data.map((json) => Post.fromJson(json)).toList();
        isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Helper for Gradient Text (App Name)
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
          letterSpacing: 1.2,
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
        centerTitle: false, 
        title: _buildGradientText("VibeSync", 26), // Gradient App Name
        actions: [
          IconButton(
            icon: Icon(Icons.add_box_outlined, size: 28, color: _seaBlueDark),
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const AddPostScreen())
            ).then((_) => fetchPosts()),
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: _seaBlueDark))
          : RefreshIndicator(
              color: _seaBlueDark,
              onRefresh: fetchPosts,
              child: posts.isEmpty
                  ? ListView(
                      // Use ListView for pull-to-refresh even when empty
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.dynamic_feed_rounded, size: 80, color: theme.dividerColor), // <--- DYNAMIC ICON COLOR
                              const SizedBox(height: 16),
                              Text(
                                "No vibes yet!",
                                style: TextStyle(
                                  fontSize: 20, 
                                  fontWeight: FontWeight.bold, 
                                  color: theme.hintColor // <--- DYNAMIC TEXT COLOR
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Be the first to share something cool.",
                                style: TextStyle(color: theme.hintColor), // <--- DYNAMIC SUBTEXT
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 20),
                      itemCount: posts.length,
                      itemBuilder: (ctx, i) => PostCard(
                        post: posts[i],
                        currentUserId: currentUserId ?? "",
                        onPostChanged: fetchPosts,
                      ),
                    ),
            ),
    );
  }
}