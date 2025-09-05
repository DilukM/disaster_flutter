import 'package:desaster/firebase_options.dart';
import 'package:desaster/screens/main_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:desaster/screens/auth/signin.dart';
import 'package:desaster/screens/auth/signup.dart';

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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.lightBlue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.lightBlue.shade50,
            foregroundColor: Colors.lightBlue.shade800,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.lightBlue.shade800,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            shadowColor: Colors.lightBlue.withOpacity(0.2),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue,
              foregroundColor: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.lightBlue,
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.lightBlue.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.lightBlue.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.lightBlue.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.lightBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            labelStyle: TextStyle(color: Colors.lightBlue.shade700),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          textTheme: TextTheme(
            headlineSmall: TextStyle(
              color: Colors.lightBlue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
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
