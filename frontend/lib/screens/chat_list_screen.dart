import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart'; // Import Socket Service
import '../models/user_model.dart';
import '../models/message_model.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<User> following = [];
  Map<String, int> _unreadCounts = {}; // Store unread messages per user
  bool isLoading = true;
  String? myId;

  // --- SEA BLUE THEME COLORS (Keep for specific UI elements) ---
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
    if (myId != null) {
      await fetchFollowing();
      _setupSocketListeners();
    }
  }

  // --- REAL-TIME LISTENERS ---
  void _setupSocketListeners() {
    // 1. User Came Online
    SocketService.socket.on('user-online', (userId) {
      if (mounted) {
        setState(() {
          for (var user in following) {
            if (user.id == userId) {
              user.isOnline = true; 
            }
          }
        });
      }
    });

    // 2. User Went Offline
    SocketService.socket.on('user-offline', (userId) {
      if (mounted) {
        setState(() {
          for (var user in following) {
            if (user.id == userId) {
              user.isOnline = false;
              user.lastSeen = DateTime.now();
            }
          }
        });
      }
    });

    // 3. Receive Message (For Unread Badges)
    SocketService.socket.on('receive-message', (data) {
      if (mounted) {
        final msg = Message.fromJson(data);
        setState(() {
          // Increment unread count for the sender
          if (_unreadCounts.containsKey(msg.senderId)) {
            _unreadCounts[msg.senderId] = _unreadCounts[msg.senderId]! + 1;
          } else {
            _unreadCounts[msg.senderId] = 1;
          }

          // Optional: Move this user to the top of the list
          final index = following.indexWhere((u) => u.id == msg.senderId);
          if (index != -1) {
            final user = following.removeAt(index);
            following.insert(0, user);
          }
        });
      }
    });
  }

  Future<void> fetchFollowing() async {
    try {
      if (myId == null) return;

      final connections = await ApiService.getUserConnections(myId!);
      final followingListJson = connections['following'] as List;

      if (mounted) {
        setState(() {
          following = followingListJson.map((json) => User.fromJson(json)).toList();
          // Initialize unread counts to 0
          for (var user in following) {
            _unreadCounts[user.id] = 0; 
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching chat list: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Helper to format "Last seen" time
  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return "Offline";
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
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
    // --- ACCESS THEME ---
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // <--- DYNAMIC BG
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor, // <--- DYNAMIC APPBAR
        elevation: 0,
        centerTitle: true,
        title: _buildGradientText("Chats", 22),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: _seaBlueDark))
          : following.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 80, color: theme.dividerColor), // <--- DYNAMIC ICON COLOR
                      const SizedBox(height: 16),
                      Text(
                        "No chats yet",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: theme.hintColor), // <--- DYNAMIC TEXT
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Follow people to start chatting!",
                        style: TextStyle(color: theme.hintColor), // <--- DYNAMIC SUBTEXT
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(top: 10),
                  itemCount: following.length,
                  separatorBuilder: (ctx, i) => Divider(
                    color: theme.dividerColor, // <--- DYNAMIC DIVIDER
                    height: 1,
                    indent: 80, 
                    endIndent: 20,
                  ),
                  itemBuilder: (ctx, i) {
                    final user = following[i];
                    final int unread = _unreadCounts[user.id] ?? 0;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      leading: Stack(
                        children: [
                          // Avatar with Gradient Ring
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: _seaBlueGradient,
                            ),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: theme.cardColor, // <--- DYNAMIC AVATAR BG
                              backgroundImage: (user.profilePic.isNotEmpty)
                                  ? NetworkImage(user.profilePic)
                                  : null,
                              child: (user.profilePic.isEmpty)
                                  ? Icon(Icons.person,
                                      color: theme.iconTheme.color) // <--- DYNAMIC ICON
                                  : null,
                            ),
                          ),
                          // Online Indicator
                          if (user.isOnline)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: theme.scaffoldBackgroundColor, width: 2), // <--- MATCH BG
                                ),
                              ),
                            )
                        ],
                      ),
                      title: Text(
                        user.username,
                        style: TextStyle(
                          fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w600,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface, // <--- DYNAMIC TEXT COLOR
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            if (!user.isOnline)
                              Icon(Icons.access_time,
                                  size: 14, color: theme.hintColor), // <--- DYNAMIC ICON
                            if (!user.isOnline) const SizedBox(width: 4),
                            Text(
                              user.isOnline
                                  ? "Online Now"
                                  : "Seen ${_formatLastSeen(user.lastSeen)}",
                              style: TextStyle(
                                color: user.isOnline
                                    ? Colors.green
                                    : theme.hintColor, // <--- DYNAMIC SUBTEXT
                                fontWeight: user.isOnline
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // --- UNREAD COUNT BADGE ---
                          if (unread > 0)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0093AF), // Sea Blue
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unread.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 16, color: theme.dividerColor), // <--- DYNAMIC ARROW
                        ],
                      ),
                      onTap: () {
                        // Reset count when entering chat
                        setState(() {
                          _unreadCounts[user.id] = 0;
                        });
                        
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ChatRoomScreen(targetUser: user)));
                      },
                    );
                  },
                ),
    );
  }
}