import 'package:flutter/material.dart';
import 'styles.dart';
import 'routes.dart';

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
      precacheImage(const AssetImage(AppImages.image5), context);
      precacheImage(const AssetImage(AppImages.image6), context);

      _imagesPrecached = true; // to avoid precaching multiple times
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
            Image.asset(AppImages.image1, height: 350, width: 300),
            const SizedBox(height: AppSizing.ssb),
            const Text(
              AppText.title1,
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
            const SizedBox(height: AppSizing.tsb),
            Text(
              AppText.text1,
              style: TextStyle(
                color: AppColors.whiteWithOpacity60,
                fontWeight: FontWeight.normal,
                fontSize: AppSizing.textfont,
              ),
            ),
            SizedBox(height: AppSizing.ftsb),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.os2);
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
