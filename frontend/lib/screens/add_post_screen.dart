import 'dart:io';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  XFile? _image;
  final TextEditingController _descController = TextEditingController();
  bool _isLoading = false;

  // --- SEA BLUE THEME COLORS ---
  final Color _seaBlueLight = const Color(0xFF0093AF);
  final Color _seaBlueDark = const Color(0xFF006994);

  LinearGradient get _seaBlueGradient => LinearGradient(
        colors: [_seaBlueDark, _seaBlueLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = pickedFile);
    }
  }

  Future<void> _uploadPost() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select an image first")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiService.createPost(_descController.text, _image!);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Posted successfully!")));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper for Gradient Text (Matches Auth Screen Title)
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
    // --- ACCESS THEME ---
    final theme = Theme.of(context);

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
        title: _buildGradientText("New Post", 22), // Gradient Title
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Share your vibe",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: theme.hintColor, // <--- DYNAMIC TEXT COLOR
              ),
            ),
            const SizedBox(height: 20),

            // --- IMAGE PICKER ---
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.cardColor, // <--- DYNAMIC CONTAINER BG
                  borderRadius: BorderRadius.circular(16),
                  image: _image != null
                      ? DecorationImage(
                          image: kIsWeb
                              ? NetworkImage(_image!.path)
                              : FileImage(File(_image!.path)) as ImageProvider,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 50, color: _seaBlueDark), // Sea Blue Icon
                          const SizedBox(height: 10),
                          Text(
                            "Tap to select photo",
                            style: TextStyle(color: theme.hintColor, fontSize: 16), // <--- DYNAMIC HINT
                          ),
                        ],
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 24),

            // --- CAPTION INPUT ---
            TextField(
              controller: _descController,
              maxLines: 4,
              style: TextStyle(color: theme.colorScheme.onSurface), // <--- INPUT TEXT COLOR
              decoration: InputDecoration(
                labelText: "Caption",
                labelStyle: TextStyle(color: theme.hintColor),
                alignLabelWithHint: true,
                hintText: "Write a caption...",
                hintStyle: TextStyle(color: theme.hintColor), // <--- DYNAMIC HINT
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 60), // Align icon to top
                  child: Icon(Icons.edit_note, color: _seaBlueDark),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor, // <--- DYNAMIC FILL
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
            ),

            const SizedBox(height: 30),

            // --- POST BUTTON (Sea Blue Gradient) ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _uploadPost,
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
                            "SHARE POST",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // White text on gradient is always fine
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