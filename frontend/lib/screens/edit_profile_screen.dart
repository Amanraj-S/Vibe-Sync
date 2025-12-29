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
  final _aboutController = TextEditingController();
  XFile? _imageFile;
  String? _currentProfilePic; // To show existing image before picking new one
  bool _isLoading = false;

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
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    try {
      final profile = await ApiService.getMyProfile();
      setState(() {
        _aboutController.text = profile['about'] ?? '';
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
    setState(() => _isLoading = true);
    try {
      await ApiService.updateProfile(_aboutController.text, _imageFile);
      if (mounted) {
        Navigator.pop(context); // Go back to profile screen
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
          color: Colors.white, // Required for ShaderMask
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine which image to show
    ImageProvider? backgroundImage;
    if (_imageFile != null) {
      backgroundImage = kIsWeb
          ? NetworkImage(_imageFile!.path)
          : FileImage(File(_imageFile!.path)) as ImageProvider;
    } else if (_currentProfilePic != null && _currentProfilePic!.isNotEmpty) {
      backgroundImage = NetworkImage(_currentProfilePic!);
    }

    return Scaffold(
      backgroundColor: Colors.white, // Solid White Background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
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
                    padding: const EdgeInsets.all(4), // Border width
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _seaBlueGradient,
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: backgroundImage,
                      child: (backgroundImage == null)
                          ? Icon(Icons.person, size: 60, color: Colors.grey[300])
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
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- ABOUT ME INPUT (FIXED ALIGNMENT) ---
            TextField(
              controller: _aboutController,
              maxLines: 4,
              textAlignVertical: TextAlignVertical.top, // Aligns text to top
              decoration: InputDecoration(
                labelText: "About Me",
                alignLabelWithHint: true, // Aligns label to top
                prefixIcon: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0), // Standard padding
                      child: Icon(Icons.info_outline, color: _seaBlueDark),
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
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