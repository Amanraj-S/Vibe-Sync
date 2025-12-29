import 'dart:convert';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class ApiService {
  // --- HELPERS ---
  static Future<Map<String, String>> getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    return {
      "Content-Type": "application/json",
      "Authorization": token ?? "" // Sends token as-is
    };
  }

  // --- AUTHENTICATION ---
  
  // Register User
  static Future<void> register(String username, String email, String password, String about, XFile? imageFile) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    final request = http.MultipartRequest('POST', uri);
    
    request.fields['username'] = username;
    request.fields['email'] = email;
    request.fields['password'] = password;
    request.fields['about'] = about;

    if (imageFile != null) {
      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes('profilePic', await imageFile.readAsBytes(), filename: 'profile.jpg'));
      } else {
        request.files.add(await http.MultipartFile.fromPath('profilePic', imageFile.path));
      }
    }

    final response = await request.send();
    if (response.statusCode != 201) {
       final respStr = await response.stream.bytesToString();
       throw Exception("Registration Failed: $respStr");
    }
  }

  // Login User
  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('userId', data['user']['_id']);
      return true;
    }
    return false;
  }

  // --- USER PROFILES ---

  // Get "My" Profile
  static Future<Map<String, dynamic>> getMyProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId == null) throw Exception("User ID not found locally");
    return getUserProfile(userId);
  }

  // Get Any User Profile by ID
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final headers = await getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/users/profile/$userId'), headers: headers);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load profile');
    }
  }

  // Update Profile (NOW ACCEPTS USERNAME)
  static Future<void> updateProfile(String username, String about, XFile? imageFile) async {
    final uri = Uri.parse('$baseUrl/users/update');
    final request = http.MultipartRequest('PUT', uri);
    
    final headers = await getHeaders();
    request.headers['Authorization'] = headers['Authorization']!;
    
    // Add fields to request
    request.fields['username'] = username; // <--- NEW: Send username
    request.fields['about'] = about;       // Kept as 'about' (ensure backend maps it to 'desc' if needed)

    if (imageFile != null) {
      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes('profilePic', await imageFile.readAsBytes(), filename: 'update.jpg'));
      } else {
        request.files.add(await http.MultipartFile.fromPath('profilePic', imageFile.path));
      }
    }

    final response = await request.send();
    
    if (response.statusCode != 200) {
      final respStr = await response.stream.bytesToString();
      throw Exception('Update failed: $respStr');
    }
  }

  // Get All Users (Search)
  static Future<List<dynamic>> getAllUsers() async {
    final headers = await getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/users'), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // Follow / Unfollow
  static Future<void> followUser(String userId) async {
    final headers = await getHeaders();
    await http.put(Uri.parse('$baseUrl/users/follow/$userId'), headers: headers);
  }

  // Get Connections (Followers & Following List)
  static Future<Map<String, dynamic>> getUserConnections(String userId) async {
    final headers = await getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/users/connections/$userId'), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return {"followers": [], "following": []};
  }

  // Delete My Account
  static Future<void> deleteAccount() async {
    final headers = await getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/users/delete'), headers: headers);
    
    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } else {
      throw Exception('Failed to delete account');
    }
  }

  // --- POSTS ---

  // Get All Posts (Feed)
  static Future<List<dynamic>> getPosts() async {
    final headers = await getHeaders(); 
    final response = await http.get(Uri.parse('$baseUrl/posts'), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // Get Posts for Specific User (Profile Page)
  static Future<List<dynamic>> getUserPosts(String userId) async {
    final headers = await getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/posts/user/$userId'), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // Create Post
  static Future<void> createPost(String description, XFile imageFile) async {
    final uri = Uri.parse('$baseUrl/posts');
    final request = http.MultipartRequest('POST', uri);
    final headers = await getHeaders();
    request.headers['Authorization'] = headers['Authorization']!;
    request.fields['description'] = description;

    if (kIsWeb) {
      request.files.add(http.MultipartFile.fromBytes('image', await imageFile.readAsBytes(), filename: 'post.jpg'));
    } else {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }

    final response = await request.send();
    if (response.statusCode != 201) throw Exception('Upload failed');
  }

  // Edit Post (Description Only)
  static Future<void> editPost(String postId, String newDescription) async {
    final headers = await getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/posts/$postId'),
      headers: headers,
      body: jsonEncode({'description': newDescription}),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update post');
    }
  }

  // Delete Post
  static Future<void> deletePost(String postId) async {
    final headers = await getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/posts/$postId'), headers: headers);
    if (response.statusCode != 200) throw Exception('Failed to delete post');
  }

  // --- LIKES & COMMENTS (NEW) ---

  // Like a Post
  static Future<void> likePost(String postId) async {
    final headers = await getHeaders();
    await http.put(
      Uri.parse('$baseUrl/posts/$postId/like'),
      headers: headers,
    );
  }

  // Add a Comment
  static Future<void> addComment(String postId, String text) async {
    final headers = await getHeaders();
    await http.post(
      Uri.parse('$baseUrl/posts/$postId/comment'),
      headers: headers,
      body: jsonEncode({'text': text}),
    );
  }

  // --- CHAT ---
  static Future<List<dynamic>> getChatHistory(String otherUserId) async {
    final headers = await getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/chat/$otherUserId'), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }
}