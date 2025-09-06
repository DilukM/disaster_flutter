import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'auth/signin.dart';
import 'main_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes from Firebase
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        // Check if user is authenticated
        final user = snapshot.data;
        if (user != null) {
          // User is logged in, show main screen
          return const MainScreen();
        } else {
          // User is not logged in, show sign in screen
          return const SignInPage();
        }
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.authGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: AppTheme.logoContainerDecoration,
                child: ClipOval(
                  child: Image.asset(AppTheme.logoPath, fit: BoxFit.cover),
                ),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // Loading text
              const Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
