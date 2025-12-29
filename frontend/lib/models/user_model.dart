class User {
  final String id;
  final String username;
  final String email;
  final String profilePic;
  final List<String> followers;
  final List<String> following;
  bool isOnline; 
  DateTime? lastSeen;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.profilePic,
    required this.followers,
    required this.following,
    this.isOnline = false,
    this.lastSeen,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profilePic: json['profilePic'] ?? '',
      followers: List<String>.from(json['followers'] ?? []),
      following: List<String>.from(json['following'] ?? []),
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null 
          ? DateTime.parse(json['lastSeen']) 
          : null,
    );
  }
}