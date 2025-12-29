import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';

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

  // --- SMART IMAGE URL FIXER (UPDATED FOR RENDER) ---
  String _getValidImageUrl(String url) {
    if (url.isEmpty) return "";

    // 1. RESCUE BROKEN CLOUDINARY LINKS
    // If the DB has a messy URL containing "vibesync_posts", extract ID and fix it.
    if (url.contains("vibesync_posts") || url.contains("vibesync")) {
      String cleanId = url.split(RegExp(r'vibesync(?:_posts)?/')).last;
      // Using the Cloud Name you provided in the previous snippet: devq3zfrq
      return "https://res.cloudinary.com/devq3zfrq/image/upload/vibesync_posts/$cleanId";
    }

    // 2. STANDARD URL HANDLING
    // If it's already a valid web URL (Cloudinary), return as is.
    if (url.startsWith("http") || url.startsWith("https")) {
      // If the database accidentally saved "localhost", point it to Render
      if (url.contains("localhost")) {
        return url.replaceFirst("http://localhost:5000", "https://vibe-sync-ijgt.onrender.com");
      }
      return url;
    }

    // 3. HANDLE RELATIVE PATHS (Legacy images)
    // If the DB has just "uploads/image.png", assume it's on Render
    return "https://vibe-sync-ijgt.onrender.com/$url";
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
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
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text("No comments yet.",
                            style: TextStyle(color: Colors.grey)))
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(c.text),
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
                      decoration: InputDecoration(
                        hintText: "Add a comment...",
                        filled: true,
                        fillColor: Colors.grey[100],
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
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
          // 1. Header
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
                backgroundColor: Colors.white,
                // --- FIX: APPLIED _getValidImageUrl HERE ---
                backgroundImage: (widget.post.user.profilePic.isNotEmpty)
                    ? NetworkImage(
                        _getValidImageUrl(widget.post.user.profilePic))
                    : null,
                child: (widget.post.user.profilePic.isEmpty)
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
            ),
            title: Text(widget.post.user.username,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
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
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  )
                : null,
          ),

          // 2. Image (POST IMAGE)
          if (widget.post.imageUrl.isNotEmpty)
            Image.network(
              _getValidImageUrl(widget.post.imageUrl),
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
                    color: Colors.grey[100],
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
                    color: isLiked ? const Color(0xFFE91E63) : Colors.black87,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _showCommentsModal,
                  child: const Icon(Icons.chat_bubble_outline_rounded,
                      size: 26, color: Colors.black87),
                ),
                const Spacer(),
                const Icon(Icons.bookmark_border_rounded,
                    size: 28, color: Colors.black87),
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 4),
                if (widget.post.description.isNotEmpty)
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black87),
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