import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'detections/squatdetection.dart';
import 'detections/pushupdetection.dart';
import 'detections/notyetavailable.dart';
import 'utils/routes.dart';
import 'utils/styles.dart';
import 'OSs/os1.dart';
import 'OSs/os2.dart';
import 'OSs/os3.dart';
import 'OSs/os4.dart';
import 'OSs/os5.dart';
import 'OSs/os6.dart';
import 'OSs/os7.dart';
import 'OSs/os8.dart';
import 'package:sugmps/Authen/login.dart';
import 'package:sugmps/Authen/registration.dart';
import 'package:sugmps/Authen/prereg.dart';
import 'package:sugmps/MSs/navbar.dart';
import 'package:sugmps/MSs/activitypage.dart';
import 'utils/video_store.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load available cameras
  cameras = await availableCameras();

  // Load previously saved videos
  await loadVideosFromPrefs();

  // Check onboarding status
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

  // Set status bar color and icons
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: AppColors.background,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(MyApp(cameras: cameras, showOnboarding: isFirstTime));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  final bool showOnboarding;

  const MyApp({super.key, required this.cameras, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Dynamically set initial route
      initialRoute: showOnboarding ? AppRoutes.os1 : AppRoutes.homepage,
      onGenerateRoute: (settings) {
        WidgetBuilder builder;
        switch (settings.name) {
          case AppRoutes.os1:
            builder = (_) => const OS1();
            break;
          case AppRoutes.os2:
            builder = (_) => const OS2();
            break;
          case AppRoutes.os3:
            builder = (_) => const OS3();
            break;
          case AppRoutes.os4:
            builder = (_) => const OS4();
            break;
          case AppRoutes.os5:
            builder = (_) => const OS5();
            break;
          case AppRoutes.os6:
            builder = (_) => const OS6();
            break;
          case AppRoutes.os7:
            builder = (_) => const OS7();
            break;
          case AppRoutes.os8:
            builder = (_) => const OS8();
            break;
          case AppRoutes.prereg:
            builder = (_) => const Prereg();
            break;
          case AppRoutes.registration:
            builder = (_) => const Registration();
            break;
          case AppRoutes.login:
            builder = (_) => const Login();
            break;
          case AppRoutes.homepage:
            builder = (_) => const BottomNav();
            break;
          case AppRoutes.activity:
            builder = (_) => const Activitypage();
            break;
          case AppRoutes.pushupdetection:
            builder = (_) => const PushupDetectionScreen();
            break;
          case AppRoutes.squatdetection:
            builder = (_) => SquatDetectionPage();
            break;
          case AppRoutes.notyetavailable:
            builder = (_) => const NotYetAvailableScreen();
            break;
          default:
            throw Exception('Invalid route: ${settings.name}');
        }

        return PageRouteBuilder(
          pageBuilder: (context, __, ___) => builder(context),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
      },
    );
  }
}
