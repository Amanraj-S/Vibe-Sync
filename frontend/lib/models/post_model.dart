class Post {
  final String id;
  final String description;
  final String imageUrl;
  final UserWrapper user;
  final DateTime createdAt;
  final List<String> likes; // List of User IDs who liked
  final List<Comment> comments; // List of Comment objects

  Post({
    required this.id,
    required this.description,
    required this.imageUrl,
    required this.user,
    required this.createdAt,
    this.likes = const [],
    this.comments = const [],
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      user: UserWrapper.fromJson(json['user'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      // Parse Likes
      likes: (json['likes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      // Parse Comments
      comments: (json['comments'] as List<dynamic>?)
          ?.map((c) => Comment.fromJson(c))
          .toList() ?? [],
    );
  }
}

// Wrapper for the User inside a Post
class UserWrapper {
  final String id;
  final String username;
  final String profilePic;

  UserWrapper({required this.id, required this.username, required this.profilePic});

  factory UserWrapper.fromJson(Map<String, dynamic> json) {
    return UserWrapper(
      id: json['_id'] ?? '',
      username: json['username'] ?? 'Unknown',
      profilePic: json['profilePic'] ?? '',
    );
  }
}

// New Comment Model
class Comment {
  final String id;
  final String userId;
  final String username;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.username,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    // Handle case where user is populated or just an ID
    final userObj = json['user'];
    String uName = "Unknown";
    String uId = "";
    
    if (userObj is Map) {
      uName = userObj['username'] ?? "Unknown";
      uId = userObj['_id'] ?? "";
    } else {
      uId = userObj.toString();
    }

    return Comment(
      id: json['_id'] ?? '',
      userId: uId,
      username: uName,
      text: json['text'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now(),
    );
  }
}