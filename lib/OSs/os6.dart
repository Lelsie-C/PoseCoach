import 'package:flutter/material.dart';
import 'package:sugmps/OSs/routes.dart';
import 'styles.dart';

class OS6 extends StatefulWidget {
  const OS6({super.key});

  @override
  State<OS6> createState() => _OS6State();
}

class _OS6State extends State<OS6> {
  bool _imagesPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPrecached) {
      precacheImage(const AssetImage(AppImages.image6), context);
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
            Image.asset(AppImages.image6, height: 350, width: 300),
            const SizedBox(height: AppSizing.ssb),
            const Text(
              AppText.title6,
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: AppSizing.titlefont,
              ),
            ),
            const SizedBox(height: AppSizing.tsb),
            Text(
              AppText.text6,
              style: TextStyle(
                color: AppColors.whiteWithOpacity60,
                fontWeight: FontWeight.normal,
                fontSize: AppSizing.textfont,
              ),
            ),
            SizedBox(height: AppSizing.ftsb),
            ElevatedButton(
              onPressed: () {
                // If you want to do something here, add it.
                // Currently button repeats OS6.
                Navigator.pushNamed(context, AppRoutes.os6);
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
