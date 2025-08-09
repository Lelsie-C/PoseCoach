import 'package:flutter/material.dart';
import 'package:sugmps/OSs/routes.dart';
import 'styles.dart';

class OS4 extends StatefulWidget {
  const OS4({super.key});

  @override
  State<OS4> createState() => _OS4State();
}

class _OS4State extends State<OS4> {
  bool _imagesPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPrecached) {
      precacheImage(const AssetImage(AppImages.image4), context);
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
            Image.asset(AppImages.image4, height: 350, width: 300),
            const SizedBox(height: AppSizing.ssb),
            const Text(
              AppText.title4,
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: AppSizing.titlefont,
              ),
            ),
            const SizedBox(height: AppSizing.tsb),
            Text(
              AppText.text4,
              style: TextStyle(
                color: AppColors.whiteWithOpacity60,
                fontWeight: FontWeight.normal,
                fontSize: AppSizing.textfont,
              ),
            ),
            SizedBox(height: AppSizing.ftsb),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.os5);
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
