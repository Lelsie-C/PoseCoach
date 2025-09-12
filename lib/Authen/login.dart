import 'package:flutter/material.dart';
import 'package:sugmps/utils/routes.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _matriculeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? matricule;
  String? password;
  String? username;
  String? phone;

  // Gradient for icons
  static const _iconGradient = LinearGradient(
    colors: [Color(0xFFE77B22), Color.fromARGB(255, 20, 3, 119)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void dispose() {
    _matriculeController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
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

  void _login() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      debugPrint("Matricule: $matricule");
      debugPrint("Password: $password");
      debugPrint("Username: $username");
      debugPrint("Phone: $phone");

      Navigator.pushNamed(context, AppRoutes.os1);
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
                    "Login",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Matricule input
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

                  // Password input
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

                  // Optional Username input
                  TextFormField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      "Username (optional)",
                      Icons.person,
                    ),
                    onSaved: (value) => username = value,
                  ),
                  const SizedBox(height: 15),

                  // Optional Phone number input
                  TextFormField(
                    controller: _phoneController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      "Phone Number (optional)",
                      Icons.phone,
                    ),
                    keyboardType: TextInputType.phone,
                    onSaved: (value) => phone = value,
                  ),
                  const SizedBox(height: 25),

                  ElevatedButton(
                    onPressed: _login,
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
                      "Login",
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
