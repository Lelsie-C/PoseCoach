import 'package:flutter/material.dart';
import '../utils/styles.dart';
import 'package:sugmps/utils/routes.dart';

class OS1 extends StatefulWidget {
  const OS1({super.key});

  @override
  State<OS1> createState() => _OS1State();
}

class _OS1State extends State<OS1> {
  bool _imagesPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_imagesPrecached) {
      precacheImage(const AssetImage(AppImages.image1), context);
      precacheImage(const AssetImage(AppImages.image2), context);
      precacheImage(const AssetImage(AppImages.image3), context);
      precacheImage(const AssetImage(AppImages.image4), context);

      _imagesPrecached = true; // to avoid precaching multiple times
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
                      Image.asset(AppImages.image1, height: 350, width: 300),
                      const SizedBox(height: AppSizing.ssb),
                      const Text(
                        AppText.title1,
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizing.tsb),
                      Text(
                        AppText.text1,
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
                      onPressed: () {
                        // Replace OS1 with OS2
                        Navigator.pushReplacementNamed(context, AppRoutes.os2);
                      },
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
