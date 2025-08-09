import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'OSs/colors.dart';
import 'OSs/os1.dart';
import 'OSs/os2.dart';
import 'OSs/os3.dart';
import 'OSs/os4.dart';
import 'OSs/os5.dart';
import 'OSs/os6.dart';

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
    return MaterialApp(debugShowCheckedModeBanner: false, home: const OS6());
  }
}
