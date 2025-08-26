import 'package:flutter/material.dart';
import 'OSs/styles.dart';
import 'routes.dart';

class UserType extends StatefulWidget {
  const UserType({super.key});

  @override
  State<UserType> createState() => _UserTypeState();
}

class _UserTypeState extends State<UserType> {
  String? _selectedUserType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              AppText.title7,
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: AppSizing.titlefont,
              ),
            ),
            const SizedBox(height: 50),

            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RadioListTile<String>(
                    title: const Text('Student'),
                    value: 'student',
                    groupValue: _selectedUserType,
                    onChanged: (value) {
                      setState(() {
                        _selectedUserType = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Teacher'),
                    value: 'teacher',
                    groupValue: _selectedUserType,
                    onChanged: (value) {
                      setState(() {
                        _selectedUserType = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Admin'),
                    value: 'admin',
                    groupValue: _selectedUserType,
                    onChanged: (value) {
                      setState(() {
                        _selectedUserType = value;
                      });
                    },
                  ),

                  const SizedBox(height: 50),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFE77B22),
                          Color.fromARGB(255, 20, 3, 119),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed:
                          _selectedUserType == null
                              ? null
                              : () {
                                if (_selectedUserType == "student") {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.prereg,
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Only students can register here",
                                      ),
                                    ),
                                  );
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 70,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Next",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
