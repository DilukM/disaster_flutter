import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

/// Service class to handle all authentication operations
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // SharedPreferences keys for UI convenience only
  static const String _userEmailKey = 'user_email';

  /// Get current user
  static User? get currentUser => _auth.currentUser;

  /// Get auth state changes stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  static Future<AuthResult> signIn({
    required String email,
    required String password,
    bool rememberUser = true,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email.trim(), password: password);

      developer.log(
        'User signed in successfully: ${userCredential.user?.email}',
      );

      // Save user email for UI convenience (pre-filling email field)
      if (rememberUser) {
        await _saveUserEmail(email.trim());
      }

      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      developer.log(
        'Firebase Auth error during sign in: ${e.code} - ${e.message}',
      );

      String message = _getSignInErrorMessage(e.code);
      return AuthResult.failure(message);
    } catch (e) {
      developer.log('Unexpected error during sign in: $e');
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  /// Sign up with email and password
  static Future<AuthResult> signUp({
    required String email,
    required String password,
    bool rememberUser = true,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      developer.log(
        'User signed up successfully: ${userCredential.user?.email}',
      );

      // Save user email for UI convenience (pre-filling email field)
      if (rememberUser) {
        await _saveUserEmail(email.trim());
      }

      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      developer.log(
        'Firebase Auth error during sign up: ${e.code} - ${e.message}',
      );

      String message = _getSignUpErrorMessage(e.code);
      return AuthResult.failure(message);
    } catch (e) {
      developer.log('Unexpected error during sign up: $e');
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  /// Sign out current user
  static Future<AuthResult> signOut() async {
    try {
      await _auth.signOut();

      // Clear saved email from SharedPreferences
      await _clearUserEmail();

      developer.log('User signed out successfully');
      return AuthResult.success();
    } catch (e) {
      developer.log('Error during sign out: $e');
      return AuthResult.failure('Failed to sign out');
    }
  }

  /// Send password reset email
  static Future<AuthResult> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      developer.log('Password reset email sent to: $email');
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      developer.log(
        'Firebase Auth error during password reset: ${e.code} - ${e.message}',
      );

      String message = _getPasswordResetErrorMessage(e.code);
      return AuthResult.failure(message);
    } catch (e) {
      developer.log('Unexpected error during password reset: $e');
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  // Helper methods for email storage (UI convenience only)

  /// Save user email to SharedPreferences for UI convenience
  static Future<void> _saveUserEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userEmailKey, email);
      developer.log('User email saved for UI convenience');
    } catch (e) {
      developer.log('Error saving user email: $e');
    }
  }

  /// Clear user email from SharedPreferences
  static Future<void> _clearUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userEmailKey);
      developer.log('User email cleared from SharedPreferences');
    } catch (e) {
      developer.log('Error clearing user email: $e');
    }
  }

  /// Get saved user email for UI convenience
  static Future<String?> getSavedUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userEmailKey);
    } catch (e) {
      developer.log('Error getting saved user email: $e');
      return null;
    }
  }

  // Validation methods

  /// Check if email is valid
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Check if password is valid
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Check if passwords match
  static bool passwordsMatch(String password, String confirmPassword) {
    return password == confirmPassword;
  }

  // Error message helpers

  /// Get user-friendly error message for sign in errors
  static String _getSignInErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No user found with this email address';
      case 'wrong-password':
        return 'Invalid password';
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'An error occurred during sign in';
    }
  }

  /// Get user-friendly error message for sign up errors
  static String _getSignUpErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password';
      case 'email-already-in-use':
        return 'An account already exists with this email address';
      case 'invalid-email':
        return 'Invalid email address';
      case 'operation-not-allowed':
        return 'Email sign up is not enabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'An error occurred during sign up';
    }
  }

  /// Get user-friendly error message for password reset errors
  static String _getPasswordResetErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-not-found':
        return 'No user found with this email address';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'An error occurred while sending reset email';
    }
  }
}

/// Result class for authentication operations
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;

  const AuthResult._(this.isSuccess, this.errorMessage);

  /// Create a successful result
  factory AuthResult.success() => const AuthResult._(true, null);

  /// Create a failure result with error message
  factory AuthResult.failure(String message) => AuthResult._(false, message);

  /// Check if the operation failed
  bool get isFailure => !isSuccess;
}
