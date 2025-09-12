import 'package:flutter/material.dart';
import 'package:sugmps/utils/routes.dart';
import '../utils/styles.dart';

class OS2 extends StatefulWidget {
  const OS2({super.key});

  @override
  State<OS2> createState() => _OS2State();
}

class _OS2State extends State<OS2> {
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
            children: [
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: AppSizing.fsb),
                      Image.asset(AppImages.image2, height: 350, width: 300),
                      const SizedBox(height: AppSizing.ssb),
                      const Text(
                        AppText.title2,
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: AppSizing.titlefont,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizing.tsb),
                      Text(
                        AppText.text2,
                        style: TextStyle(
                          color: AppColors.whiteWithOpacity60,
                          fontWeight: FontWeight.normal,
                          fontSize: AppSizing.textfont,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSizing.ftsb),
                    ],
                  ),
                ),
              ),
              // Fixed Next button at bottom
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
                          () => Navigator.pushNamed(context, AppRoutes.os3),
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
                        "Next",
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
}
