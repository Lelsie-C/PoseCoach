import 'package:flutter/material.dart';
import 'colors.dart';

class OS5 extends StatelessWidget {
  const OS5({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: Padding(
        padding: const EdgeInsets.all(AppSizing.edgeinsets), //#edgeinset
        child: Column(
          children: [
            const SizedBox(height: AppSizing.fsb), //#fsb
            Image.asset('assets/image1.png', height: 350, width: 300),
            const SizedBox(height: AppSizing.ssb), //#ssb
            const Text(
              AppText.title5,
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20, //#titlefont
              ),
            ),
            const SizedBox(height: AppSizing.tsb), //#tsb
            Text(
              AppText.text5,
              style: TextStyle(
                color: AppColors.whiteWithOpacity60,
                fontWeight: FontWeight.normal,
                fontSize: AppSizing.textfont, //#textfont
              ),
            ),
            SizedBox(height: AppSizing.ftsb), //#ftsb
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 125,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppSizing.buttonradius,
                  ), //#buttonradius
                ),
                elevation: AppSizing.elevation, //elevation
              ),
              child: const Text(
                "Next",
                style: TextStyle(
                  fontSize: AppSizing.buttontextfont,
                  fontWeight: FontWeight.bold,
                ), //#buttontextfont
              ),
            ),
          ],
        ),
      ),
    );
  }
}
