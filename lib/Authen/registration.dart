import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sugmps/routes.dart';
import '../services/auth_service.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _schoolEmailController = TextEditingController();
  final TextEditingController _otherEmailController = TextEditingController();
  final TextEditingController _matriculeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Input variables
  String? name;
  String? schoolEmail;
  String? otherEmail;
  String? matricule;
  String? password;
  String? confirmPassword;
  String? gender;
  File? profileImage;

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false; // Loading state

  static const _iconGradient = LinearGradient(
    colors: [Color(0xFFE77B22), Color.fromARGB(128, 20, 3, 119)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _schoolEmailController.dispose();
    _otherEmailController.dispose();
    _matriculeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        profileImage = File(pickedFile.path);
      });
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: ShaderMask(
        shaderCallback: (bounds) => _iconGradient.createShader(bounds),
        child: Icon(icon, color: Colors.white),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blueAccent),
        borderRadius: BorderRadius.circular(8),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    final authService = AuthService(
      baseUrl: 'https://example.com/api',
    ); // Replace with your API URL

    try {
      final result = await authService.register(
        name: name!,
        schoolEmail: schoolEmail!,
        otherEmail: otherEmail!,
        matricule: matricule!,
        password: password!,
        gender: gender!,
        profileImage: profileImage,
      );

      if (!mounted) return;
      // Success
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registration successful!')));
      Navigator.pushNamed(context, AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      // Error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 330,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Profile Image
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey.shade800,
                      backgroundImage:
                          profileImage != null
                              ? FileImage(profileImage!)
                              : null,
                      child:
                          profileImage == null
                              ? const Icon(
                                Icons.camera_alt,
                                color: Colors.white70,
                                size: 30,
                              )
                              : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Full Name", Icons.person),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? "Enter your name"
                                : null,
                    onSaved: (value) => name = value,
                  ),
                  const SizedBox(height: 15),

                  // School Email
                  TextFormField(
                    controller: _schoolEmailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("School Email", Icons.email),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter school email";
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return "Enter a valid email";
                      }
                      return null;
                    },
                    onSaved: (value) => schoolEmail = value,
                  ),
                  const SizedBox(height: 15),

                  // Other Email
                  TextFormField(
                    controller: _otherEmailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      "Other Email",
                      Icons.alternate_email,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter other email";
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return "Enter a valid email";
                      }
                      return null;
                    },
                    onSaved: (value) => otherEmail = value,
                  ),
                  const SizedBox(height: 15),

                  // Matricule Number
                  TextFormField(
                    controller: _matriculeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      "Matricule Number",
                      Icons.badge,
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? "Enter matricule"
                                : null,
                    onSaved: (value) => matricule = value,
                  ),
                  const SizedBox(height: 15),

                  // Gender Dropdown
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Select Gender", Icons.people),
                    value: gender,
                    items: const [
                      DropdownMenuItem(value: "Male", child: Text("Male")),
                      DropdownMenuItem(value: "Female", child: Text("Female")),
                      DropdownMenuItem(value: "Other", child: Text("Other")),
                    ],
                    onChanged: (value) => setState(() => gender = value),
                    validator:
                        (value) =>
                            value == null ? "Please choose gender" : null,
                  ),
                  const SizedBox(height: 15),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Password", Icons.lock),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter password";
                      }
                      if (value.length < 6) {
                        return "Password must be at least 6 chars";
                      }
                      return null;
                    },
                    onSaved: (value) => password = value,
                  ),
                  const SizedBox(height: 15),

                  // Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      "Confirm Password",
                      Icons.lock_reset,
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Confirm your password";
                      }
                      if (value != _passwordController.text) {
                        return "Passwords do not match";
                      }
                      return null;
                    },
                    onSaved: (value) => confirmPassword = value,
                  ),
                  const SizedBox(height: 25),

                  // Register Button
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.25),
                          side: const BorderSide(color: Colors.black, width: 1),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 100,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Register",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
