import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb check
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // 1. Controllers
  final _usernameController = TextEditingController();
  final _aboutController = TextEditingController();
  
  XFile? _imageFile;
  String? _currentProfilePic; 
  bool _isLoading = false;

  // --- SEA BLUE THEME COLORS (Keep for Gradient) ---
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
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfile() async {
    try {
      final profile = await ApiService.getMyProfile();
      setState(() {
        _usernameController.text = profile['username'] ?? '';
        _aboutController.text = profile['about'] ?? profile['desc'] ?? ''; 
        _currentProfilePic = profile['profilePic'];
      });
    } catch (e) {
      print("Error loading profile: $e");
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imageFile = image);
    }
  }

  Future<void> _updateProfile() async {
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Username cannot be empty")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.updateProfile(
        _usernameController.text.trim(), 
        _aboutController.text.trim(), 
        _imageFile
      );
      
      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Profile Updated!")));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
    // --- ACCESS THEME FOR DARK MODE ---
    final theme = Theme.of(context);

    // Determine Image Logic
    ImageProvider? backgroundImage;
    if (_imageFile != null) {
      backgroundImage = kIsWeb
          ? NetworkImage(_imageFile!.path)
          : FileImage(File(_imageFile!.path)) as ImageProvider;
    } else if (_currentProfilePic != null && _currentProfilePic!.isNotEmpty) {
      backgroundImage = NetworkImage(_currentProfilePic!);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // <--- DYNAMIC BG
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor, // <--- DYNAMIC APPBAR
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color), // <--- DYNAMIC ICON
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildGradientText("Edit Profile", 22),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // --- AVATAR PICKER ---
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4), 
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _seaBlueGradient,
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: theme.cardColor, // <--- DYNAMIC AVATAR BG
                      backgroundImage: backgroundImage,
                      child: (backgroundImage == null)
                          ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _seaBlueGradient,
                        border: Border.all(color: theme.scaffoldBackgroundColor, width: 2), // <--- MATCHES BG
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- 4. USERNAME INPUT (DARK MODE READY) ---
            TextField(
              controller: _usernameController,
              style: TextStyle(color: theme.colorScheme.onSurface), // <--- TEXT COLOR
              decoration: InputDecoration(
                labelText: "Username",
                labelStyle: TextStyle(color: theme.hintColor), // <--- HINT COLOR
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(Icons.person_outline, color: _seaBlueDark),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor, // <--- DYNAMIC FILL
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 16),
              ),
            ),

            const SizedBox(height: 20),

            // --- ABOUT ME INPUT (DARK MODE READY) ---
            TextField(
              controller: _aboutController,
              style: TextStyle(color: theme.colorScheme.onSurface), // <--- TEXT COLOR
              maxLines: 4,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                labelText: "About Me",
                labelStyle: TextStyle(color: theme.hintColor), // <--- HINT COLOR
                alignLabelWithHint: true, 
                prefixIcon: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0), 
                      child: Icon(Icons.info_outline, color: _seaBlueDark),
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor, // <--- DYNAMIC FILL
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 16),
              ),
            ),

            const SizedBox(height: 40),

            // --- SAVE BUTTON (Gradient) ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  backgroundColor: Colors.transparent,
                  shadowColor: _seaBlueDark.withOpacity(0.3),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: _seaBlueGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            "SAVE CHANGES",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}