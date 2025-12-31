import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import '../utils/image_utils.dart'; // Ensure this exists

class PostCard extends StatefulWidget {
  final Post post;
  final String currentUserId;
  final VoidCallback onPostChanged;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onPostChanged,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isLiked = false;
  int likeCount = 0;

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
    isLiked = widget.post.likes.contains(widget.currentUserId);
    likeCount = widget.post.likes.length;
  }

  // --- LIKE LOGIC ---
  void _toggleLike() async {
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });

    try {
      await ApiService.likePost(widget.post.id);
    } catch (e) {
      setState(() {
        isLiked = !isLiked;
        likeCount += isLiked ? 1 : -1;
      });
      print("Error liking post: $e");
    }
  }

  // --- DELETE LOGIC ---
  void _deletePost() async {
    try {
      await ApiService.deletePost(widget.post.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Post deleted")));
        widget.onPostChanged();
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- EDIT DIALOG ---
  void _showEditDialog() {
    TextEditingController descController =
        TextEditingController(text: widget.post.description);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Edit Post", style: TextStyle(color: _seaBlueDark)),
        content: TextField(
          controller: descController,
          decoration: InputDecoration(
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: _seaBlueDark)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiService.editPost(widget.post.id, descController.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                widget.onPostChanged();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _seaBlueDark,
              foregroundColor: Colors.white,
            ),
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // --- COMMENTS MODAL ---
  void _showCommentsModal() {
    TextEditingController commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor, // <--- DYNAMIC MODAL BG
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final theme = Theme.of(context);
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 15),
              Text("Comments",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _seaBlueDark)),
              const Divider(),
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: widget.post.comments.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text("No comments yet.",
                            style: TextStyle(color: theme.hintColor))) // DYNAMIC TEXT
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: widget.post.comments.length,
                        itemBuilder: (ctx, i) {
                          final c = widget.post.comments[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey[200],
                              child: const Icon(Icons.person,
                                  size: 16, color: Colors.grey),
                            ),
                            title: Text(c.username,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface)), // DYNAMIC TEXT
                            subtitle: Text(c.text, 
                                style: TextStyle(color: theme.colorScheme.onSurface)), // DYNAMIC TEXT
                          );
                        },
                      ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      style: TextStyle(color: theme.colorScheme.onSurface), // DYNAMIC INPUT TEXT
                      decoration: InputDecoration(
                        hintText: "Add a comment...",
                        filled: true,
                        fillColor: theme.inputDecorationTheme.fillColor, // DYNAMIC FILL
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      if (commentController.text.trim().isEmpty) return;
                      Navigator.pop(ctx);
                      await ApiService.addComment(
                          widget.post.id, commentController.text.trim());
                      widget.onPostChanged();
                    },
                    child: Text("Post",
                        style: TextStyle(
                            color: _seaBlueDark, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) return "${date.day}/${date.month}/${date.year}";
    if (diff.inDays >= 1) return "${diff.inDays}d ago";
    if (diff.inHours >= 1) return "${diff.inHours}h ago";
    if (diff.inMinutes >= 1) return "${diff.inMinutes}m ago";
    return "Just now";
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwner = widget.post.user.id == widget.currentUserId;
    final theme = Theme.of(context); // <--- ACCESS CURRENT THEME

    // --- USE IMAGE UTILS HELPER HERE ---
    String profilePicUrl = widget.post.user.profilePic;
    String validProfileUrl = ImageUtils.getValidImageUrl(profilePicUrl);

    String postImageUrl = widget.post.imageUrl;
    String validPostImageUrl = ImageUtils.getValidImageUrl(postImageUrl);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: theme.cardColor, // <--- DYNAMIC BACKGROUND COLOR
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header (AVATAR)
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _seaBlueGradient,
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: theme.cardColor, // <--- DYNAMIC AVATAR BG
                child: ClipOval(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: (validProfileUrl.isNotEmpty)
                        ? Image.network(
                            validProfileUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person, color: Colors.grey);
                            },
                          )
                        : const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
              ),
            ),
            title: Text(widget.post.user.username,
                style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 15,
                    color: theme.colorScheme.onSurface // <--- DYNAMIC TEXT COLOR
                )),
            subtitle: Text(_timeAgo(widget.post.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            trailing: isOwner
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _showEditDialog();
                      if (value == 'delete') _deletePost();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text("Edit")),
                      const PopupMenuItem(
                          value: 'delete',
                          child: Text("Delete",
                              style: TextStyle(color: Colors.red))),
                    ],
                    icon: Icon(Icons.more_vert, color: theme.iconTheme.color), // <--- DYNAMIC ICON COLOR
                  )
                : null,
          ),

          // 2. Image (POST IMAGE)
          if (validPostImageUrl.isNotEmpty)
            Image.network(
              validPostImageUrl,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                    height: 250,
                    child: Center(
                        child: CircularProgressIndicator(color: _seaBlueDark)));
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                    height: 200,
                    color: theme.dividerColor, // <--- DYNAMIC PLACEHOLDER BG
                    child: const Center(
                        child: Icon(Icons.broken_image,
                            size: 50, color: Colors.grey)));
              },
            ),

          // 3. Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? const Color(0xFFE91E63) : theme.iconTheme.color, // <--- DYNAMIC ICON
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _showCommentsModal,
                  child: Icon(Icons.chat_bubble_outline_rounded,
                      size: 26, color: theme.iconTheme.color), // <--- DYNAMIC ICON
                ),
                const Spacer(),
                Icon(Icons.bookmark_border_rounded,
                    size: 28, color: theme.iconTheme.color), // <--- DYNAMIC ICON
              ],
            ),
          ),

          // 4. Like Count & Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (likeCount > 0)
                  Text(
                    "$likeCount likes",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: theme.colorScheme.onSurface // <--- DYNAMIC TEXT
                    ),
                  ),
                const SizedBox(height: 4),
                if (widget.post.description.isNotEmpty)
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: theme.colorScheme.onSurface), // <--- DYNAMIC TEXT
                      children: [
                        TextSpan(
                            text: "${widget.post.user.username} ",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: widget.post.description),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                if (widget.post.comments.isNotEmpty)
                  GestureDetector(
                    onTap: _showCommentsModal,
                    child: Text(
                      "View all ${widget.post.comments.length} comments",
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}