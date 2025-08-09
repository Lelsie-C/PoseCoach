import 'package:flutter/material.dart';
import 'package:sugmps/OSs/routes.dart';
import 'styles.dart';

class OS3 extends StatefulWidget {
  const OS3({super.key});

  @override
  State<OS3> createState() => _OS3State();
}

class _OS3State extends State<OS3> {
  bool _imagesPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPrecached) {
      precacheImage(const AssetImage(AppImages.image3), context);
      _imagesPrecached = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(AppSizing.edgeinsets),
        child: Column(
          children: [
            const SizedBox(height: AppSizing.fsb),
            Image.asset(AppImages.image3, height: 350, width: 300),
            const SizedBox(height: AppSizing.ssb),
            const Text(
              AppText.title3,
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: AppSizing.titlefont,
              ),
            ),
            const SizedBox(height: AppSizing.tsb),
            Text(
              AppText.text3,
              style: TextStyle(
                color: AppColors.whiteWithOpacity60,
                fontWeight: FontWeight.normal,
                fontSize: AppSizing.textfont,
              ),
            ),
            SizedBox(height: AppSizing.ftsb),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.os4);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 125,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizing.buttonradius),
                ),
                elevation: AppSizing.elevation,
              ),
              child: const Text(
                "Next",
                style: TextStyle(
                  fontSize: AppSizing.buttontextfont,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
