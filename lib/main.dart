import 'package:desaster/firebase_options.dart';
import 'package:desaster/main_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:desaster/Auth/signin.dart';
import 'package:desaster/Auth/signup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationConfigProvider(
      config: const ToastificationConfig(
        alignment: Alignment.topCenter,
        itemWidth: 440,
        animationDuration: Duration(milliseconds: 500),
      ),
      child: MaterialApp(
        title: '@Risk',
        theme: ThemeData(colorSchemeSeed: Colors.lightBlue),
        debugShowCheckedModeBanner: false,
        initialRoute: '/signin',
        routes: {
          '/signin': (context) => SignInPage(),
          '/signup': (context) => SignUpPage(),
          '/home': (context) => MainScreen(),
        },
      ),
    );
  }
}
