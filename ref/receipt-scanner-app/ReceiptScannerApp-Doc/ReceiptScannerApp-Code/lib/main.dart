import 'package:receiptscanner/provider/provider.dart';
import 'package:receiptscanner/views/splashscreen/splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  // Initialize environment variables before running the app
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReceiptScanProvider())

      ],
      child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false,
        title: 'Receipt Scanner',
        theme: ThemeData(),
        home: SplashScreen()
    );
  }
}
