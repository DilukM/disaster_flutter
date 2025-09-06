import 'package:desaster/firebase_options.dart';
import 'package:desaster/screens/main_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:desaster/screens/auth/signin.dart';
import 'package:desaster/screens/auth/signup.dart';
import 'package:desaster/screens/auth_wrapper.dart';
import 'package:desaster/theme/app_theme.dart';

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
        title: AppTheme.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        routes: {
          '/signin': (context) => const SignInPage(),
          '/signup': (context) => const SignUpPage(),
          '/home': (context) => const MainScreen(),
        },
      ),
    );
  }
}
