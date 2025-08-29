import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sugmps/Authen/login.dart';
import 'package:sugmps/Authen/registration.dart';
import 'package:sugmps/Authen/prereg.dart';
import 'package:sugmps/MSs/homepage.dart';
import 'package:sugmps/MSs/activitypage.dart';
import 'routes.dart';
import 'OSs/styles.dart';
import 'OSs/os1.dart';
import 'OSs/os2.dart';
import 'OSs/os3.dart';
import 'OSs/os4.dart';
import 'OSs/os5.dart';
import 'OSs/os6.dart';
import 'OSs/os7.dart';
import 'OSs/os8.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: AppColors.background,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.os1,
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
            builder = (_) => const Homepage();
            break;
          case AppRoutes.activity:
            builder = (_) => const Activitypage();
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
