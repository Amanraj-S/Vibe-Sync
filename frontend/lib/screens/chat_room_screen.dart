import 'dart:async'; // Required for Timer
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';

class ChatRoomScreen extends StatefulWidget {
  final User targetUser;
  const ChatRoomScreen({super.key, required this.targetUser});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Message> messages = [];
  String? myId;

  // --- REAL-TIME STATUS VARIABLES ---
  late bool _isOnline;
  DateTime? _lastSeen;
  Timer? _statusTimer;

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
    // 1. Initialize status from the passed User object
    _isOnline = widget.targetUser.isOnline;
    _lastSeen = widget.targetUser.lastSeen;

    _initializeData(); // Load ID then History
    _setupSocketListeners();

    // 2. Start a timer to refresh the "Last seen X min ago" text every minute
    _statusTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted && !_isOnline) {
        setState(() {}); // Triggers rebuild to update time difference
      }
    });
  }

  // Ensure myId is loaded BEFORE showing messages to fix alignment
  Future<void> _initializeData() async {
    await _loadMyId();
    _fetchHistory();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _setupSocketListeners() {
    // Listen for incoming messages
    SocketService.socket.on('receive-message', (data) {
      if (mounted) {
        setState(() {
          messages.add(Message.fromJson(data));
        });
      }
    });

    // Listen for User Coming Online
    SocketService.socket.on('user-online', (userId) {
      if (userId == widget.targetUser.id && mounted) {
        setState(() {
          _isOnline = true;
        });
      }
    });

    // Listen for User Going Offline
    SocketService.socket.on('user-offline', (userId) {
      if (userId == widget.targetUser.id && mounted) {
        setState(() {
          _isOnline = false;
          _lastSeen = DateTime.now(); // Update last seen to right now
        });
      }
    });
  }

  Future<void> _loadMyId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => myId = prefs.getString('userId'));
  }

  Future<void> _fetchHistory() async {
    try {
      final data = await ApiService.getChatHistory(widget.targetUser.id);
      setState(() {
        messages = data.map((json) => Message.fromJson(json)).toList();
      });
    } catch (e) {
      print("Error loading chat: $e");
    }
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    SocketService.sendMessage(widget.targetUser.id, _controller.text);

    if (myId != null) {
      setState(() {
        messages.add(Message(
          senderId: myId!,
          receiverId: widget.targetUser.id,
          text: _controller.text,
          createdAt: DateTime.now(),
        ));
      });
    }
    _controller.clear();
  }

  // Helper to format "Last seen"
  String _getStatusText() {
    if (_isOnline) return "Online";
    if (_lastSeen == null) return "Offline";

    final diff = DateTime.now().difference(_lastSeen!);
    if (diff.inMinutes < 1) return "Last seen just now";
    if (diff.inMinutes < 60) return "Last seen ${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "Last seen ${diff.inHours}h ago";
    return "Last seen ${diff.inDays}d ago";
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // <--- DYNAMIC BG
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor, // <--- DYNAMIC APPBAR
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color), // <--- DYNAMIC ICON
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Avatar with Gradient Ring
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _seaBlueGradient,
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.cardColor, // <--- DYNAMIC AVATAR BG
                backgroundImage: widget.targetUser.profilePic.isNotEmpty
                    ? NetworkImage(widget.targetUser.profilePic)
                    : null,
                child: widget.targetUser.profilePic.isEmpty
                    ? Icon(Icons.person, size: 20, color: isDark ? Colors.grey[400] : Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGradientText(widget.targetUser.username, 16),
                // Real-time Status Text
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: _isOnline ? Colors.green : Colors.grey[500],
                    fontWeight:
                        _isOnline ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // --- MESSAGES LIST ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: messages.length,
              itemBuilder: (ctx, i) {
                final msg = messages[i];
                
                // --- CORE LOGIC: Determines Left or Right ---
                // If I am the sender, it returns true (Right Side)
                // If myId is null (loading), default to false (Left Side) to prevent crashes
                final bool isMe = (myId != null) && (msg.senderId == myId);

                return Align(
                  // WHATSAPP CONCEPT: Me -> Right, Others -> Left
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      // WHATSAPP CONCEPT: Colored for me, Grey/White for others
                      gradient: isMe ? _seaBlueGradient : null,
                      // DYNAMIC BUBBLE COLOR:
                      // If it's receiver (not me) AND dark mode, use Dark Grey.
                      // If light mode, use Light Grey.
                      color: isMe 
                          ? null 
                          : (isDark ? const Color(0xFF2C2C2C) : Colors.grey[100]),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        // WHATSAPP CONCEPT: The "Tail" logic
                        // If it's me, bottom-left is round, bottom-right is sharp (or tail)
                        bottomLeft: isMe 
                            ? const Radius.circular(16) 
                            : Radius.zero, // Tail for receiver
                        bottomRight: isMe 
                            ? Radius.zero  // Tail for sender
                            : const Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        // DYNAMIC TEXT COLOR:
                        // Me: White. Receiver: White (Dark Mode) or Black (Light Mode)
                        color: isMe 
                            ? Colors.white 
                            : theme.colorScheme.onSurface,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // --- INPUT AREA ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.cardColor, // <--- DYNAMIC BG
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: theme.colorScheme.onSurface), // <--- INPUT TEXT COLOR
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: theme.hintColor), // <--- DYNAMIC HINT
                        filled: true,
                        fillColor: theme.inputDecorationTheme.fillColor, // <--- DYNAMIC FILL
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _seaBlueGradient,
                        boxShadow: [
                          BoxShadow(
                            color: _seaBlueDark.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}