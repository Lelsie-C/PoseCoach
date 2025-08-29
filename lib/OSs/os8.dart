import 'package:flutter/material.dart';
import 'package:sugmps/routes.dart';
import 'styles.dart';

class OS8 extends StatefulWidget {
  const OS8({super.key});

  @override
  State<OS8> createState() => _OS5State();
}

class _OS5State extends State<OS8> {
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
                onPressed: () => Navigator.pushNamed(context, AppRoutes.os7),
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
                      "What is your main goal with this app?",
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
                        icon: Icons.done,
                        iconColor: Colors.green,
                        label: "Improve posture",
                        opacity: 0.25,
                        onTap: () {},
                      ),
                      const SizedBox(height: 15),
                      _frequencyContainer(
                        icon: Icons.done,
                        iconColor: Colors.green,
                        label: "Reduce back pain",
                        opacity: 0.25,
                        onTap: () {},
                      ),
                      const SizedBox(height: 15),
                      _frequencyContainer(
                        icon: Icons.done,
                        iconColor: Colors.green,
                        label: "Build strength",
                        opacity: 0.25,
                        onTap: () {},
                      ),
                      const SizedBox(height: 15),
                      _frequencyContainer(
                        icon: Icons.done,
                        iconColor: Colors.green,
                        label: "Stay active",
                        opacity: 0.25,
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
                            AppRoutes.activity,
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
