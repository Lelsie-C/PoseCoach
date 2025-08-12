import 'package:flutter/material.dart';
import 'package:sugmps/routes.dart';
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
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE77B22), Color.fromARGB(255, 20, 3, 119)],
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
                    () => Navigator.pushNamed(context, AppRoutes.usertype),
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
          ],
        ),
      ),
    );
  }
}
