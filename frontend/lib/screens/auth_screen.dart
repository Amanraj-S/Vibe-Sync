import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb check
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'layout_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _aboutController = TextEditingController();

  XFile? _profileImage;
  bool _isLoading = false;

  // Sea Blue Gradient Definition
  final Color _seaBlueLight = const Color(0xFF0093AF);
  final Color _seaBlueDark = const Color(0xFF006994);

  LinearGradient get _seaBlueGradient => LinearGradient(
        colors: [_seaBlueDark, _seaBlueLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = picked);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!isLogin && _profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a profile picture.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (isLogin) {
        bool success = await ApiService.login(
            _emailController.text, _passwordController.text);
        if (success && mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const LayoutScreen()));
        }
      } else {
        await ApiService.register(
            _usernameController.text,
            _emailController.text,
            _passwordController.text,
            _aboutController.text,
            _profileImage);

        setState(() {
          isLogin = true;
          _profileImage = null;
          _emailController.clear();
          _passwordController.clear();
          _usernameController.clear();
          _aboutController.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Account Created! Please Login."),
            backgroundColor: Colors.green,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper for Gradient Text (Used for App Name)
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
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  // Helper for Text Fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _seaBlueDark),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                
                // --- APP LOGO NAME ---
                _buildGradientText("VibeSync", 40),
                
                const SizedBox(height: 10),
                
                // --- SUBTITLE (Login / Sign Up) ---
                Text(
                  isLogin ? "Welcome Back" : "Create Account",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 40),

                // --- AVATAR PICKER (Sign Up Only) ---
                if (!isLogin) ...[
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _seaBlueGradient,
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage: _profileImage != null
                                ? (kIsWeb
                                    ? NetworkImage(_profileImage!.path)
                                    : FileImage(File(_profileImage!.path))
                                        as ImageProvider)
                                : null,
                            child: _profileImage == null
                                ? Icon(Icons.person,
                                    size: 50, color: Colors.grey[300])
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: _seaBlueGradient,
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 18, color: Colors.white),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  _buildTextField(
                    controller: _usernameController,
                    label: "Username",
                    icon: Icons.person_outline,
                    validator: (v) => v!.isEmpty ? "Username required" : null,
                  ),

                  _buildTextField(
                    controller: _aboutController,
                    label: "Bio",
                    icon: Icons.info_outline,
                    validator: (v) => v!.isEmpty ? "Bio required" : null,
                  ),
                ],

                // --- COMMON FIELDS ---
                _buildTextField(
                  controller: _emailController,
                  label: "Email",
                  icon: Icons.email_outlined,
                  validator: (v) => v!.contains("@") ? null : "Invalid Email",
                ),

                _buildTextField(
                  controller: _passwordController,
                  label: "Password",
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: (v) => v!.length < 6 ? "Min 6 chars" : null,
                ),

                const SizedBox(height: 30),

                // --- MAIN ACTION BUTTON (Gradient) ---
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _submit,
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
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                isLogin ? "Login" : "Sign Up",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.1,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- BOTTOM LINK ---
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                      if (isLogin) _profileImage = null;
                      _formKey.currentState?.reset();
                    });
                  },
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                      children: [
                        TextSpan(
                            text: isLogin
                                ? "Don't have an account? "
                                : "Already have an account? "),
                        TextSpan(
                          text: isLogin ? "Create one" : "Login",
                          style: TextStyle(
                            color: _seaBlueDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}