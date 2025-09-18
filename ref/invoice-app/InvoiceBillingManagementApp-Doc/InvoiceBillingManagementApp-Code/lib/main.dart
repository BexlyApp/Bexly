import 'package:flutter/material.dart';

import 'package:invoiceandbilling/views/splash/splashscreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Invoice Billing Management App',
      theme: ThemeData(scaffoldBackgroundColor: Colors.grey[50]),
      home: SplashScreen(),
    );
  }
}
