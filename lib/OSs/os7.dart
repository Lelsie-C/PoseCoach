import 'package:flutter/material.dart';
import 'package:sugmps/utils/routes.dart';
import '../utils/styles.dart';

class OS7 extends StatefulWidget {
  const OS7({super.key});

  @override
  State<OS7> createState() => _OS7State();
}

class _OS7State extends State<OS7> {
  bool _imagesPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_imagesPrecached) {
      precacheImage(const AssetImage(AppImages.image2), context);
      _imagesPrecached = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizing.edgeinsets),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top back arrow
              IconButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.os8),
                icon: const Icon(
                  Icons.arrow_back,
                  size: 30,
                  color: Colors.black,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 10),
              // Centered texts
              Center(
                child: Column(
                  children: const [
                    Text(
                      "How much time do you spend sitting daily?",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "You can skip if you're not sure",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 140, 139, 139),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
              // Expanded scrollable area for frequency buttons
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _frequencyContainer(
                        icon: Icons.not_interested,
                        iconColor: Colors.grey,
                        label: "Less than four hours",
                        opacity: 0.25,
                        onTap: () {},
                      ),
                      const SizedBox(height: 15),
                      _frequencyContainer(
                        icon: Icons.looks_two,
                        iconColor: Colors.blue,
                        label: "4 hours to 8 hours",
                        opacity: 0.50,
                        onTap: () {},
                      ),
                      const SizedBox(height: 15),
                      _frequencyContainer(
                        icon: Icons.repeat,
                        iconColor: Colors.orange,
                        label: "8 hours to 12 hours",
                        opacity: 0.75,
                        onTap: () {},
                      ),
                      const SizedBox(height: 15),
                      _frequencyContainer(
                        icon: Icons.sunny,
                        iconColor: Colors.green,
                        label: "12 hours plus",
                        opacity: 0.90,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
              // Fixed Next button at the bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 14, 147, 73),
                          Color.fromARGB(255, 76, 175, 80),
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
                          () => Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.os8,
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 125,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Skip",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for frequency containers
  Widget _frequencyContainer({
    required IconData icon,
    required Color iconColor,
    required String label,
    required double opacity,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 56,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Color.fromRGBO(76, 175, 80, opacity),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 30),
            const SizedBox(width: 15),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
